# Timberborn.BlockObjectTools

## Overview
The `Timberborn.BlockObjectTools` module handles the user-facing tools for interacting with the block grid. It manages the logic for selecting and deleting buildings, rendering transparent blueprint previews before a building is placed, validating if a placement is legal, and categorizing all placeable objects into the correct tabs in the bottom toolbar.

For modders, this is a highly important module. It dictates how your custom building blueprints will behave when the player drags them across the map, how they group together in the UI, and how the game confirms that your building can legally be placed in a specific spot.

---

## Key Components

### 1. The Building Tool (`BlockObjectTool` & `PreviewPlacer`)
* **`BlockObjectTool`**: The actual tool that becomes active when a player clicks a building icon in the bottom bar. It asks the `AreaPicker` for coordinates and sends them to the `PreviewPlacer`. When the user clicks to build, it validates the placement and calls `IBlockObjectPlacer.Place()`.
* **`PreviewFactory`**: Takes a `PlaceableBlockObjectSpec` (the template), instantiates the Unity Prefab, renames it to contain "Preview", and calls `MarkAsPreviewAndInitialize()` on the `BlockObject`. This strips away physics and enables transparency.
* **`PreviewPlacer`**: Manages the grid logic. It uses the `BlockObjectValidationService` to check if a blueprint is colliding with other objects or floating illegally.
* **`PreviewShower`**: Handles the visual feedback. It tints the preview blue (`BuildablePreview`), red (`UnbuildablePreview`), or yellow (`WarningPreview`), and draws the area footprint on the ground.

### 2. Deletion (`EntityBlockObjectDeletionTool`)
* Inherits from `BlockObjectDeletionTool<EntityComponent>`.
* **Flow**: The player drags an area -> `PreviewCallback` draws the red deletion box -> `ActionCallback` collects all block objects and terrain blocks in the area -> A confirmation dialog is shown (unless skipped by holding a key) -> `DeleteBlockObjects()` is called, iterating through `EntityService.Delete()` and `TerrainDestroyer.DestroyTerrain()`.
* **Validation**: It specifically checks `IBlockObjectDeletionBlocker`. If an object is marked as undeletable (like the District Center in some contexts, or the very bottom block of a stack that has stuff built on it), it removes it from the deletion list.

### 3. Tool Grouping (`BlockObjectToolGroupSpecService`)
This service organizes the bottom toolbar. 
* It reads all `BlockObjectToolGroupSpec` definitions (which define the group ID, order, name, and icon).
* The `PlaceableBlockObjectSpecService` then categorizes all placeable buildings into these groups based on the `ToolGroupId` defined in their JSON template.

### 4. Terrain Cutouts (`PreviewTerrainCutout`)
If a building embeds itself into the terrain (like a water dump or a deep mine), it needs a "Cutout" so the terrain doesn't render through the building model.
* **`PreviewTerrainCutout`**: An auto-injected decorator that listens to the preview's movement. It queries the `ICutoutTilesProvider` to find which tiles need to be cut out, and dynamically pushes those to the `ITerrainService` as the player moves their mouse.

---

## How to Use This in a Mod

### Creating a New Tool Category (Bottom Bar Tab)
If you add several new buildings to the game, you can group them into your own custom tab on the bottom UI by defining a `BlockObjectToolGroupSpec` in a JSON file:

```json
[
  {
    "Id": "MyCustomModCategory",
    "Template": "BlockObjectToolGroup",
    "Components": {
      "BlockObjectToolGroupSpec": {
        "Id": "MyModTab",
        "Order": 90,
        "NameLocKey": "MyMod.ToolGroup.Name",
        "Icon": "MyMod/Sprites/MyTabIcon"
      }
    }
  }
]
```
Then, in your custom building's template, set the `ToolGroupId` to `"MyModTab"`. The `PlaceableBlockObjectSpecService` will automatically group your buildings under this new icon.

### Validating Custom Placement Logic
If your custom building requires specific conditions to be placed (e.g., it can *only* be placed adjacent to a river), you must create a class that implements `IPreviewValidator`. The `PreviewShower` automatically collects all `IPreviewValidator` components attached to the preview entity and calls `IsValid()` before allowing the player to place the block.

```csharp
using System.Collections.Generic;
using Timberborn.BlockObjectTools;
using Timberborn.BaseComponentSystem;

public class MustBeNearWaterValidator : BaseComponent, IPreviewValidator
{
    private MyCustomWaterChecker _waterChecker;

    public void Awake()
    {
        _waterChecker = GetComponent<MyCustomWaterChecker>();
    }

    // Return true if placement is legal. If false, output a warning string.
    public bool IsValid(out string warningMessage)
    {
        if (!_waterChecker.IsNearWater())
        {
            warningMessage = "Building must be placed near a river!";
            return false;
        }
        warningMessage = null;
        return true;
    }

    // Used if placing this block invalidates *another* block. Rarely needed.
    public IEnumerable<BaseComponent> InvalidatedObjects(out string warningMessage)
    {
        warningMessage = null;
        return System.Linq.Enumerable.Empty<BaseComponent>();
    }
}
```

---

## Modding Insights & Limitations

* **Default Placer**: The `BlockObjectPlacerService` uses `DefaultBlockObjectPlacer` for almost everything. This placer simply calls `BlockObjectFactory.CreateFinished(template, placement)`. If your mod requires a building to spawn in an "Unfinished" construction state immediately upon placement (bypassing the normal construction site phase), you would need to write a custom `IBlockObjectPlacer` and bind it.
* **Preview State Instantiation**: Because `PreviewFactory` uses `_templateInstantiator.Instantiate`, your custom component's `Awake()` method *will* be called when the transparent preview is generated. If your `Awake()` method executes heavy logic or tries to modify the game world, it will cause errors. You must wrap such logic in `if (!_blockObject.IsPreview)` checks, or move it to `InitializeEntity()`.
* **DevMode Limitation**: The `BlockObjectToolDescriber` automatically injects a red warning ("THIS IS A DEVMODETOOL") into the description of any tool marked as `DevModeTool = true` in its template, unless the player is currently in the Map Editor.
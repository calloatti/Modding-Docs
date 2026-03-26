# Timberborn.BlockObjectPickingSystem

## Overview
The `Timberborn.BlockObjectPickingSystem` module is responsible for translating the player's 2D mouse inputs into precise 3D grid interactions. It handles two major facets of gameplay: 
1. **Selection & Picking**: Raycasting into the world to figure out exactly which block of a multi-block building the player clicked on, and handling area-of-effect or stack-based selections (like highlighting a stack of platforms).
2. **Preview Placement**: Calculating exactly where a new building should "snap" to the grid when the player is trying to build it, taking terrain height, orientation, existing platforms, and underground mechanics into account.

For modders, this module provides the heavy-lifting math required if you are building custom cursor tools, custom deletion logic, or trying to programmatically place buildings in the world based on mouse position.

---

## Key Components

### 1. Raycasting (`BlockObjectRaycaster` & `BlockObjectHit`)
* **`BlockObjectRaycaster`**: Performs the physical Unity raycast against objects in the world. Crucially, if it hits a multi-block object (like a 3x2 Lodge), it calculates the exact `Block` (the 1x1x1 grid cell) that was intersected, adjusting for collider edges to prevent floating-point inaccuracies.
* **`BlockObjectHit`**: A struct returned by the raycaster containing the `BlockObject` hit, the specific `Block` hit, and the `HitProjectedOnGround` coordinate (snapped to the base Z-level of the object).

### 2. The Selection Engine (`BlockObjectPicker` & `StackedBlockObjectPicker`)
These classes are used when dragging selection boxes (e.g., the Demolish tool).
* **`BlockObjectPickerFilter`**: A highly configurable struct that filters which blocks are valid for selection. It can filter by a specific `referenceZ` level, check block occupations (Full, Bottom, Top), and take a custom `Func<BlockObject, bool>` predicate to filter by specific components.
* **`BlockObjectPickingMode`**: An enum defining the shape of the selection:
    * `InsideArea`: Standard 2D drag-box selection.
    * `UpwardStack`: Selects the clicked block and recursively finds everything built on top of it.
    * `DownwardStack`: Selects the clicked block and recursively finds everything beneath it (down to the foundation).
* **`StackedBlockObjectPicker`**: Handles the recursive logic for the Upward/Downward stack modes by navigating the `IBlockService`.

### 3. Build Tool Snapping (`BlockObjectPreviewPicker`)
This is the core logic used when you are holding a building blueprint and moving your mouse around the map.
* **`CenteredPreviewCoordinates()`**: Takes a `PlaceableBlockObjectSpec`, an `Orientation`, and a camera `Ray`. It traverses the ray across the grid (`GridTraversal`) and finds the first valid placement spot. It evaluates if the terrain is underground, if the building can be attached to a terrain cliff-side (`CanBeAttachedToTerrainSide`), and accounts for the building's `CustomPivotSpec` (so buildings don't always snap by their bottom-left corner).

---

## How to Use This in a Mod

### Creating a Custom Selection Tool
If you are creating a custom cursor tool (like a tool that specifically selects and deletes all "Power Shafts" in a dragged area), you would inject and use `BlockObjectPicker`.

```csharp
using System.Collections.Generic;
using Timberborn.BlockObjectPickingSystem;
using Timberborn.BlockSystem;
using Timberborn.Coordinates;

public class MyCustomPowerShaftSelector
{
    private readonly BlockObjectPicker _blockObjectPicker;

    public MyCustomPowerShaftSelector(BlockObjectPicker blockObjectPicker)
    {
        _blockObjectPicker = blockObjectPicker;
    }

    public IEnumerable<BlockObject> GetPowerShaftsInArea(SelectionStart start, Vector3Int endCoords)
    {
        // 1. Create a filter that only returns true if the object has your custom component
        BlockObjectPickerFilter filter = BlockObjectPickerFilter.Create(
            referenceZ: start.Coordinates.z, 
            selectionPredicate: blockObj => blockObj.HasComponent<MechanicalNode>()
        );

        // 2. Ask the picker to find all matching objects in the area
        return _blockObjectPicker.PickBlockObjects(
            selectionStart: start,
            endCoords: endCoords,
            pickingMode: BlockObjectPickingMode.InsideArea,
            blockObjectFilter: blockObj => blockObj.HasComponent<MechanicalNode>(),
            selectingArea: true
        );
    }
}
```

### Retrieving a Precise Click Location
If you just need to know exactly what block the player clicked on right now:

```csharp
using Timberborn.BlockObjectPickingSystem;
using Timberborn.InputSystem;
using UnityEngine;

public class MyRaycastTester
{
    private readonly BlockObjectRaycaster _raycaster;
    private readonly InputService _inputService;

    public void CheckClick()
    {
        Ray ray = _inputService.RaycastMouse();
        
        // Pass the generic type you are looking for (e.g., BlockObject)
        if (_raycaster.TryHitBlockObject<BlockObject>(ray, out BlockObjectHit hit))
        {
            Debug.Log($"Clicked on {hit.BlockObject.name} at exact grid cell {hit.HitBlock.Coordinates}");
        }
    }
}
```

---

## Modding Insights & Limitations

* **SelectableObject Dependency**: `BlockObjectRaycaster` fundamentally relies on `SelectableObjectRaycaster`. It will *only* successfully raycast against objects that possess a `SelectableObject` component. If you create a purely decorative `BlockObject` without a selectable component, the raycaster will pass right through it.
* **Z-Level Locking**: The vanilla area selection tools (like demolishing) intentionally restrict your selection to the Z-level where you initially clicked (using the `ReferenceTerrainLevel` in `SelectionStart`). This is why dragging a demolition box on the ground doesn't accidentally delete platforms floating 3 tiles above it. The `BlockObjectPickerFilter` is where this restriction is strictly enforced.
* **Underground Targeting**: `SelectionStart` specifically checks if the clicked block is marked as `Underground`. If it is, the picker automatically shifts the `ReferenceTerrainLevel` up by 1 and adjusts the vertical offset, ensuring that dragging your cursor from an underground explosive seamlessly connects with adjacent underground terrain blocks.
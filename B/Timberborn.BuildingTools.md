# Timberborn.BuildingTools

## Overview
The `Timberborn.BuildingTools` module acts as the integration layer between the game's generic placement tools (`Timberborn.BlockObjectTools`), the science/unlock system, and the specific data definitions of buildings (`Timberborn.Buildings.BuildingSpec`). It manages how building previews are placed (as finished or unfinished), how they are unlocked using Science Points, and how their costs are displayed in tooltips.

---

## Key Components

### 1. `BuildingPlacer`
This class implements `IBlockObjectPlacer` and is the primary engine for placing buildings on the map.
* **Placement Logic**: When `Place()` is called, it checks if the user is holding the `PlaceFinished` key (usually Shift or a developer hotkey) or if the `BuildingSpec.PlaceFinished` boolean is true. 
    * If true, it uses `_constructionFactory.CreateAsFinished()` (spawning the building instantly, bypassing builders).
    * If false, it uses `_constructionFactory.CreateAsUnfinished()`, which creates a construction site ghost.
* **Tooltip Decoration**: It implements `Describe()`, which constructs the tooltip seen when hovering over a building in the menu or while placing it. It injects:
    * The material cost section via `BuildingCostSectionProvider`.
    * Any custom UI sections provided by registered `ISectionProvider` instances.
    * An unlock section (if the building is locked) via `UnlockSectionController`.

### 2. `BuildingToolLocker`
This class implements `IToolLocker` to integrate buildings with the `ScienceService`.
* **Lock Checking**: `ShouldLock(ITool)` queries the `BuildingUnlockingService` to see if the building is unlocked for the current faction.
* **Unlocking Logic**: When `TryToUnlock()` is triggered (by clicking a locked building in the menu):
    * It checks for an `InstantUnlockKey` override.
    * If normal gameplay applies, it checks `_buildingUnlockingService.Unlockable(buildingSpec)` (which validates if the player has enough Science Points).
    * It uses the `DialogBoxShower` to prompt the player to confirm the expenditure of Science Points, or warns them if they have insufficient points.

### 3. `BuildingCostSectionProvider`
A UI helper that generates the "Materials needed" section of a building's tooltip.
* It reads the `ImmutableArray<GoodAmountSpec> BuildingCost` array defined in the `BuildingSpec`.
* It loads the `Game/ToolPanel/DescriptionPanelCostSection` visual element and populates it using the `GoodItemFactory` (which creates the icons and numbers for logs, planks, gears, etc.).

---

## How to Use This in a Mod

### Adding Custom UI Sections to Building Tooltips
If your mod introduces a complex building (like a power generator that consumes fuel) and you want to display that specific information directly in the build menu tooltip *before* the player places it, you can implement the `ISectionProvider` interface.

**1. Create the Provider:**
```csharp
using Timberborn.BlockSystem;
using Timberborn.BuildingTools;
using UnityEngine.UIElements;

public class GeneratorTooltipSection : ISectionProvider
{
    private readonly VisualElementLoader _loader;

    public GeneratorTooltipSection(VisualElementLoader loader)
    {
        _loader = loader;
    }

    public bool TryGetSection(Preview preview, out VisualElement section)
    {
        // 1. Check if the preview entity has your custom mod component
        MyGeneratorComponent generator = preview.GetComponent<MyGeneratorComponent>();
        if (generator == null)
        {
            section = null;
            return false;
        }

        // 2. Generate custom UI
        section = _loader.LoadVisualElement("MyMod/UI/GeneratorTooltipSection");
        section.Q<Label>("PowerOutput").text = generator.PowerOutput.ToString() + " HP";
        
        return true;
    }
}
```

**2. Bind it in your Configurator:**
```csharp
using Bindito.Core;
using Timberborn.BuildingTools;

[Context("Game")]
internal class MyModToolConfigurator : Configurator
{
    protected override void Configure()
    {
        // Use MultiBind to inject it into the BuildingPlacer's list of providers
        MultiBind<ISectionProvider>().To<GeneratorTooltipSection>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Strict Tool Validation**: The `BuildingToolLocker` includes a robust type-check `if (tool is BlockObjectTool blockObjectTool)` and then checks if the `Template` has a `BuildingSpec`. If you create a custom `ITool` that places objects but *doesn't* inherit from `BlockObjectTool`, the `BuildingToolLocker` will fail to recognize it and bypass the science unlock checks entirely.
* **Instant Placement Hotkey**: The `BuildingPlacer` hardcodes the string `"PlaceFinished"` as the hotkey to bypass the construction phase. This is a global input mapping that cannot be intercepted or changed by individual building specs.
* **Section Provider Execution Order**: The `BuildingPlacer` stores `ISectionProvider` instances in an `ImmutableArray`. Because they are added via `MultiBind` without order parameters, modders cannot guarantee the vertical visual order in which their custom tooltip sections will appear relative to other mods' tooltip sections.
# Timberborn.ConstructionMode

## Overview
The `Timberborn.ConstructionMode` module manages the visual state of the game when the player is actively building or inspecting unfinished structures. "Construction Mode" is a specific game state where all unfinished buildings instantly change their 3D models to display what they *will* look like once finished (albeit tinted in grayscale), and the water opacity is reduced to improve grid visibility.

---

## Key Components

### 1. `ConstructionModeService`
This singleton acts as the state manager for Construction Mode. It determines when the mode should be activated or deactivated by listening to a wide array of user interactions.

* **Triggers for Entering Construction Mode**:
    * **Opening a Build Menu**: If the player opens a `ToolGroup` (like the "Water" or "Wood" tabs at the bottom of the screen) that possesses a `ConstructionModeToolGroupSpec`, the mode activates.
    * **Equipping a Tool**: If a player selects a specific tool that implements the `IConstructionModeEnabler` interface, the mode activates.
    * **Selecting an Unfinished Building**: If the player simply clicks on a building that is currently under construction, the mode activates.
* **Triggers for Exiting Construction Mode**:
    * Closing the build menu, unequipping the tool, or deselecting the unfinished building. 
    * `CanExitConstructionMode()` acts as a guard clause: if the player clicks an unfinished building *while* the build menu is open, and then closes the build menu, the mode will *stay* active because the building is still selected.
* **Execution**: When entering or exiting, it iterates through all enabled `ConstructionModeModel` components and calls `EnterConstructionMode()` or `ExitConstructionMode()`. It also calls `_waterOpacityToggle.HideWater()` to make the water transparent, and posts a global `ConstructionModeChangedEvent`.

### 2. `ConstructionModeModel`
This component is attached to every `BuildingSpec` entity via the `ConstructionModeConfigurator`. It dictates how the individual building reacts to the global Construction Mode state.

* **Lifecycle**: It starts disabled. It implements `IUnfinishedStateListener`. When the building is placed down as a blueprint (`OnEnterUnfinishedState()`), the component enables itself and uses `MaterialColorer.EnableGrayscale` to permanently tint the building's *Finished* model gray.
* **Visual Swap**: 
    * When the `ConstructionModeService` calls `EnterConstructionMode()`, it tells the `BuildingModel` to `ShowFinishedModel()`. Because of the grayscale tint applied earlier, this creates the iconic "grayed out but fully built" look.
    * When `ExitConstructionMode()` is called, it reverts to `ShowUnfinishedModel()` (the scaffolding/dirt pile).
* **Completion**: When the building finishes construction, `OnExitUnfinishedState()` disables the grayscale tint and disables the `ConstructionModeModel` component entirely, meaning this building will no longer react to the global Construction Mode state.

---

## How to Use This in a Mod

### Forcing Construction Mode for a Custom Tool Group
If you add a new category to the bottom build menu (e.g., a "Vehicles" tab) and you want the water to turn clear and all scaffolding to reveal their finished models when the player clicks your tab, you simply need to add the `ConstructionModeToolGroupSpec` to your Tool Group's JSON file.

```json
{
  "ToolGroupSpec": {
    "Id": "MyCustomVehicleGroup",
    "Icon": "Vehicles/Icon",
    "Order": 15
  },
  "ConstructionModeToolGroupSpec": {}
}
```

### Forcing Construction Mode for a Specific Tool
If you have a custom tool (like an "Inspect Blueprint" tool) that doesn't live inside a standard Tool Group, you can force it to activate Construction Mode by implementing the `IConstructionModeEnabler` interface.

```csharp
using Timberborn.ToolSystem;
using Timberborn.ConstructionMode;

public class MyCustomInspectTool : Tool, IConstructionModeEnabler
{
    public override void Enter()
    {
        base.Enter();
        // The ConstructionModeService will automatically see that this tool
        // implements IConstructionModeEnabler and will activate Construction Mode.
    }
}
```

---

## Modding Insights & Limitations

* **Performance via Component Registry**: The `ConstructionModeService` uses `_entityComponentRegistry.GetEnabled<ConstructionModeModel>()` to find all buildings that need to change their visual state. Because `ConstructionModeModel` disables itself the moment a building is finished, this list *only* contains active construction sites. This is a massive performance optimization; activating construction mode in a 200-building city will only iterate over the 5 buildings currently under construction, rather than checking all 200.
* **Hardcoded Grayscale**: The `ConstructionModeModel` hardcodes the use of `_materialColorer.EnableGrayscale`. Modders cannot easily change the blueprint color (e.g., to a glowing blue hologram style) via JSON. Changing the construction mode aesthetic requires Harmony patching the `OnEnterUnfinishedState` method to apply a different material effect.
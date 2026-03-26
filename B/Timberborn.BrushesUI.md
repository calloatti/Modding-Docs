# Timberborn.BrushesUI

## Overview
The `Timberborn.BrushesUI` module provides the user interface layer for the game's area-of-effect brush tools, which are predominantly used in the Map Editor. It operates by injecting specific UI fragments into the tool panel whenever a player selects a tool that implements one of the standard brush interfaces (e.g., size, shape, direction, or height).

---

## Key Components

### 1. `IToolFragment` Panels
The module is divided into four distinct UI panels, all implementing the `IToolFragment` interface to integrate seamlessly into the `ToolPanelModule`. They use the `EventBus` to listen for `ToolEnteredEvent` and `ToolExitedEvent` to dynamically show or hide themselves.

* **`BrushSizePanel`**: Appears when the active tool implements `IBrushWithSize`. It binds UI buttons to the `IncreaseBrushSize` and `DecreaseBrushSize` inputs. It clamps the maximum size using the value defined in `BrushesSpec.MaxBrushSize`.
* **`BrushHeightPanel`**: Appears when the active tool implements `IBrushWithHeight`. It controls the vertical reach of a brush. It clamps the maximum height to `_mapSize.MaxMapEditorTerrainHeight` and the minimum height to the tool's defined `MinimumBrushHeight`.
* **`BrushShapePanel`**: Appears when the active tool implements `IBrushWithShape`. It provides UI toggles to switch between `BrushShape.Square` and `BrushShape.Round`. It also implements `IInputProcessor` to allow players to cycle shapes using a hotkey (`ToggleBrushShapeKey`).
* **`BrushDirectionPanel`**: Appears when the active tool implements `IBrushWithDirection`. It provides localized "Raise" and "Lower" toggles and listens for the `InverseBrushDirectionKey` (usually a modifier key like Shift) to temporarily invert the tool's action.

### 2. `BrushesUIConfigurator`
This configurator operates in both the `Game` and `MapEditor` contexts. 
* **Fragment Registration**: It utilizes a `ToolPanelModule.Builder` to register all four panels with specific visual ordering weights. 
* **Ordering**: The panels are ordered as Direction (60), Height (70), Size (80), and Shape (90) so they stack consistently in the tool menu.

---

## How to Use This in a Mod

### Leveraging Vanilla UI for Custom Tools
If you are developing a custom tool (for either the Map Editor or the base game) and want it to have adjustable size or shape, you do not need to write custom UI code. You simply implement the interfaces from `Timberborn.Brushes` on your tool class.

When your tool is selected, the `Timberborn.BrushesUI` module will detect those interfaces and automatically render the sliders and hotkey bindings on the screen.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Brushes;
using Timberborn.ToolSystem;

// By implementing IBrushWithSize, the BrushSizePanel will automatically appear!
public class CustomTerraformTool : BaseComponent, ITool, IBrushWithSize
{
    // The UI panel will read and write to this property
    public int BrushSize { get; set; } = 1;

    public void Enter()
    {
        // Tool activation logic
    }

    public void Exit()
    {
        // Tool deactivation logic
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Input Bindings**: The input keys for the UI panels are defined as `private static readonly string` fields, such as `"IncreaseBrushSize"`, `"ToggleBrushShape"`, and `"InverseBrushDirection"`. Modders cannot easily remap these defaults without bypassing the vanilla panels and writing custom `IToolFragment` implementations.
* **Global Maximum Size**: The maximum allowed brush size is not dictated by individual tools, but globally by the `BrushesSpec` loaded via the `ISpecService`. If a modder creates a tool that needs to affect the entire map simultaneously, they must either override the global `BrushesSpec.MaxBrushSize` JSON file or bypass the `BrushSizePanel` entirely.
* **Context Scope**: Although brush tools are primarily a Map Editor feature, the `BrushesUIConfigurator` binds these panels in *both* `[Context("Game")]` and `[Context("MapEditor")]`. This means modders are fully supported in creating adjustable-brush tools for standard survival gameplay (e.g., a dynamic-radius tree planting tool) without needing to rewrite the UI logic.
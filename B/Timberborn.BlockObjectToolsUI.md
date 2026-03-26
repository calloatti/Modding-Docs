# Timberborn.BlockObjectToolsUI

## Overview
The `Timberborn.BlockObjectToolsUI` module serves as the presentation layer for block object placement tools. It manages the visual UI elements that players interact with during construction, such as the placement manipulation panel (rotate/flip controls), warning text panels for invalid placements, and the generation of tool buttons in the bottom bar.

---

## Key Components

### 1. `BlockObjectPlacementPanel`
This class implements `IToolFragment` to provide the UI panel that appears when a player selects a building to place.
* **Controls**: It binds physical UI buttons to the `RotateClockwise`, `RotateCounterclockwise`, and `Flip` actions of the `PreviewPlacement` service.
* **Event Listening**: It registers with the `EventBus` to listen for `ToolEnteredEvent` and `ToolExitedEvent`. When a `BlockObjectTool` is entered, the panel becomes visible; when exited, it hides.
* **Dynamic Flipping**: It checks if the active tool's `BlockObjectSpec` is `Flippable`. If not, it disables flipping in the `PreviewPlacement` and hides the flip button.

### 2. `BlockObjectToolWarningPanel`
A UI fragment that displays contextual warning messages during placement (e.g., "Too far from district center").
* **Update Loop**: It implements `IUpdatableSingleton` to run an `UpdateSingleton()` method every frame.
* **Logic**: It checks if the `_toolService.ActiveTool` is a `BlockObjectTool`. If the tool has a populated `WarningText` string, the panel displays it; otherwise, the panel hides itself.

### 3. Tool Button Factories
* **`BlockObjectToolButtonFactory`**: Creates individual tool buttons for the bottom bar. It reads the `ToolShape` from the `PlaceableBlockObjectSpec` to generate either a `Square` or `Hex` shaped button.
* **`BlockObjectToolGroupButtonFactory`**: Creates grouped tool buttons (dropdowns) for the bottom bar, iterating through available `PlaceableBlockObjectSpec` items and only adding them if `UsableWithCurrentFeatureToggles` is true.

---

## How to Use This in a Mod

While you typically define new tools and groups using JSON data rather than writing C#, understanding this module is helpful if you want to create custom UI panels that appear during construction.

### Injecting Custom Tool Panels
If you create a custom modded tool and need a specific UI panel to appear alongside it, you can create a class implementing `IToolFragment` (similar to `BlockObjectPlacementPanel`). 

You then bind it to the game's UI by adding it to the `ToolPanelModule` in your configurator:

```csharp
using Bindito.Core;
using Timberborn.ToolPanelSystem;

[Context("Game")]
internal class MyCustomToolsUIConfigurator : Configurator
{
    private class ToolPanelModuleProvider : IProvider<ToolPanelModule>
    {
        private readonly MyCustomToolPanel _myCustomPanel;

        public ToolPanelModuleProvider(MyCustomToolPanel myCustomPanel)
        {
            _myCustomPanel = myCustomPanel;
        }

        public ToolPanelModule Get()
        {
            ToolPanelModule.Builder builder = new ToolPanelModule.Builder();
            // Add your custom fragment with an ordering weight
            builder.AddFragment(_myCustomPanel, 30); 
            return builder.Build();
        }
    }

    protected override void Configure()
    {
        Bind<MyCustomToolPanel>().AsSingleton();
        MultiBind<ToolPanelModule>().ToProvider<ToolPanelModuleProvider>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Input Keys**: The input keys `"RotateClockwise"`, `"RotateCounterclockwise"`, and `"Flip"` are hardcoded as `private static readonly string` fields in `BlockObjectPlacementPanel`. Custom tools trying to hook into these specific UI buttons must match these exact binding keys.
* **Performance Consideration**: Because `BlockObjectToolWarningPanel` evaluates `warningText` on every single frame via `UpdateSingleton()`, any custom logic you write that feeds text into a tool's warning state must be highly optimized to avoid dropping frame rates during building placement.
* **UI Toolkit Dependencies**: The panels rely on specific hardcoded UI Toolkit paths (e.g., `"Common/ToolPanel/BlockObjectPlacementPanel"`) loaded via `VisualElementLoader`. Modders cannot easily edit the visual layout of these specific vanilla panels without overriding the game's core UXML assets.
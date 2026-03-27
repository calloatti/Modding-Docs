# Timberborn.DebuggingUI

## Overview
The `Timberborn.DebuggingUI` module provides the visual interface for the diagnostic tools managed by `Timberborn.Debugging`. It includes a searchable menu of developer methods (`DevPanel`), a repositionable overlay for system-wide technical readouts (`DebuggingPanel`), and a deep-inspection tool for viewing and browsing the live properties of any game object or singleton in real-time (`ObjectDebuggingPanel`).

---

## Key Components

### 1. Developer Method Menu (`DevPanel`)
This is the primary interface for executing modded and built-in developer commands.
* **Method Gathering**: It aggregates all `DevMethod` instances registered via `IDevModule` across the entire application.
* **Search and Filter**: It includes a `TextField` filter that dynamically hides buttons based on the text entered by the player.
* **Favourites System**: Players can "star" specific methods to move them to a dedicated "Favourites" section at the top of the panel. This list is persisted across game sessions using `PlayerPrefs`.
* **Keybindings**: If a `DevMethod` has an associated `KeyBindingId`, the panel automatically appends the current hotkey string (e.g., `[Ctrl+Shift+L]`) to the button label via the `InputBindingDescriber`.

### 2. System Status Overlay (`DebuggingPanel`)
A persistent window used to display text readouts from various systems (e.g., cursor coordinates, performance metrics).
* **Repositioning**: It utilizes `DebugPanelMover` to allow players to drag the window anywhere on the screen. Position and visibility states are saved in the game settings.
* **Modular Items**: Other modules can register their own readout logic by implementing `IDebuggingPanel` and calling `AddDebuggingPanel()`. Each registered panel can be individually expanded or collapsed.

### 3. Live Object Inspector (`ObjectDebuggingPanel`)
This is a powerful reflection-based browsing tool for inspecting the internal state of the game.
* **Contextual Selection**: The `ObjectSelector` dynamically populates a list of components based on the player's current selection in the game world. If nothing is selected, it displays all registered `Singletons`.
* **Reflection Engine (`ObjectViewer`)**: It uses C# reflection (`System.Reflection`) to iterate through the fields of a selected object.
* **Node Architecture**:
    * **Primitive Nodes**: Display simple values (strings, ints, bools) in a non-editable text field.
    * **Foldable Nodes**: Allow clicking to expand nested objects or base classes.
    * **Enumerable Nodes**: Specifically handle lists and arrays, displaying each element with its index (e.g., `[0]`, `[1]`).

---

## How to Use This in a Mod

### Adding a System Readout to the Debug Panel
If you have a modded system and want its current status to be visible in the Debug Mode overlay, implement `IDebuggingPanel`.

```csharp
using Timberborn.DebuggingUI;

public class MyModMonitor : IDebuggingPanel {
    private readonly DebuggingPanel _debugPanel;
    
    public MyModMonitor(DebuggingPanel debugPanel) {
        _debugPanel = debugPanel;
    }

    public void Load() {
        // Register your readout with a title
        _debugPanel.AddDebuggingPanel(this, "My Mod Status");
    }

    public string GetText() {
        // This text is updated every frame while the panel is visible
        return $"Active Entities: {myModInternalList.Count}\nProcessing: {isModActive}";
    }
}
```

---

## Modding Insights & Limitations

* **Reflection Performance**: The `ObjectViewer` is designed for debugging and should not be used in performance-critical code. Expanding a large list (like the global Beaver population) in the inspector may cause a momentary framerate hitch as it generates dozens of visual nodes.
* **Field Access**: The `ObjectViewerObjectNode` retrieves both `Public` and `NonPublic` fields, meaning it can see `private` and `protected` variables that are normally hidden. It excludes `Delegate` fields to avoid UI clutter.
* **Panel Resetting**: If a modder or player moves a debug panel off-screen and can no longer find it, a "Reset debugging panels position" method is provided in the Dev Menu via `DebuggingPanelResetter`.
* **Search Limitations**: The `ObjectSelector` search field only filters by the **Type Name** (e.g., `Lumberjack`, `Inventory`), not by the content within those objects.

---


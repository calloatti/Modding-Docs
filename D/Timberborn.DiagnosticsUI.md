# Timberborn.DiagnosticsUI

## Overview
The `Timberborn.DiagnosticsUI` module provides the visual interface and developer tools for the monitoring systems established in `Timberborn.Diagnostics`. It manages the display of real-time performance metrics (FPS), adds detailed mesh information to the debug panels, and provides developer commands for low-level system operations like Garbage Collection and scene loading.

---

## Key Components

### 1. Performance Overlay (`FramesPerSecondPanel`)
This component renders the frame rate data gathered by the `FramesPerSecondCounter`.
* **Placement**: It adds a persistent label to the **bottom-right** of the screen via the `UILayout` system.
* **Visibility**: The panel is visible if either "Dev Mode" is enabled or the player has toggled "Show FPS" in the game settings.
* **Data Display**: It displays two values: the **Average FPS** and the **Minimum FPS** (e.g., `FPS: 60 / 45`), updating only when the rounded integer values change to minimize UI redraws.

### 2. Mesh Metric Readout (`MeshMetricsDebuggingPanel`)
This panel integrates with the `DebuggingPanel` system to show technical data about selected 3D objects.
* **Real-time Stats**: When a player selects an object in the world, this panel displays the raw vertex count, triangle count, triangles-per-tile density, and the number of submeshes.
* **Context**: If no object is selected, it simply displays "Nothing selected". 
### 3. Garbage Collection Tools (`GCToggler` & `GCTrigger`)
These are developer modules (`IDevModule`) that allow for manual control over Unity's memory management.
* **`GCTrigger`**: Adds a "Trigger GC" button to the Dev Menu which immediately calls `GC.Collect()` to force memory cleanup.
* **`GCToggler`**: Adds a "Toggle GC" button. It can enable or disable Unity's automatic Garbage Collector entirely (though it is prevented from doing so while running in the Unity Editor to avoid instability).

### 4. `EmptySceneLoader`
A diagnostic tool used to test loading performance or clear the game state.
* It provides a "Load empty scene" command in the Dev Menu.
* This command is restricted to **Development Versions** of the game only and triggers an instant load of scene index 5.

---

## How to Use This in a Mod

### Accessing Diagnostics from the UI
Modders can use the `DebuggingPanel` to add their own custom readouts, similar to how `MeshMetricsDebuggingPanel` functions.

```csharp
using Timberborn.DebuggingUI;

public class MyModMetrics : ILoadableSingleton, IDebuggingPanel {
    private readonly DebuggingPanel _debugPanel;

    public MyModMetrics(DebuggingPanel debugPanel) {
        _debugPanel = debugPanel;
    }

    public void Load() {
        // Registers your mod in the "Debug Mode" window
        _debugPanel.AddDebuggingPanel(this, "My Mod Performance");
    }

    public string GetText() {
        return $"Active Objects: {someCounter}\nStatus: Nominal";
    }
}
```

---

## Modding Insights & Limitations

* **FPS Smoothing**: The FPS panel relies on the `FramesPerSecondCounter`'s 3-second sampling period. Instantaneous frame spikes may be masked by the average, making the "Minimum FPS" value more useful for identifying stuttering.
* **UI Layout Layering**: The FPS panel uses a priority/index of `2` when adding to the `BottomRight` layout. Other modders adding elements to the same corner should use different indices to avoid overlapping.
* **GC Toggling Risks**: Disabling the Garbage Collector via `GCToggler` can lead to rapid memory exhaustion and game crashes if not handled carefully. This tool is intended strictly for profiling memory-sensitive code segments.

---

## Related dlls
* **Timberborn.Diagnostics**: The underlying logic provider for FPS and mesh data.
* **Timberborn.Debugging**: Provides the `IDevModule` interface and dev mode state management.
* **Timberborn.DebuggingUI**: Provides the `DebuggingPanel` framework for modular readouts.
* **Timberborn.CoreUI**: Supplies the `VisualElementLoader` and layout services.

Would you like to examine the **Timberborn.SceneLoading** module next to see how the `EmptySceneLoader` handles scene transitions? Conclude your response with a single next step.
# Timberborn.BenchmarkingUI

## Overview
The `Timberborn.BenchmarkingUI` module is a tiny presentation layer that connects the low-level diagnostic data collected by the `Timberborn.Benchmarking` module (specifically the `FrameTimingSampler`) and displays it in real-time on the developer-facing Debugging Panel (accessible in-game via Dev Mode).

For modders, this module provides a lightweight, real-time method to monitor the CPU and GPU load of the game without having to run a full, automated, command-line benchmark.

---

## Key Components

### 1. `BenchmarkDebuggingPanel`
This singleton implements the `IDebuggingPanel` interface, injecting a new "Performance" section into the game's developer debug menu.
* **Sampling**: Every frame, the game queries `GetText()`. Inside this method, the panel calls `_frameSampler.UpdateSamples()` and adds the current frame's timing data to internal lists.
* **Averaging**: To keep the UI readable and prevent the text from flickering unreadably fast, it aggregates data over a specified `UpdateInterval` (0.5 seconds).
* **Output**: Once the interval is reached, it calculates the average for the collected lists, clears them, and formats the output using a `StringBuilder`. It displays the time (in milliseconds) spent by the CPU Main thread, CPU Render thread, CPU Wait (idle time waiting for the GPU), Total CPU time, and GPU time.

### 2. `BenchmarkingUIConfigurator`
A simple `Configurator` that runs in the `"Game"` context, binding the `BenchmarkDebuggingPanel` as a singleton. Note that it relies on `DebuggingPanel.AddDebuggingPanel(this, "Performance")` during `Load()` to register itself, rather than using Bindito `MultiBind` syntax.

---

## How to Use This in a Modding Workflow

To use this feature while developing your mod:
1. Ensure Developer Mode is active (typically by pressing `Alt + Shift + Z` in-game, or editing your configuration files).
2. Open the Debugging Panel.
3. Look for the "Performance" section.

If you are developing a highly complex mod—such as one that executes heavy pathfinding calculations on the main thread, or introduces a custom shader that puts a heavy load on the GPU—you can watch these numbers. If the `CPU (Main)` or `GPU` numbers consistently spike over ~16.6ms when your mod's features are active, it indicates your mod is causing the framerate to dip below 60 FPS and needs optimization.

---

## Modding Insights & Limitations

* **Frame Timing Feature Requirement**: Just like the underlying `Timberborn.Benchmarking` module, the `FrameTimingSampler` used here relies on the Unity project setting `FrameTimingManager.IsFeatureEnabled()`. If the game developers disable this in a retail build, the "Performance" debug panel will simply report `0.0ms` across all categories, making it useless for live mod debugging in that specific version of the game.
* **No Historical Graphing**: The panel only provides a rolling average of the last 0.5 seconds. It does not provide historical graphs or record the data to a file. For long-term trend analysis, the command-line arguments (handled by `Timberborn.Benchmarking`) must be used instead.
# Timberborn.Benchmarking (Corrected)

## Overview
The `Timberborn.Benchmarking` module is an internal, developer-focused utility used to test the game's performance and save times under controlled conditions. It provides command-line hooks to launch the game into an automated testing sequence, collects deep metrics (CPU, GPU, frametimes), and exports structured logs and CSV files.

While modders generally do not need to interact with this module directly for gameplay features, it is a highly valuable tool for testing the performance impact of large mods. You can use its command-line arguments to automatically run a test, lock the game speed, and generate a report on how your mod affected the framerate and tick length.

---

## Key Components

### 1. `Benchmarker` (The Performance Tester)
This is the core singleton that manages a standard performance benchmark.
* **Phases**: A benchmark consists of a "Warm Up" phase (to let the game stabilize after loading) followed by a "Sampling" phase (where data is actually recorded).
* **Control**: When active, it suspends autosaving (`_autosaver.Suspend()`) and edge-panning (`_edgePanningCameraTargetPicker.Suspend()`), locks the game speed to the requested multiplier, and resets internal metrics (`_metricsService.ResetMetrics()`).
* **Conclusion**: Once the sampling phase ends, it forces the game to quit (`GameQuitter.Quit()`) via the `BenchmarkLogger`.

### 2. `SavingBenchmarker` (The Save Tester)
A separate pipeline designed exclusively to test how fast the game can serialize the world state to memory.
* **Logic**: Like the main benchmarker, it has a warm-up phase. Once finished, it triggers the `GameSaver.BenchmarkSavingToMemory` method multiple times in a row.
* **Output**: It outputs the results directly to the Unity console (`Debug.Log`), detailing the average, median, min, max, and 90th percentile save times.

### 3. Data Collection (`PerformanceSampler` & `FrameTimingSampler`)
* **`PerformanceSampler`**: Runs during `LateUpdate` to record a `PerformanceSample` for every frame during the sampling period. It records real-world time, delta time, and the length of the simulation tick (`_ticker.LengthOfLastTickInSeconds`).
* **`FrameTimingSampler`**: Wraps Unity's native `FrameTimingManager`. If enabled, it provides deep diagnostics, extracting exactly how many milliseconds the CPU Main Thread, CPU Render Thread, and GPU spent processing the frame.

### 4. Logging (`BenchmarkLogger` & `BenchmarkReportCreator`)
When a benchmark finishes, the data is collated and exported.
* **`BenchmarkReportCreator`**: Gathers all contextual data about the run. This includes Unity version, system hardware specs, active feature toggles, resolution, and current entity counts (characters, buildings, construction sites).
* **`BenchmarkLogger`**: Takes the report and writes it to disk. 
    * It outputs a human-readable `.log` file.
    * It outputs a detailed `.csv` file containing every frame sample.
    * It copies the actual save file used (`.json`) next to the log.
    * It appends the summary to a master `benchmarks.csv` archive.
    * The output directory is typically `UserDataFolder/Benchmarks/Standalone/` (or `Editor/` if running in the Unity Editor).

### 5. `BenchmarkStarter` (Command Line Integration)
This singleton runs during the `Game` context load and uses the `Timberborn.CommandLine.ICommandLineArguments` service to check if the game was launched specifically to run a benchmark.
* **Arguments (Parsed with a single `-` prefix):**
    * `-benchmarkLength [int]`: The duration of the sampling phase in seconds.
    * `-benchmarkSpeed [int]`: The game speed multiplier (e.g., 3 for fast forward).
    * `-benchmarkWarmUpLength [int]`: The duration to wait before sampling begins.
    * `-benchmarkSaveCount [int]`: If present, runs the `SavingBenchmarker` instead of the standard performance benchmark, saving the game to memory the specified number of times.

---

## How to Use This in a Modding Workflow

To measure the impact of your mod, you can launch the Timberborn executable with the specific benchmarking arguments. Note that because `BenchmarkLogger` requires `GameLoader.LoadedSave`, these arguments are designed to be evaluated once a settlement actually loads.

```bash
# Example: Warm up for 10s, sample for 60s at 3x speed
Timberborn.exe -benchmarkLength 60 -benchmarkSpeed 3 -benchmarkWarmUpLength 10

# Example: Test how fast your mod's data serializes by saving to memory 5 times
Timberborn.exe -benchmarkSaveCount 5 -benchmarkWarmUpLength 10
```
After the game automatically quits, navigate to your Timberborn Documents folder (e.g., `Documents\Timberborn\Benchmarks\Standalone`) to analyze the CSV output.

---

## Modding Insights & Limitations

* **Command Line Parsing (`Timberborn.CommandLine`)**: The command line parser checks for arguments prefixed strictly with a single hyphen (`"-" + key`). 
* **Save Loading Dependency**: While the `BenchmarkStarter` initiates the benchmarking process, the `BenchmarkLogger` explicitly assumes a save file is loaded (`_gameLoader.LoadedSave`). The mechanism for automatically loading a specific save from the command line is handled outside of these modules.
* **No UI Interactions**: The benchmarking system assumes a completely hands-off test. It deliberately suspends edge-panning and autosaves to ensure clean data.
* **Frame Timing Availability**: The `FrameTimingSampler` relies on `FrameTimingManager.IsFeatureEnabled()`. In standard release builds, detailed CPU/GPU thread timings might be disabled by the developers to save overhead, meaning the detailed CPU/GPU CSV columns will be empty.
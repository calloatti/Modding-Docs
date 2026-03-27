# Timberborn.Diagnostics

## Overview
The `Timberborn.Diagnostics` module provides tools for monitoring game performance and analyzing 3D asset complexity. It is primarily designed for developers and modders to measure frame rates and audit mesh metrics (vertices, triangles, and submeshes) to ensure optimal game performance.

---

## Key Components

### 1. Performance Monitoring (`FramesPerSecondCounter`)
This singleton tracks the game's rendering performance over a rolling window.
* **Sampling**: It records the `unscaledDeltaTime` for each frame and stores samples for a period of 3 seconds.
* **Metrics**: It calculates both the **Average FPS** and the **Minimum FPS** (1% lows) during the sampling period.
* **Time Independence**: By using `Time.unscaledTime`, it ensures that FPS readings remain accurate even if the player pauses the game or changes the simulation speed.

### 2. Mesh Complexity Analysis (`MeshMetricsRetriever`)
This utility class recursively inspects GameObjects to calculate their geometric weight.
* **Data Points**: It counts total vertices, triangles, and submeshes.
* **Density Calculation**: For `BlockObject` entities (buildings), it calculates "Triangles Per Tile" by dividing the total triangles by the number of unique XY grid coordinates the building occupies.
* **Filtering**: It intelligently ignores visual helpers like "Markers", "StatusIcons", and "#Unfinished" models to provide an accurate count of the final rendered asset.

### 3. Debug Integration
* **`SelectedMeshMetrics`**: When "Debug Mode" is enabled, this singleton listens for selection events. Whenever a player clicks an object in the world, it automatically retrieves and stores the mesh metrics for that specific object.
* **`MeshMetricsDumper`**: A developer module (`IDevModule`) that adds a "Dump mesh metrics" button to the dev menu.     * It iterates through the `IPrefabOptimizationChain` to find all cached prefabs.
    * It exports a CSV file to the `UserData/MeshMetrics` folder, sorted by triangle count (highest complexity first).

---

## Data Structures

### `MeshMetrics`
A read-only data container for asset statistics:
* **`NumberOfVertices`**: Total vertex count.
* **`NumberOfTriangles`**: Total polygon count.
* **`NumberOfTrianglesPerTile`**: Geometric density relative to map footprint.
* **`NumberOfSubmeshes`**: Count of draw calls required for different materials.

---

## How to Use This in a Mod

### Auditing Custom Assets
If you are a 3D artist making new buildings, you can use the built-in dumper to see how your models compare to vanilla assets.
1. Enable **Dev Mode**.
2. Open the **Dev Menu**.
3. Click **"Dump mesh metrics"**.
4. Locate the generated CSV in your Timberborn user folder to check your "Triangles Per Tile" density.

---

## Modding Insights & Limitations

* **Recursive Inspection**: The `MeshMetricsRetriever` uses a deep recursive search (`VisitChildren`). While thorough, modders should avoid calling this every frame on extremely complex hierarchies to prevent performance spikes.
* **Active-Only Check**: The retriever only counts meshes on GameObjects that are currently `activeSelf`. If your building has hidden variant meshes, they will not be included in the total unless they are active.
* **Renderer Requirement**: Only meshes attached to a `MeshFilter` or `SkinnedMeshRenderer` with an **enabled** `Renderer` component are counted.

---

## Related dlls
* **Timberborn.BlockSystem**: Used to determine the tile footprint for density calculations.
* **Timberborn.PrefabOptimization**: Provides the collection of optimized prefabs for the metric dumper.
* **Timberborn.FileSystem**: Handles the creation and writing of CSV report files.
* **Timberborn.SelectionSystem**: Supplies events when the player selects an object to audit.

Would you like to examine the **Timberborn.SelectionSystem** next to see how the game handles object picking and events?
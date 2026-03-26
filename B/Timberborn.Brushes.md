# Timberborn.Brushes

## Overview
The `Timberborn.Brushes` module provides the foundational logic for area-of-effect tools, primarily used in the Map Editor for terrain manipulation, water placement, and resource painting. It defines how the game calculates the affected tiles based on a brush's shape, size, and random distribution probabilities.

---

## Key Components

### 1. `BrushShapeIterator`
This service is responsible for determining exactly which grid coordinates fall within a brush's area of effect.
* **Input**: It takes a center `Vector3Int` coordinate, a `size` integer (representing the radius), and a `BrushShape` enum (`Square` or `Round`).
* **Execution**: 
    * For `BrushShape.Square`: It generates a perfect square bounding box from `center.x - (size - 1)` to `center.x + (size - 1)`.
    * For `BrushShape.Round`: It generates the same bounding box but filters the results, only yielding coordinates where the Euclidean `Vector3.Distance(coords, center) + 0.7f` is less than or equal to the `size`.
* **Safety Check**: Both iterations explicitly check `_terrainService.Contains(coords)` before yielding, ensuring the brush never attempts to paint outside the playable map boundaries.

### 2. `BrushProbabilityMap`
A performance-optimized tool used for painting scattered elements (like pine trees or blueberry bushes) with a specific density.
* **Initialization**: During `Load()`, it generates a 2D float array (`_probabilities`) matching the entire `_mapSize.TerrainSize`. It populates every single coordinate with a pre-calculated random float between `0f` and `1f` using `_randomNumberGenerator.Range`.
* **Usage**: When a brush is dragged across the map, it calls `TestProbabilityAtCoordinates(coords, density)`. Because the random values are pre-calculated and static, dragging a 50% density brush back and forth over the same area will always yield the exact same pattern of placed objects, creating a consistent and predictable painting experience for the user.

### 3. Brush Interfaces
The module provides a suite of standard interfaces that specific tool implementations (like a Terrain Raising tool) can implement to standardized their configuration.
* **`IBrushWithSize`**: Implements `int BrushSize { get; set; }`.
* **`IBrushWithHeight`**: Implements `int BrushHeight { get; set; }` and a `MinimumBrushHeight`.
* **`IBrushWithShape`**: Implements `BrushShape BrushShape { get; set; }`.
* **`IBrushWithDirection`**: Handles binary tool states (e.g., raising vs. lowering terrain) via `Increase`, `Inverse`, and `IsIncreasing`.

---

## How to Use This in a Mod

### Creating a Custom Area-of-Effect Tool
If you are building a custom tool for the Map Editor (or even the main game, like a "mass demolish" tool), you can utilize the `BrushShapeIterator` to easily find all affected tiles without writing complex geometric math.

```csharp
using System.Collections.Generic;
using Timberborn.BaseComponentSystem;
using Timberborn.Brushes;
using Timberborn.Coordinates;
using UnityEngine;

public class MyCustomBombTool : BaseComponent, IBrushWithSize, IBrushWithShape
{
    private BrushShapeIterator _shapeIterator;
    
    // Implement the interfaces so UI tools can hook into them
    public int BrushSize { get; set; } = 3;
    public BrushShape BrushShape { get; set; } = BrushShape.Round;

    [Inject]
    public void InjectDependencies(BrushShapeIterator shapeIterator)
    {
        _shapeIterator = shapeIterator;
    }

    public void Detonate(Vector3Int targetCenter)
    {
        // Automatically gets a list of valid coordinates based on the current size and shape
        IEnumerable<Vector3Int> affectedTiles = _shapeIterator.IterateShape(targetCenter, BrushSize, BrushShape);

        foreach (Vector3Int tile in affectedTiles)
        {
            // ... destroy things on this tile ...
        }
    }
}
```

---

## Modding Insights & Limitations

* **Memory Overhead of Probability Map**: The `BrushProbabilityMap` allocates a `float[,] _probabilities` array for the *entire* map size (`_size.x * _size.y`) during load. For maximum-sized maps, this is a noticeable chunk of memory. Modders should leverage this existing singleton via injection rather than trying to build their own probability matrices.
* **Flat Z-Axis Assumption**: The `BrushShapeIterator` assigns the Z-coordinate (vertical height) of the `center` argument to *all* yielded coordinates (`Vector3Int coords = new Vector3Int(0, 0, center.z)`). This means brushes are inherently flat, 2D planes hovering at a specific Z-level. Modders cannot use this iterator out-of-the-box to create a true 3D spherical volume selection.
* **Rounding Bias**: The `IterateRound` method uses a specific fudge factor of `+ 0.7f` when evaluating distance (`Vector3.Distance(coords, center) + 0.7f <= (float)size`). This creates a slightly "fat" circle to ensure the grid-based selection feels subjectively round to the human eye, rather than strictly adhering to true Euclidean boundaries.
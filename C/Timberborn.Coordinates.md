# Timberborn.Coordinates

## Overview
The `Timberborn.Coordinates` module is the spatial and mathematical heart of the game. It is responsible for translating continuous 3D space (Unity's world coordinates) into Timberborn's discrete, voxel-based grid system. It provides the essential data structures for managing rotation (`Orientation`), mirroring (`FlipMode`), adjacent tile calculations (`Deltas`), and building location tracking (`Placement`).

---

## Key Components

### 1. The Grid vs. World Axis Swap (`CoordinateSystem`)
Timberborn uses a different coordinate axis mapping than standard Unity, which is critical to understand.
* **Standard Unity**: (X = Left/Right, Y = Up/Down, Z = Forward/Back).
* **Timberborn Grid**: (X = Width, Y = Depth, Z = Height/Elevation).
* **`CoordinateSystem`**: This static utility safely converts between the two formats. When translating `WorldToGrid()`, it maps Unity's `position.x` to X, `position.z` to Y, and `position.y` to Z. It also provides `GridToWorldCentered()`, which adds `0.5f` to the X and Z world coordinates to perfectly center an object in the middle of a grid tile.

### 2. Building Placement Data (`Placement`, `Orientation`, `FlipMode`)
Whenever a building is placed on the map, its exact footprint and visual state are dictated by these three structures.
* **`Placement`**: A read-only struct that combines a `Vector3Int Coordinates`, an `Orientation`, and a `FlipMode`. This is the definitive record of *where* and *how* a building exists in the world.
* **`Orientation`**: An enum defining the four 90-degree clockwise rotations: `Cw0`, `Cw90`, `Cw180`, and `Cw270`. The `OrientationExtensions` class provides methods to mathematically transform vectors, returning rotated coordinates based on these angles.
* **`FlipMode`**: Represents whether a building has been mirrored (e.g., asymmetrical buildings like Lodges or Power Shafts). If `IsFlipped` is true, its `Transform` method mathematically mirrors coordinates along the X-axis using `width - coordinates.x - 1`.

### 3. Navigation and Proximity (`Deltas`, `Direction2D/3D`)
When systems need to check adjacent tiles (like water spreading or pathfinding), they rely on standardized directional helpers.
* **`Direction2D` & `Direction3D`**: Enums defining cardinal directions (`Down`, `Left`, `Up`, `Right`, and `Bottom`/`Top` for 3D). *Note: In this context, "Down/Up" refer to south/north on the 2D grid, whereas "Bottom/Top" refer to elevation*.
* **`Deltas`**: A static collection of pre-calculated `Vector3Int` and `Vector2Int` arrays used for rapid iteration. It provides standard adjacency checks:
    * `Neighbors4`: The four cardinal directions.
    * `Neighbors8`: The eight surrounding tiles on a 2D plane (including diagonals).
    * `Neighbors6`: The six adjacent faces of a 3D cube.
    * `Neighbors26`: Every surrounding block in a 3x3x3 3D grid.
* **`NeighbourFinder.GetSpiralNeighboursXY`**: Generates a sequence of `Vector2Int` coordinates expanding outward in a spiral pattern from a center point, heavily used by AI routines to find the closest available block.


### 4. Auto-Tiling Logic (`NeighboredValues4/6/8`)
These classes are used to calculate correct 3D models for connectable structures like paths, power shafts, or levees.
* **Index Generation**: They take boolean inputs (e.g., is there a path `up`, `down`, `left`, `right`?) and compress them into a bitwise integer/long index.
* **Rotational Mapping**: The `AddVariants` method automatically takes a base 3D model and registers it for all four rotated orientations (`Cw0`, `Cw90`, `Cw180`, `Cw270`), drastically reducing the amount of manual configuration needed to define an auto-tiling ruleset.

---

## How to Use This in a Mod

### Checking Neighboring Tiles
If you are writing a custom building behavior (like a heater that warms up adjacent houses), you should use the `Deltas` array to check surrounding tiles cleanly without writing manual offset logic.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Coordinates;
using Timberborn.BlockSystem;
using UnityEngine;

public class AreaHeater : BaseComponent
{
    private IBlockService _blockService;
    private BlockObject _blockObject;

    public void WarmAdjacentBuildings()
    {
        Vector3Int myLocation = _blockObject.Coordinates;

        // Loop through the 4 cardinal directions using pre-built deltas
        foreach (Vector3Int offset in Deltas.Neighbors4Vector3Int)
        {
            Vector3Int neighborLocation = myLocation + offset;
            
            // Check if there is an object at that specific grid coordinate
            BlockObject neighbor = _blockService.GetBottomObjectAt(neighborLocation);
            if (neighbor != null)
            {
                ApplyHeat(neighbor);
            }
        }
    }
}
```

---

## Modding Insights & Limitations

* **The Z/Y Trap**: The absolute most common mistake for Timberborn modders is forgetting that Unity's `Transform.position.y` maps to Timberborn's Grid `Z`. If you manually add `Vector3Int(0, 1, 0)` to a grid coordinate expecting it to move *up in elevation*, you will actually move it *North* on the map. Always use `CoordinateSystem.WorldToGrid()` or `GridToWorld()` rather than mapping floats yourself.
* **Transform Limitations**: The `OrientationTransform` struct allows modifying raw mesh vertices and normals based on orientation. However, it only operates on world space rotations around the Y-axis. This works perfectly for placing buildings on flat ground, but it natively lacks the complex quaternion math needed to attach a building upside down or flush against a vertical wall.
* **Flip Mode Execution**: The `FlipMode.Transform` logic flips coordinates relative to the building's specific `width` parameter (`width - coordinates.x - 1`). This means flipping is *strictly* bound to the X-axis of the local grid. Modders creating asymmetrical assets must model their assets so that X-axis mirroring results in the visually correct counterpart.
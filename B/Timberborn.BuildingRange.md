# Timberborn.BuildingRange

## Overview
The `Timberborn.BuildingRange` module is a small, specialized assembly that defines the foundational interfaces and component markers used to represent a building's area of effect (range). Rather than containing the complex pathfinding or radial math itself, it provides the structural components that other systems (like the UI highlighters or specific building logic) use to identify and query range data.

---

## Key Components

### 1. `IBuildingWithRange`
This is the primary interface that any building with an area-of-effect should implement. It establishes a unified contract for querying range data:
* **`RangeName`**: A string representing the name of the range (often used for UI localization keys).
* **`GetBlocksInRange()`**: Returns an `IEnumerable<Vector3Int>`, representing the absolute world grid coordinates that fall within the building's range. This is typically used by highlighting systems to draw colored overlays on the ground.
* **`GetObjectsInRange()`**: Returns an `IEnumerable<BaseComponent>`, representing the actual entities located within that range.

### 2. Range Marker Components
The module provides two empty `BaseComponent` classes that act as tags or markers:
* **`BuildingWithRoadSpillRange`**: Attached to buildings whose range is determined by how far a beaver can walk along paths starting from the building's entrance (e.g., Builder's Huts or District Centers).
* **`BuildingWithTerrainRange`**: Attached to buildings whose range is determined by a raw radial or rectangular distance over the terrain, regardless of paths (e.g., Water Pumps or Lumberjack Flags).

### 3. `BuildingRangeConfigurator`
A simple Bindito configurator that binds the two marker components (`BuildingWithRoadSpillRange` and `BuildingWithTerrainRange`) as transient dependencies in both the `Game` and `MapEditor` contexts.

---

## How to Use This in a Mod

### Implementing a Custom Range
If your mod introduces a building with a unique area of effect (like a "Radio Tower" that buffs buildings in a massive circle), you should implement `IBuildingWithRange` on your building's core logic component. This ensures the vanilla UI systems (like range highlighters when the building is selected) will automatically detect and draw your custom range.

```csharp
using System.Collections.Generic;
using Timberborn.BaseComponentSystem;
using Timberborn.BlockSystem;
using Timberborn.BuildingRange;
using UnityEngine;

public class RadioTower : BaseComponent, IBuildingWithRange
{
    private BlockObjectRange _blockObjectRange;
    
    // The name used by the UI tooltip
    public string RangeName => "RadioSignal";

    public void Awake()
    {
        // Use the vanilla range helper
        _blockObjectRange = GetComponent<BlockObjectRange>();
    }

    public IEnumerable<Vector3Int> GetBlocksInRange()
    {
        // Return a 15-tile radius using the helper from Timberborn.BlockSystem
        return _blockObjectRange.GetBlocksOnTerrainOrStackableInRectangularRadius(15, finishedOnly: true);
    }

    public IEnumerable<BaseComponent> GetObjectsInRange()
    {
        // Implementation would query the grid at the coordinates returned above
        // to find and yield valid targets (e.g., other buildings).
        yield break; 
    }
}
```

---

## Modding Insights & Limitations

* **Interface vs Marker**: The module provides both an interface (`IBuildingWithRange`) and concrete marker components (`BuildingWithTerrainRange`, `BuildingWithRoadSpillRange`). However, the markers themselves do *not* implement `IBuildingWithRange`. These markers are strictly used by other UI components (found in other assemblies) to trigger specific visual overlay styles (e.g., drawing a solid circle vs drawing a web of path lines), while the interface is used to fetch the actual coordinate data.
* **No Built-in Logic**: This module contains absolutely no math or pathfinding logic. Implementers of `IBuildingWithRange` must calculate their own `Vector3Int` coordinates, often relying on `Timberborn.BlockSystem.BlockObjectRange` or `Timberborn.GridTraversing` to do the heavy lifting.
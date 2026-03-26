# Timberborn.BlockSystem

## Overview
The `Timberborn.BlockSystem` module is the foundational voxel-like grid architecture that governs physical space in Timberborn. It dictates how objects exist in the 3D world, how they stack vertically, how they share space within a single coordinate, and how the game validates whether a placement defies physics (like floating buildings). 

---

## The Anatomy of a Tile (Grid Sharing)
Unlike simple grid games where one tile equals one building, Timberborn allows multiple distinct `BlockObject` entities to occupy the exact same 1x1x1 spatial coordinate simultaneously. 
This is achieved through the `WorldBlock` struct and the bitwise `BlockOccupations` enum. A single `WorldBlock` coordinate has specific "slots" that can be filled independently:
* **Floor & Path**: Used by ground-level decorations or paths (`BlockOccupations.Floor`, `BlockOccupations.Path`).
* **Bottom & Top**: Used by stackable objects or multi-story buildings (`BlockOccupations.Bottom`, `BlockOccupations.Top`).
* **Middle & Corners**: Used for specialized intersection blocks (`BlockOccupations.Middle`, `BlockOccupations.Corners`).
* **Underground**: A completely separate slot allowing an object (like a root or pipe) to exist in the same XYZ coordinate as a surface building, provided the terrain allows it.

---

## Key Components

### 1. `BlockObject`
The absolute core component attached to *everything* placed on the grid (buildings, paths, trees, ruins).
* **Spatial Data**: It holds the entity's `Coordinates`, `Orientation` (e.g., Cw90, Cw270), and `FlipMode`.
* **Block Collection**: It owns a `PositionedBlocks` collection, representing every individual grid coordinate the entity consumes based on its size and rotation.
* **Overridable Flag**: Exposes an `Overridable` boolean. If true, placing a solid object on top of this one (like a building over a path) will instantly delete this object via the `OverridenBlockObjectService`.

### 2. `BlockService` (The Master Grid)
This singleton is the central authority of the physical world.
* **Array3D**: It maintains an `Array3D<WorldBlock>` mapping the entire map.
* **Querying**: Provides essential methods for modders like `GetObjectsAt(Vector3Int)`, `GetBottomObjectAt(Vector3Int)`, and `AnyNonOverridableObjectBelow(Vector3Int)`.

### 3. Validation Ecosystem (`BlockValidator` & `MatterBelowValidator`)
Before an object can enter the world, the game checks its physical validity.
* **`MatterBelow`**: Every `BlockSpec` defines what must exist underneath it (`Ground`, `Air`, `Stackable`, `GroundOrStackable`, or `Any`). The `MatterBelowValidator` checks the `ITerrainService` and `StackableBlockService` to ensure the building won't float or clip illegally.

---

## The Block Lifecycle & States
A building does not just "exist"; it transitions through strict states managed by `BlockObjectState`.

1.  **Preview (`State.Preview`)**: The player is holding the building (the blue ghost). It exists in the `PreviewBlockService` but *not* the main `BlockService`.
2.  **Unfinished (`State.Unfinished`)**: The ghost is placed as a construction site. The game fires an `EnteredUnfinishedStateEvent` on the `EventBus`.
3.  **Finished (`State.Finished`)**: Construction is complete. The game fires an `EnteredFinishedStateEvent`, which is the critical trigger for most functional components (like water pumps or power shafts) to start ticking.

---

## How to Use This in a Mod

### Safely Querying the Grid
If your mod introduces a custom area-of-effect or needs to find neighboring buildings, you should inject `IBlockService` and query coordinates safely:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.BlockSystem;
using Timberborn.Coordinates;
using UnityEngine;

public class NeighborScanner : BaseComponent
{
    private IBlockService _blockService;
    private BlockObject _myBlockObject;

    // Inject the interface, not the concrete class
    [Inject]
    public void InjectDependencies(IBlockService blockService)
    {
        _blockService = blockService;
    }

    public void Awake()
    {
        _myBlockObject = GetComponent<BlockObject>();
    }

    public void ScanAbove()
    {
        // Grid Z is vertical height. We check one block exactly above our base coordinates.
        Vector3Int aboveCoords = _myBlockObject.CoordinatesAtBaseZ + new Vector3Int(0, 0, 1);
        
        if (_blockService.Contains(aboveCoords))
        {
            BlockObject objectAbove = _blockService.GetBottomObjectAt(aboveCoords);
            if (objectAbove != null) 
            {
                Debug.Log($"Found {objectAbove.name} resting on me!");
            }
        }
    }
}
```

---

## Modding Insights & Limitations

* **Z is Up, Not Y**: In Timberborn's Grid Coordinate System (`Vector3Int`), the `Z` axis represents vertical altitude, while `X` and `Y` are the flat ground plane. When translating this to Unity's World Space (`Vector3`), `Z` maps to Unity's `Y` axis. The `BlockObjectCenter` and `CoordinateSystem` classes handle this math natively.
* **Event Bus Reliance**: The system heavily relies on `Timberborn.SingletonSystem.EventBus`. When `BlockService.SetObject` is called, it posts a `BlockObjectSetEvent`. Modders should listen to these events rather than running expensive `Update()` loops to check if a grid tile changed.
* **List Pre-allocation Penalty**: Notice in `BlockService.GetIntersectingObjectsAt` and `BlockOccupier.CoordinatesHaveNoOtherObjectsExceptFloor`, the code requires you to pass in an already instantiated `List<BlockObject>`. This is an engine-wide performance pattern to eliminate Garbage Collection (GC) spikes. Modders must adhere to this by using member-level lists rather than instantiating new lists inside loops.
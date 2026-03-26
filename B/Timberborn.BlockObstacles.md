# Timberborn.BlockObstacles

## Overview
The `Timberborn.BlockObstacles` module manages dynamic, multi-layered vertical obstructions within the game world. Unlike standard static buildings, this system allows for obstacles (like floodgates) that can change their vertical occupancy dynamically. It achieves this by managing invisible blocking entities that update the game's block system and navigation meshes in real-time as the obstacle changes height.

---

## Key Components

### 1. `BlockOccupier`
This is a component attached to invisible entities that act as proxies to block specific tiles in the game world.
* **Capabilities**: It registers itself with the game's block system by calling `BlockObject.MarkAsFinishedAndAddToServices()`. It also recalculates and enqueues itself to the regular NavMesh via `IBlockObjectNavMesh` to prevent beavers from walking through it.
* **Validation**: The `CanBeAddedToServices()` method ensures that the target coordinates are not underground (checked via `ITerrainService`) and have no other non-overridable objects present except for the floor.

### 2. `BlockOccupationLayer`
This class represents a logical grouping of `BlockOccupier` instances that make up a single horizontal "slice" of an obstacle at a specific `GridHeight`.
* **Management**: It contains methods like `AddToServices()` and `RemoveFromServices()` which iterate through its internal list of `BlockOccupier` objects and applies the state change to all of them.
* **Destruction**: When `Remove()` is called, it removes the occupiers from the services and explicitly calls `Object.Destroy()` on their GameObjects.

### 3. `LayeredBlockObstacle`
This is the core logic component that must be attached to the root of the dynamic obstacle.
* **Dynamic Range Tracking**: It tracks an `OccupancyRange` as a `float`, which is saved and loaded via the `IPersistentEntity` interface.
* **Layer Initialization**: Upon entering the finished state, it calculates the required number of layers based on its `AnchorPosition` and a `BlockCreationOffset` defined in `LayeredBlockObstacleSpec`.
* **Environment Adaptation**: It actively listens to `TerrainHeightChanged`, `BlockObjectSetEvent`, and `BlockObjectUnsetEvent` on the `EventBus`. When the environment changes, it recalculates its `MaxOccupancyRange` to ensure it does not attempt to occupy spaces filled by dirt or new buildings.

### 4. `BlockOccupationLayerFactory`
This factory is responsible for actually instantiating the invisible blocker entities.
* **Entity Creation**: It uses `BlockObjectFactory.CreateAsPreview()` to spawn the blocker entities based on a hidden `BlockOccupierSpec` template. 
* **Naming**: The spawned entities are explicitly named `"BlockOccupier {coordinates}"` in the Unity hierarchy.

### 5. `LayeredBlockObstacleVisualizer`
This component handles the visual animation of the dynamic obstacle.
* **Interpolation**: It is a `TickableComponent` that calculates an `_occupancyChangeRate` and smoothly interpolates the visual model towards the logical `OccupancyRange` using `Mathf.MoveTowards`.
* **Transform Manipulation**: It directly modifies the `localPosition` (moving it down by the occupancy range) and `localScale` (increasing the Y scale by the occupancy range) of the transforms specified in `LayeredBlockObstacleVisualizerSpec`.

---

## How to Use This in a Mod

### Creating a Custom Dynamic Barrier
If you want to create a new type of dynamic vertical barrier, you can configure your building's JSON template to utilize this system without writing custom collision logic.

1.  **Add the Specs to your Prefab**:
    Your building's template needs to include the configuration specs to define the dimensions and visual moving parts:
    ```json
    {
      "LayeredBlockObstacleSpec": {
        "LayerSize": {"X": 2, "Y": 1},
        "AnchorPosition": {"X": 0.0, "Y": 0.0, "Z": 0.0},
        "BlockCreationOffset": 0
      },
      "LayeredBlockObstacleVisualizerSpec": {
        "PositionTransformName": "MovingPart",
        "ScaleTransformName": "ScalingPart"
      }
    }
    ```
2.  **Control the Range via Script**:
    Write a custom script that interacts with the `LayeredBlockObstacle` to change its state by accessing `ModifyOccupancyRange()`.
    ```csharp
    using Timberborn.BaseComponentSystem;
    using Timberborn.BlockObstacles;

    public class CustomBarrierController : BaseComponent
    {
        private LayeredBlockObstacle _obstacle;

        public void Awake()
        {
            _obstacle = GetComponent<LayeredBlockObstacle>();
        }

        public void LowerBarrier()
        {
            // Lower the physical and visual barrier by 1 block
            _obstacle.ModifyOccupancyRange(-1.0f);
        }
    }
    ```

---

## Modding Insights & Limitations

* **Entity Spawning Overhead**: Because `BlockOccupationLayerFactory` spawns a real `BlockObject` for every single grid coordinate the obstacle occupies, extremely large dynamic obstacles may introduce a slight performance overhead during initialization.
* **Hardcoded Minimum Change Rate**: The `LayeredBlockObstacleVisualizer` enforces a `private static readonly float MinimumChangeRate = 0.001f;`. If a mod attempts to animate the obstacle slower than this threshold, the visualizer will clamp it to the minimum speed.
* **Strictly Vertical**: The logic in `LayeredBlockObstacleVisualizer` strictly alters the Y-axis of the `localPosition` and `localScale`. Modders cannot use this vanilla system to create horizontally extending barriers (like sliding doors or drawbridges) without writing a completely custom visualizer.
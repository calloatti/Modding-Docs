# Timberborn.Buildings (Deep Dive)

## Overview
The `Timberborn.Buildings` module is a massive, complex layer that sits directly on top of the generic `BlockSystem`. While the `BlockSystem` handles pure spatial coordinates, this module defines the specific logic, lifecycles, accessibility, and dynamic visual states of actual structures placed by the player. It serves as the connective tissue between the physical grid, the pathfinding NavMesh, the rendering engine, and the player's UI controls.

---

## 1. The Building Lifecycle & State Machine
A building in Timberborn does not statically exist; it flows through a strict state machine driven by events. The visual representation of this lifecycle is handled entirely by the `BuildingModel` component.



* **Preview State**: When the player is dragging a ghost building, `BuildingModel` listens to `IPreviewStateListener` and temporarily calls `ShowFinishedModel()`. This allows the player to see what the final building will look like before placing it.
* **Unfinished State**: Upon placement, it receives `OnEnterUnfinishedState()` via the `IUnfinishedStateListener` interface, immediately switching the visible mesh by calling `ShowUnfinishedModel()`.
* **Finished State**: When builders complete the construction, the `IFinishedStateListener` triggers `OnEnterFinishedState()`, swapping back to the full model.
* **Visibility Matrices**: The `ToggleModelVisibility()` method is highly complex, balancing five different boolean states (`showFinished`, `showFinishedShadows`, `showFinishedUncovered`, `showUnfinished`, `showUndergroundModel`). It actively queries the `BlockObjectModelController` to determine if the building is currently "sliced" by the player's Z-level camera view, adjusting the active models accordingly.

---

## 2. Dynamic Mesh Updating (`BuildingModelUpdater`)
Timberborn buildings often have dynamic meshes that adapt to their surroundings (e.g., a staircase adding a handrail if a path is built next to it). The `BuildingModelUpdater` is the singleton responsible for triggering these visual refreshes.



* **Dual-Trigger System**: It listens to two entirely different systems to detect environmental changes:
    1.  **Block System**: `OnBlockObjectSetEvent` and `OnBlockObjectUnsetEvent`.
    2.  **NavMesh System**: `OnPreviewNavMeshUpdated` and `OnInstantNavMeshUpdated`.
* **Spatial Querying**: When an object is placed, `UpdateBuildingsModelsAround(BlockObject)` calculates a bounding box around the placed object. It uses `OrientationExtensions.Transform` to determine the exact min/max bounds based on rotation. It then iterates through the perimeter coordinates (X-1 to X+1, Y-1 to Y+1) and forces any `BlockObjectModelController` found in those spaces to run `UpdateModel()`. It performs a similar check for the tile directly below the object (`UpdateBuildingModelsBelow`).

---

## 3. Accessibility & Path Validation
For a building to function, beavers must be able to reach it. This is split into physical access points and path validation.

* **`BuildingAccessible`**: Translates the logical grid entrance into a physical 3D world coordinate. If `ForceOneFinalAccess` is false, it uses `CoordinateSystem.GridToWorldCentered(_blockObject.PositionedEntrance.Coordinates)`. This provides the actual walking destination for the beaver AI.
* **`BuildingBlockedAccessible`**: This component dynamically checks if the building is orphaned. During its enabled state, `IsBlocked()` queries the `INavMeshService` to ensure a valid route exists between the building's internal `Coordinates` and its external `DoorstepCoordinates`. If this connection is severed, the building shuts down and displays a "No Path" warning.

---

## 4. The Pause Architecture (`PausableBuilding`)
The `PausableBuilding` component allows players to halt a building's operation. It uses a highly decoupled interface discovery pattern.

* **Interface Discovery**: During `Awake()`, it does not check for specific building types (like "WaterPump" or "Farm"). Instead, it uses `GetComponents(_unfinishedPausables)` and `GetComponents(_finishedPausables)`. It looks for *any* component attached to the entity that implements the empty `IFinishedPausable` or `IUnfinishedPausable` marker interfaces.
* **State Locking**: If paused, it utilizes the `Timberborn.BlockingSystem` to call `_blockableObject.Block(this)`. This centralized blocking mechanism tells all other logic scripts on the entity to suspend execution.
* **Memory Efficiency**: In `Save(IEntitySaver)`, it uses the conditional `if (Paused)`. If a building is running normally, its pause state is completely omitted from the save file, saving memory.

---

## 5. Advanced Visual Controllers
The module contains several specialized rendering components to handle edge-case visuals.

* **`UncoveredModelSwitcher`**: Directly integrates with the `ILevelVisibilityService`. If the player uses the slice tool, and the `MaxVisibleLevel` falls between the building's bottom Z and top Z coordinate (`maxVisibleLevel >= z && maxVisibleLevel <= num`), it loops through pre-collected child objects to hide the `_fullModels` and display the `_uncoveredModels`.
* **`BuildingTerrainCutout`**: Resolves Z-fighting and clipping between basements and terrain. When the finished model is shown, it feeds an array of coordinates to the `TerrainCutout` service to literally punch holes in the ground mesh underneath the building.
* **`FireIntensityController`**: A hardcoded animation script for flames. It modifies the `startSizeMultiplier` and `startLifetimeMultiplier` of a Unity `ParticleSystem.MainModule`. Calling `Strengthen()` scales the fire by 2.5x size and 3.1x lifetime for exactly 0.25 seconds. Calling `Dampen()` kills the fire (0x multipliers) for 0.5 seconds.

---

## Modding Applications & Strict Patterns

### Pattern: Pre-allocated Component Retrieval
Notice the strict pattern used in `PausableBuilding.Awake()`:
```csharp
private readonly List<IUnfinishedPausable> _unfinishedPausables = new List<IUnfinishedPausable>();

public void Awake()
{
    // CORRECT TIMBERBORN PATTERN: Pass a pre-allocated list to prevent GC spikes
    GetComponents(_unfinishedPausables); 
}
```
Modders **must** use this pattern when writing custom building logic. Using Unity's native `var list = GetComponents<T>()` will result in compiler errors (CS7036/CS0815) because Timberborn's optimized `BaseComponent` system returns `void` for this method to prevent Garbage Collection allocation overhead.

### Making a Custom Building Pausable
If you are creating a custom building logic script (e.g., a modded drone charging station), you must explicitly flag it so the `PausableBuilding` component knows it exists:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Buildings;

// 1. Add IFinishedPausable to your class declaration
public class DroneCharger : BaseComponent, IUpdatableComponent, IFinishedPausable
{
    private BlockableObject _blockableObject;

    public void Awake()
    {
        _blockableObject = GetComponent<BlockableObject>();
    }

    public void Update()
    {
        // 2. You MUST check the block state every tick
        if (_blockableObject.IsBlocked) return;

        // Perform charging logic here...
    }
}
```

### Insights & Modding Limitations
* **Hardcoded Fire Logic**: The `FireIntensityController` uses entirely hardcoded float values for its multipliers and durations (`2.5f`, `3.1f`, `0.25f`). Modders cannot customize the intensity of the "Strengthen" or "Dampen" effects via JSON specs. If a modded building requires a massive bonfire or a tiny candle, the modder must write a completely custom particle controller.
* **Terrain Cutout Timing**: The `BuildingTerrainCutout` only activates if `_blockObjectModelController.IsFinishedModelShown` evaluates to true. Consequently, while a building is a construction site (unfinished), the terrain cutout is disabled, meaning dirt will visually clip through any deep foundations until the building is built.
* **Duplicate Blueprint Requirements**: The `BuildingSpec` requires the JSON file to define `BuildingCost` (an array of `GoodAmountSpec`) and `ScienceCost`. Modders must ensure their JSON templates align precisely with these requirements, or the `BasicDeserializer` (from the Blueprint System) will fail to load the building.
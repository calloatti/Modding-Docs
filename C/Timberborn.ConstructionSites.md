# Timberborn.ConstructionSites

## Overview
The `Timberborn.ConstructionSites` module is responsible for the entire lifecycle of a building's construction phase. It manages the creation of unfinished "ghost" buildings, tracks resource delivery, manages AI builder assignments, prevents construction on invalid terrain, and updates the visual progress models.

---

## Key Components

### 1. `ConstructionSite` & `ConstructionRegistry`
`ConstructionSite` is the core state component attached to every unfinished building.
* **Initialization**: The `ConstructionFactory` creates a new building via `CreateAsUnfinished`, ensuring the `BlockObject` is flagged as unfinished. The `ConstructionSiteInventoryInitializer` then reads the `BuildingSpec.BuildingCost` and generates an `Inventory` specifically to hold the required goods.
* **Registration**: When the site enters the unfinished state, `ConstructionRegistrar` adds it to the global `ConstructionRegistry`. The registry organizes jobs by `Priority` and `InstantiationOrder` (so older blueprints get built first).
* **Completion Check**: Every tick, the site checks `IsReadyToFinish`. This requires:
    1. `Inventory.IsFull` (all materials delivered).
    2. `BuildTimeProgressInHours >= _constructionTimeInHours` (builders have spent enough time working on it).
    3. `!BlockedByBeaversOnSite()` (if the building is dangerous to finish while someone is standing on it, it waits for them to leave).
    4. `IsOn` (the site is validly grounded and not blocked by the player).
    If all conditions are met, it calls `_blockObject.MarkAsFinished()`.

### 2. Builder AI (`Builder`, `BuildBehavior`, `BuildExecutor`)
These components are attached to worker beavers (like those employed at the Builder's Hut).
* **`ConstructionJob`**: The actual task node the AI interacts with. If a site lacks materials, `StartConstructionJob()` will look for the closest warehouse with the required goods and dispatch the beaver to carry them to the site.
* **`BuildBehavior`**: If the site has materials, this behavior paths the beaver to the site (using `WalkToAccessibleExecutor` or entering the building if it has slots).
* **`BuildExecutor`**: Once the beaver arrives, this `IExecutor` node ticks every frame, calling `_constructionSite.IncreaseBuildTime(deltaTimeInHours * _worker.WorkingSpeedMultiplier)`. It also manages the character's `"Building"` animation and forces them to look at the center of the construction site.

### 3. Validation & Support
A building blueprint can be placed, but it won't be built if the ground beneath it changes or becomes invalid.
* **`IConstructionSiteValidator`**: Components implementing this interface restrict the `IsOn` state of the `ConstructionSite`.
* **`GroundedConstructionSite`**: Ensures that the `MatterBelow` the building is solid. If a player deletes the platform underneath a blueprint, `Validate()` marks the site as invalid, halting construction.
* **`PhysicallySupportedConstructionSite`**: Uses `ITerrainPhysicsService` to ensure terrain blocks (like dirt blocks) obey overhang and support physics rules.

### 4. Visual Progress (`ConstructionSiteProgressVisualizer`)
* **Thresholds**: It reads the `ConstructionSiteProgressVisualizerSpec.ProgressThresholds` array (e.g., `[0.33, 0.66]`).
* **Model Swapping**: Based on the `BuildTimeProgress`, it calculates the current `stageIndex` and activates the corresponding child `GameObject` inside the `UnfinishedModel` transform. This is what causes scaffolding to visually "grow" as the beaver hammers on it.

---

## How to Use This in a Mod

### Adding a Custom Finish Blocker
If your mod introduces a new mechanic—for example, a "Curing" process where a building must sit in the sun for a day after being built before it is truly finished—you can implement `IConstructionFinishBlocker`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.ConstructionSites;

public class SunCuringRequirement : BaseComponent, IConstructionFinishBlocker
{
    private bool _isCured = false;

    // The ConstructionSite checks this every tick.
    // If true, the building will stay in the Unfinished state even if
    // all materials are delivered and build time is complete.
    public bool IsFinishBlocked => !_isCured;

    public void Cure()
    {
        _isCured = true;
    }
}
```
If you add this component to your building's prefab, the vanilla `ConstructionSite` will automatically find it via `GetComponent<IConstructionFinishBlocker>()` during `Awake()` and respect your custom logic.

---

## Modding Insights & Limitations

* **Builder Limits**: The `ConstructionSiteBuildersLimiter` calculates how many beavers can work on a site simultaneously based on how many materials have been delivered. It uses hardcoded gaps (`ProgressGapNoBuilders = 0.1f`, `ProgressGapFullBuilders = 0.3f`). This means if a building is less than 10% funded with materials, 0 builders are allowed to work on it. If it is 30% funded, the maximum number of builders (defined in the JSON spec) can work. Modders cannot change these thresholds via JSON.
* **Instant Finish**: The `ConstructionFactory.CreateAsFinished()` method creates an unfinished site and immediately calls `FinishNow()` on it. This is how Map Editor buildings are spawned. `FinishNow()` bypasses all inventory requirements by magically spawning the required goods out of thin air (`Inventory.GiveIgnoringCapacityReservation`) to satisfy the completion logic.
* **Missing Material Priority**: The `ConstructionJob` always uses the `SortedSet` to find remaining goods. It iterates through the missing goods and grabs the first one it can find a path to. There is no way for a modder to force beavers to deliver "Wood" before "Gears"; the AI fetches whatever is closest and available.
# Timberborn.BuilderHubSystem

## Overview
The `Timberborn.BuilderHubSystem` module manages the behavior and job delegation for entities assigned to Builder's Huts or similar construction-focused workplaces. Instead of individual beavers scanning the map for construction tasks, this system centralizes the job discovery process within the workplace itself, dispatching assigned workers to valid jobs according to player-defined priorities.

---

## Key Components

### 1. `BuilderHubWorkplaceBehavior`
This is the core behavioral node that dictates what a worker assigned to a Builder's Hut actually does.
* **Job Evaluation Loop**: When `Decide()` is called by a worker's `BehaviorAgent`, it iterates through all possible `Priority` levels (from Highest to Lowest).
* **Provider Iteration**: For *each* priority level, it queries all registered `IBuilderJobProvider` instances (sorted by `ProviderPriority`). If a provider returns a valid `Decision` that is not `ShouldReleaseNow`, it immediately transfers the worker to that task.
* **Fallback**: If no jobs are found across any priority or provider, it releases the worker, allowing them to fall through to lower-priority workplace behaviors (like emptying inventories or waiting idly).

### 2. `IBuilderJobProvider`
An interface defining a source of construction-related tasks.
* **Contract**: Implementers must provide a `ProviderPriority` (an integer determining the order providers are queried) and a `GetJob` method that takes the worker (`BehaviorAgent`), the workplace's `Accessible` node, and the current `Priority` level being evaluated.

### 3. `BuildingJobProvider`
The vanilla implementation of `IBuilderJobProvider` that specifically targets standard building construction.
* **Registry Query**: It queries the `ConstructionRegistry` for all `ConstructionJob` instances matching the requested `Priority`.
* **Job Claiming**: It attempts to start the job via `job.StartConstructionJob(agent, start)`. If the job is successfully claimed and pathable, it returns the resulting `Behavior` and `Decision` back to the hub.

### 4. `BuilderHubSystemConfigurator`
This class sets up the dependency injection and template decorators for builder hubs.
* **Decorators**: It adds a robust stack of behaviors to any prefab possessing a `BuilderHubSpec`. 
* **Behavior Stack**: The decorators added are evaluated in this order:
    1. `BuilderHubWorkplaceBehavior` (primary construction jobs)
    2. `EmptyOutputWorkplaceBehavior` (hauling output goods, if any)
    3. `RemoveUnwantedStockWorkplaceBehavior` (cleaning up incorrect goods)
    4. `EmptyInventoriesWorkplaceBehavior` (emptying internal storage)
    5. `LaborWorkplaceBehavior`
    6. `WaitInsideIdlyWorkplaceBehavior` (fallback idle state)

---

## How to Use This in a Mod

### Creating a Custom Builder Job Provider
If your mod introduces a new type of task that "Builders" should perform—such as a specialized terrain terraforming task or repairing broken structures—you can inject your own `IBuilderJobProvider`.

**1. Create the Provider:**
```csharp
using Timberborn.BehaviorSystem;
using Timberborn.BuilderHubSystem;
using Timberborn.Navigation;
using Timberborn.PrioritySystem;

public class RepairJobProvider : IBuilderJobProvider
{
    private readonly MyCustomRepairRegistry _repairRegistry;

    // Use a higher or lower number to determine if this runs before or after vanilla building
    // Vanilla BuildingJobProvider uses priority 1
    public int ProviderPriority => 2; 

    public RepairJobProvider(MyCustomRepairRegistry repairRegistry)
    {
        _repairRegistry = repairRegistry;
    }

    public (Behavior, Decision) GetJob(Accessible start, BehaviorAgent agent, Priority priority)
    {
        // Fetch custom jobs matching the current priority tier
        foreach (var repairJob in _repairRegistry.GetJobs(priority))
        {
            var (behavior, decision) = repairJob.TryAssignWorker(agent, start);
            if (!decision.ShouldReleaseNow)
            {
                return (behavior, decision);
            }
        }
        return (null, Decision.ReleaseNow());
    }
}
```

**2. Bind it in your Configurator:**
```csharp
using Bindito.Core;
using Timberborn.BuilderHubSystem;

[Context("Game")]
internal class MyRepairConfigurator : Configurator
{
    protected override void Configure()
    {
        // Use MultiBind so the BuilderHubWorkplaceBehavior picks it up alongside the vanilla providers
        MultiBind<IBuilderJobProvider>().To<RepairJobProvider>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Strict Priority Loop**: The nested loops in `BuilderHubWorkplaceBehavior.Decide` enforce a very strict priority system. The game will completely exhaust *all* providers for `Priority.Highest` before it even looks at `Priority.High` for any provider. This ensures players have absolute control over what gets built first, regardless of the job type.
* **No Internal Pathfinding Cache**: The `BuildingJobProvider` iterates through jobs in the registry and relies on `StartConstructionJob` to determine if a path actually exists. If a map has many unreachable High-Priority construction sites, every idle builder will continuously attempt to pathfind to them every time `Decide()` ticks, which can cause significant performance degradation. Modders implementing custom providers should consider caching unpathable jobs to prevent CPU spiking.
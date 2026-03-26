# Timberborn.BuilderPrioritySystem

## Overview
The `Timberborn.BuilderPrioritySystem` is a small state-management module that allows players to designate the importance of specific construction tasks relative to others. It provides the foundational `BuilderPrioritizable` component, which stores a `Priority` value that builder AI uses to determine which jobs to tackle first.

---

## Key Components

### 1. `BuilderPrioritizable`
This is the core component attached to entities that can be prioritized by builders. It implements several key interfaces to ensure its state is managed correctly:
* **State Management (`IPrioritizable`)**: It exposes a `Priority` property (defaulting to `Priority.Normal`) and a `SetPriority()` method. When the priority changes, it fires a `PriorityChanged` event, allowing the construction registries to re-sort the job.
* **Lifecycle**: By default, it disables itself during `Awake()`. It provides explicit `Enable()` and `Disable()` methods, firing corresponding events (`PrioritizableEnabled`, `PrioritizableDisabled`) so external systems know when the entity is eligible for prioritization. Disabling the component safely resets the `Priority` back to `Normal`.
* **Persistence (`IPersistentEntity`)**: It saves its state to the save file, but *only* if the priority is not `Normal` (`if (Priority != Priority.Normal)`). This is a minor optimization to keep save files smaller by omitting default states.
* **Duplication (`IDuplicable`)**: It supports the game's blueprint-copying tools. If a player uses the "Copy Building" tool on an unfinished construction site with a "Highest" priority, the new placement will inherit that same priority. It explicitly prevents duplication if the target is finished and disabled (`(base.Enabled || !_blockObject.IsFinished)`).

### 2. `BuilderPrioritySystemConfigurator`
A minimal Bindito configurator that binds `BuilderPrioritizable` as a transient dependency in both the `Game` and `MapEditor` contexts.

---

## How to Use This in a Mod

Because `BuilderPrioritizable` is a generic state holder, it must be attached to an entity via a Template Builder, and then its `Enable()` and `Disable()` methods must be managed by the specific system utilizing it.

For instance, if you were creating a mod that added a new type of "Terraforming" construction site, you would add the decorator:

```csharp
// In your configurator:
builder.AddDecorator<MyTerraformSiteSpec, BuilderPrioritizable>();
```

And in your logic component, you would enable it when terraforming begins, and disable it when finished:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.BuilderPrioritySystem;

public class MyTerraformSite : BaseComponent
{
    private BuilderPrioritizable _prioritizable;

    public void Awake()
    {
        _prioritizable = GetComponent<BuilderPrioritizable>();
    }

    public void StartTerraforming()
    {
        // Allow the player to change priority
        _prioritizable.Enable();
    }

    public void FinishTerraforming()
    {
        // Lock the priority and hide the UI
        _prioritizable.Disable();
    }
}
```

---

## Modding Insights & Limitations

* **No Automated Registration**: Unlike `BaseComponent` updates, attaching `BuilderPrioritizable` does not automatically register the entity with the `ConstructionRegistry` or builder AI. It purely holds the state. The actual construction site logic (e.g., `ConstructionSite.cs`) must listen to the `PriorityChanged` event and inform the registry to move the job to a different priority queue.
* **Transient Binding**: The configurator binds `BuilderPrioritizable` as `.AsTransient()`, meaning it must be instantiated per-entity rather than globally.
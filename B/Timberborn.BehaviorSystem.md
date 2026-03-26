# Timberborn.BehaviorSystem

## Overview
The `Timberborn.BehaviorSystem` module provides the core artificial intelligence framework for entities in Timberborn (primarily Beavers and Bots). It is a highly modular, component-based state machine that dictates how entities make decisions and execute actions over time. 

The system is split into two primary concepts: **Behaviors** (the decision-makers, answering "what should I do?") and **Executors** (the action-takers, answering "how do I do it over time?"). The `BehaviorManager` acts as the brain that coordinates these two pieces.

For modders, understanding this module is essential for creating custom AI routines, adding new jobs, or altering how entities interact with custom buildings.

---

## Key Components

### 1. The Brain (`BehaviorManager`)
The `BehaviorManager` is a `TickableComponent` attached to entities that require AI.
* **Root Behaviors List**: It holds a prioritized list of `RootBehavior` instances. During its tick, if it isn't already running an `IExecutor`, it iterates through this list to ask each behavior to make a `Decision`.
* **Executor Management**: If a `Decision` returns an `IExecutor`, the `BehaviorManager` locks onto it. On subsequent ticks, it calls `IExecutor.Tick()` instead of checking behaviors, until the executor returns `Success` or `Failure`.
* **State Persistence**: The manager saves and loads exactly which Behavior and Executor were running, including the elapsed time of the executor, ensuring AI tasks resume perfectly after saving/loading the game.
* **Logging**: It maintains a `_timestampedBehaviorLog` (the last 10 behaviors), which is very useful for debugging AI loops.

### 2. The Decision Makers (`Behavior` & `RootBehavior`)
* **`Behavior`**: An abstract base class that implements `Decide(BehaviorAgent agent)`. It evaluates the current state of the game and returns a `Decision`.
* **`RootBehavior`**: An empty subclass of `Behavior`. The `BehaviorManager` only iterates through *Root* behaviors when searching for a new task. Standard `Behavior` classes can only be transitioned into via a `Decision` returned by a Root behavior.

### 3. The Action Takers (`IExecutor`)
Executors represent actions that take time to complete (e.g., walking, waiting, playing an animation, or producing goods).
* **`Tick(float deltaTimeInHours)`**: Called every tick by the `BehaviorManager`. It must return an `ExecutorStatus`:
    * `Running`: The action is still ongoing.
    * `Success`: The action finished successfully. The `BehaviorManager` will now ask for a new `Decision`.
    * `Failure`: The action failed (e.g., pathfinding blocked). The `BehaviorManager` will now ask for a new `Decision`.
* **Persistence**: Executors implement `Save` and `Load` to preserve their internal state (like progress bars or target coordinates).

### 4. The Output (`Decision`)
A struct returned by `Behavior.Decide()`. It tells the `BehaviorManager` what to do next. It has several static factory methods:
* **`ReleaseNow()`**: The behavior has nothing to do right now. The manager should check the next behavior in the list.
* **`ReturnNextTick()`**: The behavior is doing something instantaneous (no executor), but wants to be called again on the very next tick.
* **`ReleaseWhenFinished(IExecutor)`**: Run the provided executor until it finishes, then drop this behavior and start checking from the top of the root list again.
* **`ReturnWhenFinished(IExecutor)`**: Run the provided executor until it finishes, then *immediately* ask this specific behavior for its next decision, bypassing the root list priority.

---

## How to Use This in a Mod

### Creating a Custom AI Action
If you want a beaver to perform a custom sequence of events (e.g., walk to a spot, then wait, then delete a block), you create a custom `RootBehavior` and custom `IExecutor` components.

**1. Create the Executor (The Action):**
```csharp
using Timberborn.BehaviorSystem;
using Timberborn.BaseComponentSystem;
using Timberborn.TimeSystem;

public class MyCustomDanceExecutor : BaseComponent, IExecutor
{
    private readonly IDayNightCycle _dayNightCycle;
    private float _finishTime;

    public MyCustomDanceExecutor(IDayNightCycle dayNightCycle) => _dayNightCycle = dayNightCycle;

    public void LaunchDance(float durationInHours)
    {
        _finishTime = _dayNightCycle.DayNumberHoursFromNow(durationInHours);
        // Trigger animation here...
    }

    public ExecutorStatus Tick(float deltaTimeInHours)
    {
        if (_dayNightCycle.PartialDayNumber > _finishTime) return ExecutorStatus.Success;
        return ExecutorStatus.Running;
    }

    // Must implement Save/Load for persistence
    public void Save(IEntitySaver entitySaver) { ... }
    public void Load(IEntityLoader entityLoader) { ... }
}
```

**2. Create the Behavior (The Logic):**
```csharp
using Timberborn.BehaviorSystem;

public class MyCustomDanceBehavior : RootBehavior
{
    private MyCustomDanceExecutor _danceExecutor;

    public void Awake()
    {
        _danceExecutor = GetComponent<MyCustomDanceExecutor>();
    }

    public override Decision Decide(BehaviorAgent agent)
    {
        if (ShouldStartDancing()) 
        {
            _danceExecutor.LaunchDance(2.0f); // Dance for 2 in-game hours
            return Decision.ReleaseWhenFinished(_danceExecutor);
        }
        
        // If we don't want to dance, let the next behavior in the list take over
        return Decision.ReleaseNow(); 
    }
}
```

**3. Register them to the Beaver:**
You would use a `Configurator` with a `TemplateModule.Builder` to add your Executor and Behavior to the `BeaverSpec`, just like `BehaviorSystemConfigurator` does. *Note: You also need to register your custom RootBehavior to the `BehaviorManager` during Awake, which is typically done by a custom Initializer component similar to `BeaverBehaviorInitializer`.*

---

## Modding Insights & Limitations

* **Priority Order Matters**: The `BehaviorManager` iterates through `_rootBehaviors` in the exact order they were added. The first behavior to return something *other* than `ReleaseNow()` wins control. Therefore, the order in which behaviors are added to the manager dictates AI priority (e.g., "Flee Danger" should be added before "Work").
* **Single Executor Limitation**: A `BehaviorManager` can only run exactly **one** `IExecutor` at a time. A beaver cannot execute a `WalkExecutor` and a `ProduceExecutor` simultaneously.
* **Serialization Matching**: The `BehaviorManager` saves the currently running executor by serializing its string name (`executor.GetName()`, which defaults to `GetType().Name`). When loading, it looks through all attached `IExecutor` components to find one with a matching name. If you rename your custom executor class in an update, existing save files will fail to deserialize the AI state correctly, potentially breaking the beaver.
# Timberborn.AchievementSystem

## Overview
The `Timberborn.AchievementSystem` module is the core framework that defines what an achievement is and how it communicates with the game's external storefront platforms (like Steam, GOG, or Epic Games). 

Unlike `Timberborn.Achievements` (which contains the specific logic for *how* vanilla achievements are earned), this DLL provides the abstract API and the service manager that orchestrates them.

---

## Key Components

### 1. `Achievement` (Abstract Base Class)
This is the foundational class that all achievements must inherit from.
* **Properties:** * `Id`: A string representing the unique identifier for the storefront backend.
  * `IsEnabled`: A boolean checking if the achievement is currently being tracked (i.e., not already unlocked).
* **Lifecycle Methods:**
  * `EnableInternal()`: A virtual method you override to start listening to game events or ticks.
  * `DisableInternal()`: A virtual method you override to clean up and unregister listeners.
* **Triggers:**
  * `Unlock()`: The method your modded logic will call when the player successfully completes the achievement's requirements.

### 2. `AchievementService` (Singleton Manager)
This `IPostLoadableSingleton` is responsible for grabbing every single registered `Achievement` in the game and figuring out if it needs to be tracked.
* **Behavior:** During the `PostLoad` phase, it initializes the store connection. It then iterates through all `Achievement` instances injected into it. If an achievement is *not* already unlocked on the player's account, it calls `Enable()` on it and attaches a callback that fires `_storeAchievements.UnlockAchievement(achievement.Id)` whenever your logic calls `Unlock()`.

### 3. `IStoreAchievements` (Interface)
This interface abstracts the connection to the storefront. Implementations of this interface (likely found in DLLs like `Timberborn.SteamAchievementSystem`) handle the actual API calls to Valve, GOG, etc.

---

## How and When to Use This in a Mod

If you are adding custom achievements to your mod, you will interact heavily with the `Achievement` class from this DLL.

### Creating a Custom Achievement
You should inherit from `Achievement` and implement your specific tracking logic. Because `AchievementService` handles the "is it already unlocked" check, you can assume that if `EnableInternal()` is called, the player actually needs to earn it.

```csharp
using System;
using Timberborn.AchievementSystem;
using Timberborn.SingletonSystem;
using Timberborn.TimeSystem; // Example dependency

public class Survive100DaysAchievement : Achievement
{
    private readonly EventBus _eventBus;
    private readonly IDayNightCycle _dayNightCycle;

    // This ID must be unique
    public override string Id => "MYMOD_SURVIVE_100_DAYS";

    public Survive100DaysAchievement(EventBus eventBus, IDayNightCycle dayNightCycle)
    {
        _eventBus = eventBus;
        _dayNightCycle = dayNightCycle;
    }

    protected override void EnableInternal()
    {
        // Start listening to day changes
        _eventBus.Register(this);
    }

    protected override void DisableInternal()
    {
        // Clean up listeners
        _eventBus.Unregister(this);
    }

    [OnEvent]
    public void OnDaytimeStart(DaytimeStartEvent daytimeStartEvent)
    {
        if (_dayNightCycle.DayNumber >= 100)
        {
            // This calls the base Achievement.Unlock(), 
            // which notifies the AchievementService!
            Unlock(); 
        }
    }
}
```

---

## Modding Insights & Limitations

* **Automatic Cleanup:** When you call `Unlock()`, the base `Achievement` class automatically calls your `DisableInternal()` method and removes its callbacks. You do not need to manually unregister your event listeners inside your unlock logic; just ensure your cleanup is properly written in `DisableInternal()`.
* **Platform Limitations (`IStoreAchievements`):** While you can easily create custom achievements and trigger the internal `Unlock()` mechanism, your custom achievement IDs (e.g., `"MYMOD_SURVIVE_100_DAYS"`) will not exist on the official Timberborn Steam/GOG backends. Unless you also build a custom UI to display modded achievements, triggering `Unlock()` on a custom ID will essentially be swallowed silently by the storefront API.
* **Dependency Injection:** To get your custom achievement to run, you do *not* touch `AchievementService`. You simply `MultiBind<Achievement>().To<YourCustomAchievement>().AsSingleton();` in your configurator. The `AchievementService` automatically requests an `IEnumerable<Achievement>`, meaning Bindito will gather all vanilla and modded achievements and hand them to the service seamlessly.
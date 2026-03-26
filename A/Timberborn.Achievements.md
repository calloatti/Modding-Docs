# Timberborn.Achievements

## Overview
The `Timberborn.Achievements` module contains the logical implementations for all vanilla, game-specific achievements in Timberborn. While the underlying framework (like the `Achievement` base class) exists in `Timberborn.AchievementSystem`, this DLL acts as the concrete implementation layer. 

It is an excellent reference for modders because it demonstrates dozens of ways to hook into Timberborn's engine to track player behavior, monitor game states, and persist data across save files.

---

## Key Modding Patterns & Mechanics

If you want to track complex player actions or add your own custom achievements, this DLL shows you exactly how Timberborn handles it internally.

### 1. Event-Driven Tracking (`EventBus`)
Most achievements in the game do not check their conditions every frame. Instead, they register to the `EventBus` and wait for specific events to fire.
* **Implementation:** Achievements override `EnableInternal()` to call `_eventBus.Register(this);` and `DisableInternal()` to call `_eventBus.Unregister(this);`.
* **Usage:** They use the `[OnEvent]` attribute to listen for events like `EnteredFinishedStateEvent` (when a building finishes construction), `HazardousWeatherEndedEvent` (surviving a drought/badtide), or `BeaverBornEvent`.

### 2. Continuous Tracking (`ITickableSingleton`)
For achievements that cannot rely on a single event (e.g., maintaining a certain average wellbeing or reaching a specific power capacity), the class implements `ITickableSingleton`.
* **Example:** `ReachMaxAverageWellbeingAchievement` implements `Tick()` to constantly check if `_wellbeingService.AverageGlobalWellbeing >= _wellbeingLimitService.MaxBeaverWellbeing`. If true, it calls `Unlock()`.

### 3. Save/Load Persistence (`ISaveableSingleton` / `ILoadableSingleton`)
If an achievement needs to track progress across multiple play sessions (like planting 10,000 trees or keeping a badtide streak alive), it uses Timberborn's persistence system.
* **Example:** `BadtideStreakAchievement` saves an integer `_streakCount` using a `SingletonKey` and a `PropertyKey<int>` so the streak isn't lost when the player quits the game.

### 4. Component Decorators for Specific Tracking
Sometimes, you only want to track a very specific object (like Dynamite) without listening to every single block placement in the game.
* **Pattern:** The `AchievementsConfigurator` uses a `TemplateModule.Builder` to add specific tracking components to prefabs during instantiation. 
* **Example:** `builder.AddDecorator<Dynamite, PlaceDynamiteAtBottomTracker>();` automatically attaches the tracker component to anything that has the `Dynamite` component.

---

## How to Add Custom Achievements

To add a custom achievement to the game, you must create a class that inherits from `Achievement` (from `Timberborn.AchievementSystem`) and register it via your mod's configurator.

### 1. Create the Achievement Class
```csharp
using Timberborn.AchievementSystem;
using Timberborn.SingletonSystem;
using Timberborn.Beavers;

public class MyCustomModAchievement : Achievement
{
    private readonly EventBus _eventBus;

    // The unique ID matching your localization / Steam backend
    public override string Id => "MY_CUSTOM_ACHIEVEMENT_ID";

    public MyCustomModAchievement(EventBus eventBus)
    {
        _eventBus = eventBus;
    }

    // 1. Hook into the EventBus when the achievement is tracking
    protected override void EnableInternal()
    {
        _eventBus.Register(this);
    }

    // 2. Unhook when disabled or already unlocked
    protected override void DisableInternal()
    {
        _eventBus.Unregister(this);
    }

    // 3. Listen for a specific event
    [OnEvent]
    public void OnBeaverBorn(BeaverBornEvent beaverBornEvent)
    {
        // Add your custom logic here
        if (/* some custom condition */)
        {
            Unlock(); // Tells the AchievementSystem to trigger the unlock
        }
    }
}
```

### 2. Register it in your Configurator
You must bind your custom achievement into the game's `Achievement` collection using `MultiBind`.

```csharp
using Bindito.Core;
using Timberborn.AchievementSystem;

[Context("Game")]
public class MyModAchievementsConfigurator : Configurator
{
    protected override void Configure()
    {
        // This injects your custom achievement into the global list of tracked achievements
        MultiBind<Achievement>().To<MyCustomModAchievement>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Steam Integration is Separate:** This DLL only handles the logical *unlocking* condition within the simulation. The actual communication with Steam's API is handled by a separate module (likely `Timberborn.SteamAchievementSystem`). If you are adding custom achievements, calling `Unlock()` will register it in the game's internal tracking, but you would need external backend setup for it to show up on Steam.
* **Base Class Requirement:** To compile classes like `BuildAchievement` or `CycleSurvivalAchievement` from this file, your mod project requires a reference to `Timberborn.AchievementSystem.dll`, as that is where the base `Achievement` class lives.
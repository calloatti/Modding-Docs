# Timberborn.ActivatorSystem

## Overview
The `Timberborn.ActivatorSystem` module provides a framework for entities that trigger a specific action after a predetermined amount of in-game time (cycles and days) has passed. It is primarily used for delayed-action objects like timed explosives or environmental hazards that activate mid-game. 

This DLL handles the time-tracking, saving/loading the progress, and displaying visual warnings (status icons and particles) as the activation time approaches.

---

## Key Components

### 1. `IActivableComponent` (The Target Interface)
This is the single interface your custom mod scripts need to implement if you want them to be triggered by this system.
* **Methods:** Requires `Activate()` and `Deactivate()`.
* **Purpose:** The activator system doesn't know *what* your block does (explode, spawn water, kill crops); it just knows it needs to call `Activate()` when the timer expires.

### 2. `TimedComponentActivator` (The Core Logic)
This component does the heavy lifting for time tracking. It implements `TickableComponent` to continuously check the time, and `IPersistentEntity` to save and load its countdown state.
* **Mechanics:** It waits until `_gameCycleService.Cycle >= CyclesUntilCountdownActivation`. Once the target cycle is reached, it begins tracking `DaysPassedWithHours` against `DaysUntilActivation`. 
* **Trigger:** When `IsPastActivationTime` becomes true, it grabs the attached `IActivableComponent` and calls `.Activate()`.

### 3. Visual & UI Feedback
The system includes built-in ways to warn the player that a component is about to activate:
* **`ActivationWarningStatus`:** Displays a status icon floating above the entity when it is close to activating. It hooks into the `StatusSubject` system and uses `StatusWarningType.Short` when the activator has 3 or fewer days left.
* **`ActivationProgressParticles`:** A particle controller that scales emission rates (`Mathf.Lerp` between `MinEmission` and `MaxEmission`) based on how close the activator is to firing (`_timedComponentActivator.ActivationProgress`).

---

## How and When to Use This in a Mod

If you want to create a building or object that does nothing when built, but triggers an effect X days later, you should rely entirely on this system rather than writing your own timer.

### 1. Create your Custom Behavior
Implement `IActivableComponent` on your custom MonoBehavior/BaseComponent.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.ActivatorSystem;

public class MyDelayedSpawnComponent : BaseComponent, IActivableComponent
{
    public void Deactivate()
    {
        // Called when the object is built, before the timer finishes.
        // Keep your object dormant here.
    }

    public void Activate()
    {
        // Called the exact moment the TimedComponentActivator timer hits 0.
        // Trigger your explosion, spawn your beavers, release water, etc.
    }
}
```

### 2. Configure the JSON Spec
Because `ActivatorSystemConfigurator` uses the Decorator pattern (`builder.AddDecorator<TimedComponentActivatorSpec, TimedComponentActivator>()`), you **do not** need to add `TimedComponentActivator` to your prefab manually.

Instead, just add the `TimedComponentActivatorSpec` to your object's JSON template. Timberborn will automatically attach and wire up the activator logic when the building is placed.

```json
{
  "Components": {
    "TimedComponentActivatorSpec": {
      "CyclesUntilCountdownActivation": 2,
      "DaysUntilActivation": 5.0,
      "IsOptionallyActivable": false
    },
    "MyDelayedSpawnComponent": {}
  }
}
```

---

## Modding Insights & Limitations

* **Single Target:** The `TimedComponentActivator` simply calls `GetComponent<IActivableComponent>()` in its `Awake()` method. This means **you can only have one `IActivableComponent` per GameObject**. If your entity needs to do multiple things upon activation, your single `IActivableComponent` will need to coordinate those actions.
* **Map Editor Integration:** The component is designed to be fully compatible with the Map Editor. The timer does not tick down while in the map editor (`!_mapEditorMode.IsMapEditor`), and the settings are duplicable via the `IDuplicable` interface.
* **Optionally Activable:** If `IsOptionallyActivable` is set to true in the spec, the timer will *not* start automatically. You will need to manually call `EnableActivator()` on the `TimedComponentActivator` to begin the countdown.
# Timberborn.BotBehavior

## Overview
The `Timberborn.BotBehavior` module defines the artificial intelligence structure and priority queue for mechanical citizens (Bots). While it shares underlying framework components with standard organic beavers (like the `BehaviorManager`), this module specifically configures the executors, root behaviors, and need-evaluation logic tailored to the unique requirements of bots (e.g., the lack of a mandatory sleep cycle).

---

## Key Components

### 1. `BotBehaviorConfigurator`
This configurator is responsible for assembling the bot's "brain" by adding decorators to the `BotSpec` template. 
* **Executors**: It registers discrete low-level actions the bot can perform, such as `WorkExecutor`, `ProduceExecutor`, `BuildExecutor`, `DemolishExecutor`, and `PlantExecutor`.
* **Behaviors**: It registers high-level state nodes, such as `CarryRootBehavior` and `WorkerRootBehavior`. 

### 2. `BotBehaviorInitializer`
Attached to every bot, this component runs during `Awake()` to inject the registered behaviors into the bot's `BehaviorManager`. The order in which it adds root behaviors strictly defines the bot's AI priority stack.

#### The Bot Priority Stack
When the `BehaviorManager` evaluates what a bot should do, it checks these root behaviors in this exact order:
1.  **`CharacterControlRootBehavior`**: Direct player orders (e.g., forced movement).
2.  **`DeadRootBehavior`**: Evaluates if the bot is dead.
3.  **`CarryRootBehavior`**: Handles immediate hauling/carrying tasks.
4.  **`DieRootBehavior`**: Handles the transition of dying.
5.  **`CriticalNeederRootBehavior`**: Forces the bot to fulfill a critical need (e.g., running out of fuel/power).
6.  **`StrandedRootBehavior`**: Evaluates if the bot is stuck without pathing.
7.  **`NeederRootBehavior`**: Fulfills non-critical needs below the warning threshold.
8.  **`WorkerRootBehavior`**: Executes standard workplace duties.
9.  **`WanderRootBehavior`**: The fallback state if absolutely no other work or need requires attention.

### 3. `BotNeedBehaviorPicker`
This component acts as the decision engine for bot needs, implementing the `INeedBehaviorPicker` interface. 
* **Evaluation Logic**: It relies heavily on `NeedFilter.NeedIsInCriticalState()` and `NeedFilter.NeedIsBelowWarningThreshold()` to decide if a bot should stop working to go refuel or repair.
* **District Dependency**: To find a place to fulfill its needs, it delegates the search to the `DistrictNeedBehaviorService` via `_citizen.AssignedDistrict`.
* **Persistence**: It tracks needs that are currently being addressed in a `_needsBeingCriticallySatisfied` hash set. This state is serialized and saved to the save file via `IPersistentEntity` to prevent bots from forgetting what they were doing upon loading a game.

---

## How to Use This in a Mod

### Adding Custom Behaviors to Bots
If your mod introduces a new custom behavior that should apply *only* to bots (and not organic beavers), you must target the `BotSpec` template in your custom configurator.

```csharp
using Bindito.Core;
using Timberborn.TemplateInstantiation;
using Timberborn.Bots;

[Context("Game")]
internal class MyCustomBotBehaviorConfigurator : Configurator
{
    protected override void Configure()
    {
        MultiBind<TemplateModule>().ToProvider(ProvideTemplateModule).AsSingleton();
    }

    private static TemplateModule ProvideTemplateModule()
    {
        TemplateModule.Builder builder = new TemplateModule.Builder();
        // Target BotSpec to ensure this only applies to mechanical citizens
        builder.AddDecorator<BotSpec, MyCustomBotOverheatBehavior>();
        return builder.Build();
    }
}
```
*Note: Because `BotBehaviorInitializer` hardcodes the registration of vanilla root behaviors, your custom behavior will need to register itself with the `BehaviorManager` during its own `Start()` phase, or you will need to patch the initializer.*

---

## Modding Insights & Limitations

* **No "Essential" Need**: Unlike organic beavers (which strictly require sleep via an `EssentialNeedBehavior`), bots do not have a mandatory day/night essential cycle built into their behavior picker. Their routine is entirely dictated by reaching warning or critical thresholds on their needs.
* **Hardcoded District Need Fulfillment**: The `BotNeedBehaviorPicker` explicitly requires the bot to be assigned to a district to find a need-fulfilling action (`if (_citizen.HasAssignedDistrict)`). If a bot somehow becomes unassigned from a district, `GetBestNonEssentialAction` will return a default/null action, meaning the bot will be unable to find fuel or maintenance stations.
* **Hardcoded Initialization Order**: The `BotBehaviorInitializer` explicitly instantiates the priority stack using sequential `component.AddRootBehavior()` calls. Modders cannot easily slip a new behavior exactly between `CarryRootBehavior` and `DieRootBehavior` without using Harmony to prefix or postfix the `InitializeBehaviors` method.
# Timberborn.BeaverBehavior

## Overview
The `Timberborn.BeaverBehavior` module governs the foundational behavioral framework for beavers (both adults and children) within Timberborn. It sets up the logic required to evaluate, prioritize, and execute various actions, such as sleeping, working, wandering, and fulfilling needs. This is managed by initializing a structured hierarchy of "Root Behaviors" and specific "Executors" that translate high-level goals into low-level game engine commands (like walking or playing animations).

For modders, this module reveals the "brain" of the beaver. Understanding how `BeaverBehaviorInitializer` and `BeaverNeedBehaviorPicker` prioritize tasks is crucial for creating custom needs, jobs, or behaviors that integrate seamlessly with the vanilla AI.

---

## Key Components

### 1. `BeaverBehaviorConfigurator` (The AI Assembler)
This class registers all the fundamental behaviors and executors to the game's dependency injection system via `TemplateModule.Builder`.
* **Executors**: These are the discrete actions a beaver can perform. Examples include `WalkToPositionExecutor`, `WaitExecutor`, `ProduceExecutor` (Adult only), and `BuildExecutor` (Adult only).
* **Root Behaviors**: These are the high-level states a beaver can exist in. Examples include `SleepNeedBehavior`, `CarryRootBehavior` (Adult only), `WorkerRootBehavior` (Adult only), and `WanderRootBehavior`.

### 2. `BeaverBehaviorInitializer`
This component is attached to every beaver and runs during `Awake()`. It is responsible for taking the behaviors registered by the configurator and actually adding them to the beaver's `BehaviorManager`.
* **Adult vs. Child Logic**: It explicitly checks if the beaver is an adult (`!GetComponent<Child>()`). Based on this check, it assigns adult-specific behaviors (like `CarryRootBehavior` and `WorkerRootBehavior`) or child-specific behaviors (`ChildRootBehavior`).
* **Essential Needs**: It specifically links `SleepNeedBehavior` as the core "Essential Need" via `BeaverNeedBehaviorPicker.InitializeEssentialNeedBehavior()`.

### 3. `BeaverNeedBehaviorPicker` (The Decision Engine)
This is the core decision-making component for satisfying a beaver's needs. It calculates the optimal action based on time of day, distance, and current need levels.
* **Critical Needs Evaluation**: It contains methods like `GetBestNeedBehaviorAffectingNeedsInCriticalState()` which prioritize actions that resolve needs currently in a critical state (e.g., dying of thirst).
* **Time Management**: The picker heavily relies on the `IDayNightCycle` to calculate how much time is left before dawn (`HoursToNextStartOf(TimeOfDay.Daytime)`).
* **The "Essential Action" (Sleep)**: It calculates if it is time for the "essential action" (sleep) by comparing the points gained from sleeping against the points from the "best non-essential action" (like drinking or relaxing). If there isn't enough time left in the night to do a non-essential action and still get a full night's sleep, it will prioritize sleep (`hoursToDawn < fullDurationOfEssentialActionInHours * 1.2f`).
* **District Context**: For non-essential actions, it delegates the search to the `DistrictNeedBehaviorService` of the district the citizen is assigned to (`_citizen.AssignedDistrict.GetComponent<DistrictNeedBehaviorService>().PickBestAction(...)`).
* **Persistence**: It saves and loads the list of needs currently being "critically satisfied" to ensure continuity upon reloading a save file.

---

## How to Use This in a Mod

### Understanding the Action Hierarchy
If you are adding a new building that satisfies a need (e.g., a "Coffee Shop" that restores energy), you do not need to interact directly with this module to make beavers use it. The `BeaverNeedBehaviorPicker` automatically queries the `DistrictNeedBehaviorService` for the best action, so as long as your building correctly implements the standard Need System components (like `NeedBehavior` and `Effect`), the vanilla AI will evaluate and select it appropriately.

### Custom Behaviors (Advanced)
If you want to add a completely new *Root Behavior* (e.g., a "Panic" state when a specific event happens), you would:
1.  Create your custom `Behavior` class.
2.  Use a custom configurator to inject it into the `TemplateModule.Builder` for the `BeaverSpec`, similar to how `BeaverBehaviorConfigurator` works.
3.  Ensure your custom behavior yields control back to the `BehaviorManager` appropriately so the beaver doesn't get permanently stuck in your custom state.

---

## Modding Insights & Limitations

* **Singleton Essential Behavior**: The `BeaverNeedBehaviorPicker` strictly enforces that there can be only *one* `EssentialNeedBehavior`. Attempting to initialize a second essential behavior will throw an `InvalidOperationException` ("There can be only one essential behavior..."). By default, this is hardcoded to `SleepNeedBehavior` in the `BeaverBehaviorInitializer`. You cannot easily add a second "mandatory" night-time action.
* **Adult vs. Child hardcoding**: The distinction between adult and child capabilities (carrying, working, building) is hardcoded into `BeaverBehaviorInitializer` by checking for the `Child` component. Modders cannot easily create a "teenager" phase that can carry but not build without overriding or heavily patching this initialization logic.
* **Save Data Stability**: `BeaverNeedBehaviorPicker` implements `IPersistentEntity` and saves a `ListKey<string>` called `"NeedsBeingCriticallySatisfied"`. If your mod removes a need type from the game, you must handle the scenario where a save file tries to load a critically satisfied need ID that no longer exists, though standard Unity/Timberborn deserialization usually handles missing string IDs gracefully.
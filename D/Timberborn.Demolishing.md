# Timberborn.Demolishing

## Overview
The `Timberborn.Demolishing` module manages the system for marking and removing buildings and structures via worker beavers. It handles the "mark for demolition" state, job prioritization for builders, worker AI behaviors for reaching and dismantling targets, and rewards for deconstruction.

---

## Key Components

### 1. The Demolishable State (`Demolishable`)
This is the core component attached to entities that can be demolished by workers.
* **Marking Logic**: Buildings are marked for demolition, which enables a `DemolishJob` and triggers events like `DemolishableMarkedEvent`.
* **Progress Tracking**: It tracks `DemolishTimeLeft` based on a spec value and provides a `DemolishingProgress` float (0 to 1).
* **Persistence**: Saves and loads whether an object is marked and how much demolition time remains.
* **Overridable Interaction**: If a `BlockObject` becomes "overridable" (e.g., resources on top are cleared), the `Demolishable` component automatically deletes the entity.

### 2. Builder AI & Behaviors
This module integrates with the worker system to dispatch beavers to dismantling tasks.
* **`Demolisher`**: A component for workers that tracks a `ReservedDemolishable`. It handles reserving the target structure and ensures only one beaver works on a specific demolition at a time.
* **`DemolishBehavior`**: The high-level AI decision tree. It checks if a reservation exists, ensures the target can still be demolished, and launches the pathfinding/execution logic.
* **`DemolishExecutor`**: The actual work task. It plays the "Building" animation, ticks down the demolition time on the target, and deletes the entity once work is complete.

### 3. Reachability & Navigation
* **`ReachableDemolishable`**: Determines if a marked building is accessible via the road network. It checks if the object is within the "road spill" of its district.
* **`AccessibleDemolishableReacher`**: A specialized reacher for buildings that must be demolished from above (using `DemolishableFromTopSpec`). It forces the beaver to look toward the center of the building while working.

### 4. Visuals and Rewards
* **`DemolishableParticleController`**: Manages visual feedback by showing/hiding particles based on the template being dismantled.
* **`DemolishableScienceReward`**: If configured in the `DemolishableScienceRewardSpec`, completing a demolition adds science points to the player's total.
* **`DemolishableStatusIconOffsetter`**: Manages the positioning of the "marked for demolition" status icon, calculating vertical offsets so icons don't clip through buildings.

---

## How to Use This in a Mod

### Adding Demolition to a Custom Building
To allow builders to dismantle your building, you must add the `DemolishableSpec` and its associated decorators in your building's template.

```json
{
  "DemolishableSpec": {
    "DemolishTimeInHours": 0.5,
    "ShowDemolishButtonInEntityPanel": true
  },
  "DemolishableScienceRewardSpec": {
    "SciencePoints": 5
  }
}
```

### Scripting with Demolish Events
You can react to players marking or unmarking objects to trigger custom logic.

```csharp
[OnEvent]
public void OnMarked(DemolishableMarkedEvent @event) {
    Debug.Log($"Building {@event.Demolishable.name} is now marked for destruction.");
}
```

---

## Modding Insights & Limitations

* **Forced Demolition**: The `Demolisher` component supports a `ReserveWithForcedDemolition` state. This allows beavers to demolish objects even if they aren't explicitly "Marked" by the player, which is useful for specialized AI tools.
* **Unfinished Model Handling**: Structures using `DemolishableFromTopSpec` automatically include `HighBlockObjectAccessesAdder`, implying they require beavers to stand on higher adjacent blocks (like platforms) to reach the target.
* **Animation Lock**: The `DemolishExecutor` is hardcoded to use the `"Building"` animation. Custom demolition animations per-building are not natively supported through this specific component.

---

## Related dlls
* **Timberborn.BuilderHubSystem**: Provides the `IBuilderJobProvider` interface for the `DemolishJobProvider`.
* **Timberborn.BlockSystem**: Essential for `BlockObject` and coordinate management during demolition.
* **Timberborn.PrioritySystem**: Used to organize demolition jobs by player-set priority levels.
* **Timberborn.ScienceSystem**: Required for handling science rewards upon demolition completion.
* **Timberborn.ReservableSystem**: Used to manage entity locking so only one beaver works on a building at a time.

Would you like to examine the **Timberborn.BuilderHubSystem** next to see how builders prioritize demolition versus construction?
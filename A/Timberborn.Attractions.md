# Timberborn.Attractions

## Overview
The `Timberborn.Attractions` module governs the logic and behavior of leisure and wellbeing buildings where beavers go to satisfy specific needs (e.g., Campfires, Shrines, Rooftop Terraces, Carousels). 

It integrates with the `NeedBehaviorSystem` to guide beavers to these locations, applies the appropriate `ContinuousEffect` to the beaver while they are inside, and tracks usage statistics (like the hourly `AttractionLoadRate`).

---

## Key Components

### 1. `Attraction` (The Core Definition)
This component acts as the primary identifier that a building is an attraction.
* **Effects:** During `Awake()`, it reads the `AttractionSpec` to gather an array of `ContinuousEffectSpec` objects, which define what needs are satisfied by visiting this building (e.g., "Awe", "SocialLife").
* **Efficiency:** When applying these effects to a beaver (`GetEfficiencyAdjustedEffects`), the `Attraction` class checks all attached `IBuildingEfficiencyProvider` components and multiplies the `PointsPerHour` by the total building efficiency. This means a lack of power or workers can slow down how fast a beaver fulfills their needs.

### 2. `AttractionNeedBehavior` (The AI Controller)
This class bridges the gap between the `Attraction` building and the individual beaver AI (`BehaviorAgent`).
* **Pathfinding:** Implements `ActionPosition()` to tell the `NeedManager` where the beaver must walk to enter the attraction.
* **Execution (`Decide`):** Once the beaver reaches the door, it uses `WalkInsideExecutor` to move the beaver into the building. It then triggers the `ApplyEffectExecutor` with a specific time duration to raise the beaver's need levels.
* **The "First Visit" Rule:** To ensure a beaver actually spends time inside an attraction (rather than stepping in and immediately stepping out because their need ticked up by 0.01%), the code uses `AttractionAttender.FirstVisit`. On their first entry, the beaver is forced to stay for a minimum of `0.5f` hours before the AI re-evaluates.

### 3. `GoodConsumingAttraction`
For attractions that require physical goods to operate (like Mud Baths requiring Dirt and Water, or Carousels requiring Power), this component manages the consumption state.
* **Logic:** It listens to `EntererAdded` and `EntererRemoved` events on the building's `Enterable` component. 
* **Optimization:** It calls `PauseConsumption()` on the `GoodConsumingToggle` when empty, and `ResumeConsumption()` when a beaver enters. This ensures that attractions do not burn through resources/power while no one is using them.

### 4. `AttractionLoadRate`
This component generates the data used for the "Load Rate" bar chart in the building's UI panel.
* **Tracking:** It records `_maxLoad` and `_actualLoad` arrays representing the 24 hours in a day.
* **Sampling:** Every tick, it adds the building's total `Capacity` to the max load, and the `NumberOfEnterersInside` to the actual load. The resulting UI graph simply divides actual by max.

### 5. `AttractionFire`
A specialized visual controller for attractions like the Campfire. It automatically enables/disables a `Fire` component and a woodstack GameObject based on the `IDayNightCycle`, making sure the fire is only lit at night.

---

## How to Create a Custom Attraction Mod

To create a new attraction (e.g., a "Cinema"), you do not need to write C# code. You only need to construct a Unity Prefab with the correct Vanilla components and specify them in the JSON template.

### The JSON Template Structure
Your modded building's JSON must include the `AttractionSpec` and the `Enterable` components:

```json
{
  "Components": {
    "BlockObject": {
      "Coordinates": [ 0, 0, 0 ]
    },
    "EnterableSpec": {
      "CapacityFinished": 10,
      "CapacityUnfinished": 0
    },
    "AttractionSpec": {
      "Effects": [
        {
          "NeedId": "Awe",
          "PointsPerHour": 50.0,
          "SatisfyToMaxValue": true
        },
        {
          "NeedId": "SocialLife",
          "PointsPerHour": 20.0,
          "SatisfyToMaxValue": false
        }
      ]
    },
    "BuildingAccessible": {}
  }
}
```
*Note: Because `AttractionsConfigurator` automatically attaches the AI logic (`builder.AddDecorator<Attraction, AttractionNeedBehavior>()`), adding `AttractionSpec` to the JSON is all that is required to make the beavers use the building.*

---

## Modding Insights & Limitations

* **Need IDs:** The string used in `"NeedId"` (e.g., `"Awe"`) must correspond exactly to an existing need defined by a `NeedSpec` loaded into the game. If you want to create a brand new custom need (e.g., "Entertainment"), you must add that `NeedSpec` in a separate JSON file before your attraction can fulfill it.
* **Continuous Effects:** Notice the `SatisfyToMaxValue` boolean in the `ContinuousEffectSpec`. If set to `true`, the beaver will stay inside the attraction until their need bar is 100% full. If `false`, the beaver will leave as soon as the AI finds a more pressing task, even if the bar is only at 50%.
* **Efficiency Multiplying:** Because `GetEfficiency()` multiplies all attached `IBuildingEfficiencyProvider` components together, if an attraction requires an employee to operate and no employee is present (efficiency = 0), the `PointsPerHour` will multiply to 0, and the beaver will sit inside the attraction gaining no need fulfillment.
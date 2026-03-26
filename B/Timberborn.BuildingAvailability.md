# Timberborn.BuildingAvailability

## Overview
The `Timberborn.BuildingAvailability` module is a small, specialized system that determines whether a specific building tool should be accessible to the player based on the current state of the settlement. Specifically, it manages the logic that disables the placement of advanced structures (like certain elevated pathways or power shafts) until the required understructure foundations have been unlocked or built.

---

## Key Components

### 1. `BuildingAvailabilityValidator`
This is the core logic class that evaluates if a building is ready to be placed by the player.
* **Constraint Checking**: When `IsAvailableForPlacement` is called with a `ComponentSpec`, it checks if the spec possesses an `UnderstructureConstraintSpec`. If it does not, the building is always available.
* **Instantiation Check**: If a constraint exists, it checks `_entityRegistry.WasTemplateInstantiated` to see if *any* of the required understructure templates have ever been built in the current game.
* **Dev Mode / Unbuildable Check**: If the required understructure has *not* been built, it checks if the player is even *capable* of building it. It queries the `PlaceableBlockObjectSpec` of the required templates and ensures they are not marked as `DevModeTool`. If the only required understructures are developer-only, the building remains unavailable.

### 2. `BuildingAvailabilityToolDisabler`
This class implements the `IToolDisabler` interface, integrating the validator into the game's broader `ToolSystem`.
* **Tool Interception**: It intercepts `ITool` instances. If the tool is a `BlockObjectTool` (a standard building placement tool), it runs the `Template` through the `BuildingAvailabilityValidator`. If the validator returns `false`, the tool is disabled in the UI (typically appearing grayed out or unclickable).

### 3. `BuildingAvailabilityConfigurator`
A standard Bindito configurator that operates only in the `Game` context. It binds the validator as a singleton and uses a `MultiBind` to add the `BuildingAvailabilityToolDisabler` to the collection of `IToolDisabler` instances used by the global `ToolSystem`.

---

## How to Use This in a Mod

Because this system relies on the `UnderstructureConstraintSpec` (which belongs to `Timberborn.UnderstructureSystem`), you primarily interact with it via JSON configuration when creating custom buildings.

If you create a modded building that must be placed on top of a specific custom foundation (e.g., a "Sky-Lodge" that requires a "Sky-Pillar"), you add the constraint spec to the Sky-Lodge's JSON:

```json
{
  "UnderstructureConstraintSpec": {
    "UnderstructureTemplateNames": [
      "SkyPillar",
      "ReinforcedSkyPillar"
    ]
  }
}
```

The `BuildingAvailabilityToolDisabler` will automatically grey-out the Sky-Lodge in the build menu until the player has built at least one `SkyPillar` or `ReinforcedSkyPillar`.

---

## Modding Insights & Limitations

* **Entity Registry Dependency**: The validator relies on `_entityRegistry.WasTemplateInstantiated(templateName)`. This method returns true if the entity has *ever* been instantiated in the current save file. It does not check if the required understructure is *currently* active or built on the map. If a player builds the required foundation and then deletes it, the advanced building remains permanently unlocked for that save.
* **Map Editor Exclusion**: The `BuildingAvailabilityConfigurator` explicitly omits the `[Context("MapEditor")]` attribute. This means all building availability constraints are completely ignored when a user is designing a map; all tools are available at all times in the editor.
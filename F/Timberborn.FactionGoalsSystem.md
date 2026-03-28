# Timberborn.FactionGoalsSystem

## Overview
The `Timberborn.FactionGoalsSystem` module is a small, focused system that continuously monitors player progress to determine if a locked faction should become available for future playthroughs.

---

## Key Components

### 1. `FactionGoalsUnlocker`
This is a singleton class that implements `ITickableSingleton`, meaning it executes its logic continuously during the game's update loop.
* **Tick Logic**: Every tick, it iterates through all available `FactionSpec` definitions provided by the `FactionSpecService`.
* **Lock Check**: It skips any faction that is already unlocked by checking `_factionUnlockingService.IsLocked(current)`.
* **Condition Evaluation**: For locked factions, it evaluates `UnlockConditionsAreSatisfied(current)`.
* **Unlocking**: If the conditions are met, it immediately calls `_factionUnlockingService.UnlockFaction(current)`.

### 2. Unlock Conditions
The criteria for unlocking a faction are defined in the `UnlockableFactionSpec`. To satisfy the conditions:
1.  **Prerequisite Faction**: The player's *currently active* faction (`_factionService.Current.Id`) must match the `PrerequisiteFaction` defined in the locked faction's spec. This ensures players must play as a specific faction (e.g., Folktails) to unlock the next one (e.g., Iron Teeth).
2.  **Wellbeing Threshold**: The global settlement wellbeing (`_wellbeingService.AverageGlobalWellbeing`) must meet or exceed the required `AverageWellbeingToUnlock`.

---

## Modding Insights & Limitations

* **Extensibility**: The unlocking criteria are currently hardcoded to just two factors: the active faction ID and the average global wellbeing. If a modder wanted to create a faction that unlocks via a different metric (e.g., hoarding 10,000 logs or surviving 50 cycles), they would need to write a custom unlocker class and bypass this default system.
* **Performance**: Because `FactionGoalsUnlocker` is an `ITickableSingleton`, it runs every single game tick. While the current logic is very lightweight (just checking an array of typically 2 factions), modders injecting custom unlock logic into the tick loop should ensure their condition checks are highly optimized to avoid unnecessary CPU overhead.

---

## Related DLLs
* **Timberborn.GameFactionSystem**: Provides the `FactionService`, `FactionSpecService`, and `FactionUnlockingService` required to read specs and persist the unlocked state.
* **Timberborn.FactionSystem**: Provides the base `FactionSpec` class.
* **Timberborn.Wellbeing**: Supplies the `WellbeingService` used to query the `AverageGlobalWellbeing` metric.
* **Timberborn.TickSystem**: Provides the `ITickableSingleton` interface that drives the execution loop.
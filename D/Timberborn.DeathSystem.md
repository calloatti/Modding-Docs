# Timberborn.DeathSystem

## Overview
The `Timberborn.DeathSystem` module governs the behavioral logic of a character when it is scheduled to die. It primary responsibility is to handle the final actions of a "Mortal" entity, ensuring characters either die in place or move to a public location before expiring.

---

## Key Components

### 1. `DieRootBehavior`
This is a high-priority `RootBehavior` that takes control of a character's AI once the `Mortal` component determines it is time for the character to die.

* **Public vs. Private Death**: The behavior checks `Mortal.ShouldDiePublicly`. 
    * If a public death is required, or if the character is currently outside of a building, it will attempt to find a random destination to walk to before dying.
    * If the character is inside a building and does not need to die publicly, it may expire immediately.
* **Execution Logic**: 
    1.  Checks if `IsTimeToDie` is true.
    2.  If the character hasn't reached its final "death position" yet, it uses a `RandomDestinationPicker` to choose a spot within its district.
    3.  Uses `WalkToPositionExecutor` to move the character to that spot.
    4.  Once at the destination (or if movement fails), it calls `Mortal.DieIfItIsTime()` to finalize the death process.
* **Persistence**: It saves the `_wentToDeathPosition` state. This ensures that if a game is saved and loaded while a beaver is walking to its final resting place, it remembers it has already picked a spot and won't restart the "walk to death" logic indefinitely.

### 2. `DeathSystemConfigurator`
A standard Bindito configurator that registers `DieRootBehavior` as a transient component within the "Game" context.

---

## Modding Insights

### Forcing Death Positions
If you are modding character AI and want to ensure a character dies at a specific graveyard or memorial, you would likely need to Harmony patch `GoToRandomDeathPosition()` to return a specific coordinate instead of a random one from `RandomDestinationPicker`.

### Death Timing
The actual calculation of "when" a beaver dies (old age, hunger, thirst) is handled by the `Mortal` component in the `Timberborn.MortalSystem` module. `DieRootBehavior` simply reacts to the flag set by that system.

---


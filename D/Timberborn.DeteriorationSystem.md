# Timberborn.DeteriorationSystem

## Overview
The `Timberborn.DeteriorationSystem` module manages the mechanical "lifespan" of entities through a deterioration mechanic, primarily used for Golems (Bots). Instead of biological aging, these entities lose "condition" over time until they break down and cease to function.



---

## Key Components

### 1. `Deteriorable`
This is the core component responsible for tracking the gradual decay of an entity.
* **Time Tracking**: It converts the game's `FixedDeltaTimeInHours` into fractional days to subtract from the entity's remaining life.
* **Lifecycle Management**: 
    * It initializes with maximum deterioration (full condition) based on the values in `DeteriorableSpec`.
    * Every simulation tick, it subtracts the elapsed time from the `_currentDeterioration` value.
* **Death Integration**: When `_currentDeterioration` reaches zero, it triggers a public death through the `Mortal` system.
* **Notifications**: It uses a specific localized message (`Bot.DeathMessage`) to inform the player when the entity has broken down.
* **Data Access**: It provides a `DeteriorationProgress` float (0.0 to 1.0) for UI elements to display condition bars.

### 2. `DeteriorableSpec`
A data record used in prefab templates to define specific lifespan parameters.
* **`DeteriorationInDays`**: Defines the total number of game days an entity lasts before breaking down.

### 3. `DeteriorationSystemConfigurator`
A standard Bindito configurator that manages dependency injection and template decoration.
* It binds `Deteriorable` as a transient component.
* It uses a `TemplateModule` decorator to ensure any entity with a `DeteriorableSpec` automatically receives the `Deteriorable` logic.

---

## Data Persistence
The system ensures that the condition of a Bot is maintained across game saves.
* **Save**: Writes the exact `_currentDeterioration` value to the entity's data.
* **Load**: Retrieves the saved value to resume the countdown from the precise moment the game was last saved.

---

## Related dlls
Based on the implementation, this system integrates with the following game modules:
* **Timberborn.TickSystem**: Provides the `TickableComponent` base for per-frame updates.
* **Timberborn.MortalSystem**: Handles the actual destruction of the entity once condition hits zero.
* **Timberborn.TimeSystem**: Provides `IDayNightCycle` for time calculations.
* **Timberborn.Persistence**: Manages the serialization of the deterioration state.
* **Timberborn.Localization**: Used for the "Bot has broken down" player notifications.

Would you like to examine the **Timberborn.MortalSystem** to see how biological death differs from this mechanical breakdown?
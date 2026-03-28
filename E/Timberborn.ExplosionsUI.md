# Timberborn.ExplosionsUI

## Overview
The `Timberborn.ExplosionsUI` module provides the interactive user interface elements for triggering and configuring explosives in the game. It injects specific fragments into the `EntityPanel` when a player selects `Dynamite` or an `UnstableCore`.

---

## Key Components

### 1. `DynamiteFragment`
This fragment is injected into the top section of the Entity Panel when a player selects a `Dynamite` block.
* **Detonation Button**: It provides a button to trigger the dynamite. The button's text and interactivity update dynamically based on the block's state:
    * Unfinished: "CantDetonate" (disabled).
    * Already Triggered: "Armed" (disabled).
    * Finished & Ready: "Detonate" (enabled).
* **Input Processing**: It implements `IInputProcessor`, allowing players to detonate the selected dynamite using a hotkey (bound to `UniqueBuildingActionKey`). 
* **Hidden Delay Logic**: If the player holds down specific hidden hotkeys (`DetonationDelayKey` or `LongDetonationDelayKey`), it triggers the dynamite with a 10 or 20 tick delay instead of detonating instantly.

### 2. `UnstableCoreFragment`
This fragment provides the configuration UI for the `UnstableCore` (the Badwater Rig explosive).
* **Visibility Restrictions**: This UI is completely hidden during normal gameplay. It only becomes visible if the player is in the Map Editor (`_mapEditorMode.IsMapEditor`) or if Developer Mode is enabled (`_devModeManager.Enabled`).
* **Radius Input**: It displays an `IntegerField` allowing the user to manually set the `ExplosionRadius`.
* **Undo Support**: When the value is changed, the logic is wrapped in a `using (_entityChangeRecorderFactory.CreateChangeRecorder(_unstableCore))` block, allowing the player to undo their radius change. The new radius is strictly clamped between `MinExplosionRadius` and `MaxExplosionRadius`.

### 3. `UnstableCoreDebugFragment`
A developer-only fragment injected into the Diagnostic section of the Entity Panel when an `UnstableCore` is selected.
* **Explode Button**: Instantly disables the map-editor block (`_unstableCoreExplosionBlocker.Disable()`) and forces the core to detonate. It also respects the hidden 10/20 tick delay hotkeys.
* **Safe Delete**: Provides a "Delete without exploding" button that guarantees the core is removed without destroying the surrounding terrain.

### 4. `DynamiteDescriber`
An implementation of `IEntityDescriber` that adds textual information to the Dynamite's tooltip.
* It uses the `UnitFormatter.FormatDistance` utility to append the formatted `Depth` value to the tooltip (e.g., "Explosion depth: 2m").

---

## Modding Insights & Limitations

* **Hardcoded Hotkeys**: The hotkey strings used to trigger delayed explosions (`"DetonationDelay"` and `"LongDetonationDelay"`) and the debug detonation (`"DetonateUnstableCore"`) are hardcoded strings. 
* **Input Processor Lifecycle**: Both interactive fragments (`DynamiteFragment` and `UnstableCoreDebugFragment`) properly register and unregister themselves with the `InputService` inside their `ShowFragment` and `ClearFragment` methods. This ensures hotkeys only work when the specific building is actively selected by the player.

---

## Related DLLs

* **Timberborn.Explosions**: The core logic backend providing the `Dynamite` and `UnstableCore` components.
* **Timberborn.EntityPanelSystem**: The UI framework into which these fragments are injected via `EntityPanelModuleProvider`.
* **Timberborn.InputSystem**: Provides the `InputService` and `IInputProcessor` interface used for hotkey bindings.
* **Timberborn.EntityUndoSystem**: Provides the `EntityChangeRecorderFactory` used to log user edits to the Unstable Core radius.
* **Timberborn.Debugging**: Supplies the `DevModeManager` used to gate the visibility of the Unstable Core UI.
# Timberborn.DuplicationSystemUI

## Overview
The `Timberborn.DuplicationSystemUI` module provides the user interface and input handling for the game's copy-paste and duplication mechanics. It allows players to either duplicate an object's settings (like warehouse limits) to another object or entirely duplicate a building structure to place a new copy in the world.

---

## Key Components

### 1. UI Fragments
These components are injected into the Entity Panel when a valid object is selected.
* **`DuplicateSettingsFragment`**: Displays a button (bound to `"DuplicateSettings"`) that activates the `DuplicateSettingsTool` using the currently selected entity as the source. It only appears if `CanDuplicateSettings` returns true.
* **`DuplicateObjectFragment`**: Displays a button (bound to `"DuplicateObject"`) that finds the construction tool associated with the selected building and activates it, effectively letting the player build another copy of the same structure.

### 2. Interaction Handlers
* **`DuplicateSettingsTool`**: This is an interactive tool (`ITool`) that replaces the default cursor when the player initiates a settings copy.
    * **Highlighting**: It locks a primary highlight color onto the source building (`SourceColor`) and uses a rolling highlight (`TargetColor`) on whatever building the mouse hovers over.
    * **Execution**: When the player clicks on a valid target building, it calls `_duplicator.Duplicate(_source, target)`.
    * **Undo Support**: It wraps the duplication action inside an `EntityChangeRecorderFactory.CreateChangeRecorder`, allowing the player to undo accidental setting overwrites.
* **`DuplicationInputProcessor`**: A global input listener that enables "eyedropper" functionality. If the player has no object selected and presses the hotkeys for duplicating settings or objects while hovering over a building in the world, it instantly triggers the respective tool.

### 3. Validation Logic (`DuplicationValidator`)
Centralized logic to determine if an entity can be copied.
* **Settings Validation**: `CanDuplicateSettings` checks if the entity possesses *any* component that implements the `IDuplicable` interface and returns true for `IsDuplicable`.
* **Object Validation**: `CanDuplicateObject` checks two conditions:
    1. The entity must *not* have the `DuplicationBlocker` component attached.
    2. The system must be able to find an active construction tool for that entity via the `IToolFinder` collection.

---

## Modding Insights & Limitations

* **Fragment Injection**: Both the settings and object duplication buttons are injected into the `LeftHeaderFragment` of the Entity Panel with sorting weights of `10` and `20` respectively. This places them consistently at the top left of the selection window.
* **Color Customization**: The highlight colors used by the settings tool are not hardcoded; they are defined in JSON via the `DuplicationSystemColorsSpec`.
* **No Multi-Select Paste**: The `DuplicateSettingsTool` is designed for single-click pasting. The player must click individually on every target building to apply the copied settings. It does not natively support drag-selecting an area to paste settings to multiple buildings at once.

---

## Related dlls
* **Timberborn.DuplicationSystem**: The core data logic and interfaces (`IDuplicable`, `Duplicator`, `DuplicationBlocker`).
* **Timberborn.EntityPanelSystem**: The framework into which the UI fragments are injected.
* **Timberborn.ToolSystem**: Manages the activation and cursor states of the `DuplicateSettingsTool`.
* **Timberborn.SelectionSystem**: Provides the `Highlighter` and `RollingHighlighter` services.
* **Timberborn.EntityUndoSystem**: Provides the `EntityChangeRecorderFactory` to log the copy-paste action.
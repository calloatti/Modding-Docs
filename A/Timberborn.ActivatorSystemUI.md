# Timberborn.ActivatorSystemUI

## Overview
The `Timberborn.ActivatorSystemUI` module handles the user interface components for the `ActivatorSystem`. It integrates with Timberborn's UI Toolkit-based `EntityPanelSystem` to display progress bars to the player during normal gameplay, and configuration inputs to map creators in the Map Editor (or developers using Dev Mode).

This DLL is an excellent reference for modders looking to understand how Timberborn splits UI logic between standard gameplay viewing and Map Editor configuration.

---

## Key Components

### 1. `TimedComponentActivatorFragment` (Player UI)
This is the `IEntityPanelFragment` that standard players see when clicking on a timed entity. 
* **Visibility:** It explicitly hides itself in the Map Editor (`!_mapEditorMode.IsMapEditor`) and disappears once the activator has passed its activation time (`_timedComponentActivator.IsPastActivationTime`).
* **Progress Bar:** Uses the `TimedActivatorProgressBar` to show how close the component is to triggering. If the underlying spec flags it as a `IsHazardousActivator`, the UI applies the `progress-bar--red` USS class to make the bar red.

### 2. `TimedComponentActivatorSettingsFragment` (Map Editor / Dev UI)
This fragment allows users to configure the timer settings of an entity.
* **Visibility:** Only visible if the Map Editor is active (`_mapEditorMode.IsMapEditor`) or if Dev Mode is enabled (`_devModeManager.Enabled`).
* **Controls:** Provides a toggle to enable/disable the activator (if `IsOptional` is true), and float fields to set the `CyclesUntilCountdownActivation` and `DaysUntilActivation`.

### 3. `ActivatorSystemUIConfigurator`
Registers the UI components into the dependency injection container.
* **Panel Module:** Uses a `TemplateModule.Builder` via `EntityPanelModuleProvider` to inject the two fragments into the middle of the entity panel. The standard fragment is given priority `10`, and the settings fragment is given priority `11`.

---

## Modding Insights & Patterns

### 1. Undo/Redo Integration for Map Editors
If your mod adds configuration fields to the Map Editor, you must integrate with Timberborn's Undo/Redo system so players can press `Ctrl+Z` to revert their changes. This DLL demonstrates exactly how to do that using `EntityChangeRecorderFactory`.

**Usage Pattern:**
Whenever a UI element's callback changes a value on the underlying component, wrap the change in a `using` block with the change recorder:

```csharp
private void SetDaysUntilActivation(float value)
{
    // 1. Create the recorder and target the specific entity component
    using (_entityChangeRecorderFactory.CreateChangeRecorder((BaseComponent)(object)_timedComponentActivator))
    {
        // 2. Apply the change
        _timedComponentActivator.SetDaysUntilActivation(value);
    }
    // 3. The 'using' block automatically finalizes the record for the Undo system
}
```

### 2. UI Toolkit (UIElements) Usage
Timberborn UI is built using Unity's UI Toolkit. 
* To load a UI layout from the game's assets, the code uses `_visualElementLoader.LoadVisualElement("Path/To/UXML")`.
* To find specific elements inside that layout, it uses `root.Q<VisualElementType>("ElementName")` (e.g., `_root.Q<Toggle>("IsEnabledToggle")`).
* To bind callbacks to input fields, it uses `.RegisterValueChangedCallback(...)` or the helper `TextFields.InitializeFloatField`.

### 3. Separation of Concerns
Notice how this DLL contains absolutely no logic about *how* the activator ticks down. It simply reads values from the `TimedComponentActivator` (from `Timberborn.ActivatorSystem.dll`) and updates `VisualElement` properties. As a best practice, your UI logic and simulation logic should always be in separate classes, and ideally separate assemblies.
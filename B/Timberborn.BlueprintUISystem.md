# Timberborn.BlueprintUISystem

## Overview
The `Timberborn.BlueprintUISystem` is a small, developer-focused UI module. It provides diagnostic user interface elements—specifically the `BlueprintDebugFragment`—that allow modders and developers to inspect the raw, deserialized JSON blueprint data of any selected entity directly from within the game.


---

## Key Components

### 1. `BlueprintDebugFragment`
This class implements `IEntityPanelFragment` to integrate directly into the game's standard entity selection panel (the window that appears when you click on a building or beaver).
* **Entity Linkage**: When an entity is selected, `ShowFragment(BaseComponent entity)` is called. The fragment finds the entity's blueprint by querying `entity.AllComponents` for the first object that inherits from `ComponentSpec`, and then extracts its `Blueprint` property.
* **The Debug Dialog**: It adds a "Show Blueprint" button to the diagnostic UI. Clicking this button uses the `DialogBoxShower` and `VisualElementLoader` to spawn a custom window (`"Common/EntityPanel/BlueprintDebugWindow"`).
* **Data Visualization (Tabs)**: It fetches the raw file data via `BlueprintSourceService.Get(_blueprint)`. The window uses a UI Toolkit `TabView` to display the JSON code. 
    * It always generates a **"Merged"** tab, which displays the final JSON structure after all modifications and partial files are combined using `SerializedObjectReaderWriter`.
    * If the blueprint is composed of multiple JSON parts (e.g., modified by `IBlueprintModifierProvider`), it generates individual tabs (`"Part 1"`, `"Part 2"`, etc.) displaying the raw string content and the source name for each individual modification.
* **Utility**: The dialog explicitly includes a "Copy to clipboard" button, which copies the text of the currently active JSON tab into `GUIUtility.systemCopyBuffer`.

### 2. `BlueprintUISystemConfigurator`
This configurator operates in both the `Game` and `MapEditor` contexts. It binds the `BlueprintDebugFragment` as a singleton and injects it into the `EntityPanelModule`.
* **Diagnostic Registration**: Crucially, it registers the fragment using `builder.AddDiagnosticFragment(_blueprintDebugFragment)`. This categorizes it as a developer/debug tool, ensuring it only appears in the UI when the game's developer mode or diagnostic panels are enabled.

---

## How to Use This in a Mod

You generally do not need to interact with this module via C# code, but it is an **invaluable tool for modders** working with JSON files and the Blueprint System.

### Debugging Custom JSON Blueprints
If you are writing a mod that creates new buildings or utilizes `IBlueprintModifierProvider` to inject new `ComponentSpec` data into existing buildings, you can use this UI to verify your work:
1. Enable Developer Mode in Timberborn.
2. Click on the entity in-game (e.g., your custom building).
3. Find the diagnostic section of the entity panel and click **"Show Blueprint"**.
4. Use the **"Merged"** tab to verify that the game's deserializer correctly combined your custom JSON arrays, objects, and values. This confirms whether your JSON syntax is correct and properly formatted for the game's engine.

---

## Modding Insights & Limitations

* **First-Spec Dependency**: The logic used to retrieve the blueprint is hardcoded to `entity.AllComponents.First((object component) => component is ComponentSpec)`. The system assumes that all `ComponentSpec` objects on a single entity originate from the exact same root `Blueprint`.
* **Read-Only**: This interface is strictly diagnostic and read-only. While it utilizes `TextField` elements for the UI display, it explicitly sets `textField.SetValueWithoutNotify(content)` and provides no save mechanism, meaning you cannot edit an entity's JSON in real-time through this window.
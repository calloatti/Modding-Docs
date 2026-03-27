# Timberborn.DwellingSystemUI

## Overview
The `Timberborn.DwellingSystemUI` module is responsible for displaying information about housing and its residents in the game's UI. It provides the visual components for the Entity Panel when a player selects a house, including detailed views of the beavers living there, as well as the UI rows for the Batch Control window.

---

## Key Components

### 1. Entity Panel Fragments
These components are injected into the Entity Panel when a `Dwelling` is selected.
* **`DwellingUserFragment`**: The primary UI element that displays the residents of a selected dwelling.
    * **Header**: Shows the total occupancy versus capacity (e.g., "Dwellers: 4 / 6").
    * **Dweller Grid**: It dynamically generates a grid of `DwellerView` elements based on the `AdultSlots` and `ChildSlots` of the building.
    * **Resident Data**: For each occupied slot, it displays the beaver's portrait, name, subtitle (profession/status), and their current wellbeing score. Clicking on a resident selects and follows that specific beaver in the world.
* **`DwellingDebugFragment`**: A developer-only diagnostic tool that adds a "Spawn newborn" button to the panel. It allows developers to instantly spawn a child into the selected dwelling, provided there is a free slot.

### 2. Batch Control Integration
* **`DwellingBatchControlRowItemFactory`**: Generates the UI elements for dwellings listed in the Batch Control window. 
* **Row Data**: It creates a simple text label showing the occupancy ratio (`NumberOfDwellers / TotalSlots`).
* **Tooltips**: It registers a localized tooltip that breaks down the occupancy by demographic (e.g., "Adults: 2 / 4", "Children: 1 / 2").

### 3. Tooltips and Descriptions
* **`DwellingDescriber`**: Implements `IEntityDescriber` to add textual information to the standard building tooltip (the box that appears when hovering over the building in the construction menu or the world).
    * **Capacity**: It adds a row stating the maximum inhabitants.
    * **Sleep Effects**: It uses the `EffectDescriber` to list the buffs (like Comfort) that beavers receive when sleeping in this specific type of house.

---

## Modding Insights & Limitations

* **Adult/Child Slot Visuals**: The `DwellerView` component explicitly supports empty slot visuals for adults (`SetAsAdult()`) and children (`SetAsChild()`) using the `CharacterButton` component. This reinforces the rigid demographic split defined in the core `DwellingSystem`.
* **Rebuild on Select**: The `DwellingUserFragment` completely destroys and recreates the `DwellerView` grid every time the building is selected (`ShowFragment` -> `InitializeUserViews`). It then relies on `UpdateFragment` (called every frame) to populate the views with current data.
* **Hardcoded Wellbeing Styling**: The `DwellerView` uses a hardcoded CSS class (`wellbeing--negative`) to visually style the wellbeing counter if the beaver's wellbeing drops below 0. 

---

## Related dlls
* **Timberborn.DwellingSystem**: The core logic backend providing `Dwelling`, `Dweller`, and slot counts.
* **Timberborn.EntityPanelSystem**: The UI framework into which the `DwellingUserFragment` is injected as a `TopFragment`.
* **Timberborn.BatchControl**: The multi-building overview window that utilizes `DwellingBatchControlRowItemFactory`.
* **Timberborn.CharactersUI**: Provides the `CharacterButton` used to render the beaver portraits in the UI.
* **Timberborn.Wellbeing**: Provides the `WellbeingTracker` used to display the resident's current score.
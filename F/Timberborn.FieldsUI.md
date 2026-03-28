# Timberborn.FieldsUI

## Overview
The `Timberborn.FieldsUI` module provides the user interface components for managing agricultural buildings and tools. It enables players to toggle work priorities for farmhouses, access crop planting tools via the bottom bar, and monitor farm status in the batch control window.

---

## Key Components

### 1. Farmhouse Work Priority Toggle
The system provides a standardized UI toggle to switch between planting and harvesting.
* **`FarmHouseToggle`**: A slider-based toggle that allows the player to select either "Planting" (`Fields.Planting`) or "Harvesting" (`Fields.Harvesting`).
* **Priority Actions**: Selecting a side of the toggle calls `PrioritizePlanting()` or `UnprioritizePlanting()` on the `FarmHouse` component.
* **`FarmHouseFragment`**: Integrates the toggle into the Entity Panel when a farmhouse is selected.

### 2. Bottom Bar Integration
* **`FieldsButton`**: Provides the "Fields" category button on the game's bottom construction bar.
* **Dynamic Tool Generation**: It automatically scans all loaded `PlantableSpec` templates. Any template that possesses a `CropSpec` and is marked as usable with current feature toggles is added as a planting tool under the Fields group.
* **Cancel Tool**: It automatically adds a "Cancel Planting" tool to the group using the `PlantingToolButtonFactory`.

### 3. Batch Control
* **`FarmHouseBatchControlRowItemFactory`**: Generates UI rows for the Batch Control overview window.
* **Functionality**: Each row includes the `FarmHouseToggle`, allowing players to change the planting/harvesting priority for multiple farmhouses simultaneously from a single menu.

### 4. Yield and Inventory Status
The module uses decorators to attach additional informational components to the `FarmHouse` building.
* **`YieldStatus`**: Attaches to farmhouses to show potential crop yields.
* **`SimpleOutputInventoryFragmentEnabler`**: Ensures the building's output inventory (where harvested crops are stored) is visible in the Entity Panel.

---

## Modding Insights & Limitations

* **Automatic Tool Population**: Modders do not need to manually register buttons for new crops. As long as a new plant prefab has both `PlantableSpec` and `CropSpec`, the `FieldsButton` logic will automatically find it and create a construction button in the "Fields" group.
* **Hardcoded Icon Classes**: The `FarmHouseToggle` uses hardcoded CSS classes (`farmhouse-toggle__icon--harvesting` and `farmhouse-toggle__icon--planting`) for its visual styling.

---

## Related DLLs

* **Timberborn.Fields**: The core logic backend that this UI interacts with.
* **Timberborn.Planting**: Provides the `PlantableSpec` and tool factories used to build the bottom bar buttons.
* **Timberborn.EntityPanelSystem**: The framework for injecting the `FarmHouseFragment`.
* **Timberborn.SliderToggleSystem**: Supplies the `SliderToggleFactory` used for the priority switcher.
* **Timberborn.BatchControl**: The overview system utilized by the `FarmHouseBatchControlRowItem`.
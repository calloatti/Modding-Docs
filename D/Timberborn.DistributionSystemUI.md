# Timberborn.DistributionSystemUI

## Overview
The `Timberborn.DistributionSystemUI` module provides the user interface components displayed in the Entity Panel when a player selects a District Crossing. It serves as a localized dashboard for viewing which goods are actively being imported or exported at that specific crossing, and provides a shortcut to the global Distribution Batch Control window.

---

## Key Components

### 1. Crossing Overview Fragment (`DistrictCrossingFragment`)
This fragment appears on the side of the Entity Panel when a `DistrictCrossing` is selected.
* **Shortcut Button**: It features a "DistributionButton" that, when clicked, immediately opens the `BatchControlBox`, switches to the Distribution tab, and automatically focuses on the district belonging to the selected crossing.
* **Import Good Icons**: It displays a categorized grid of all goods in the game. 
    * It uses `ImportGoodIconFactory` to generate these icons based on `GoodGroupSpec` groupings.
    * Each icon (`ImportGoodIcon`) dynamically toggles between an "Importable" and "NonImportable" visual state based on whether the local `DistrictDistributableGoodProvider` has imports enabled for that specific good.

### 2. Crossing Inventory Fragment (`DistrictCrossingInventoryFragment`)
Because the District Crossing acts as a temporary buffer warehouse for goods moving between districts, this fragment displays its internal storage.
* **Inventory Builder**: It uses the `InventoryFragmentBuilderFactory` to create a standard inventory UI, similar to what is seen on regular warehouses.
* **Customization**: The builder is configured with `.ShowRowLimit()` and `.ShowNoGoodInStockMessage()`, providing a clear view of the hardcoded 30-unit limits per good managed by the `DistrictCrossingInventoryInitializer`.

### 3. Import Tooltips (`ImportGoodIconFactory`)
The factory that generates the grid of goods also attaches highly contextual tooltips to each icon.
* **Dynamic Content**: When hovered, the tooltip calculates the current state of that good within the district.
* **State Display**: It toggles the visibility of four different information panels within the tooltip based on the `ImportOption` (Disabled, Auto, Forced) and whether the district actually has the capacity to receive the good (Importable vs NonImportable).

---

## How to Use This in a Mod

### Adding Custom Goods to the Crossing UI
Because the `ImportGoodIconFactory` iterates through `_goodsGroupSpecService.GoodGroupSpecs` and `_goodService.GetGoodsForGroup`, any new goods added by modders (via JSON definition) will automatically appear in the District Crossing's grid of icons, grouped properly under their assigned category icon. No additional C# code is required to support new resources.

---

## Modding Insights & Limitations

* **Fragment Layout Positioning**: The `DistrictCrossingFragment` is added as a `SideFragment`, while the `DistrictCrossingInventoryFragment` is added as a `BottomFragment`. This ensures the massive list of potential goods doesn't push the basic building stats (like worker occupancy) off the screen.
* **No Direct Settings Editing**: Unlike the Batch Control window, the `DistrictCrossingFragment` does not allow players to actually *change* the import/export settings. It is purely an informational readout. To change settings, the player must use the shortcut button to open the Batch Control window.

---

## Related DLLs
* **Timberborn.DistributionSystem**: The core logic module providing `DistrictCrossing`, `DistrictDistributableGoodProvider`, and the import states.
* **Timberborn.EntityPanelSystem**: The framework into which these fragments are injected.
* **Timberborn.BatchControl**: Activated when the player clicks the distribution shortcut button.
* **Timberborn.InventorySystemUI**: Provides the `InventoryFragmentBuilderFactory` used to display the crossing's internal stock.
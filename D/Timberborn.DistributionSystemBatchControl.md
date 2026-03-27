# Timberborn.DistributionSystemBatchControl

## Overview
The `Timberborn.DistributionSystemBatchControl` module is responsible for the "Distribution" tab within the game's Batch Control window. It allows players to view and edit the import/export settings (`GoodDistributionSetting`) for all districts simultaneously, providing a centralized dashboard for managing inter-district logistics.

---

## Key Components

### 1. Batch Control Tab Integration (`DistributionBatchControlTab`)
This class registers the "Distribution" tab into the global Batch Control UI.
* **Registration**: It uses the `BatchControlModuleProvider` to add itself to the Batch Control window with a priority index of `8`.
* **Row Generation**: It queries the `DistrictCenterRegistry` for all finished `DistrictCenter` entities and uses the `DistributionBatchControlRowGroupFactory` to generate a dedicated row group for each district.

### 2. District Controls (`DistrictDistributionControlRowItemFactory`)
This factory creates the header controls for a specific district's row group, allowing for bulk actions across all goods in that district.
* **Reset**: Returns all goods in the district to their default distribution settings.
* **Export Modifiers**: 
    * "Export All" sets the export threshold to `0` (0%).
    * "Export None" sets the threshold to `1` (100%).
* **Import Modifiers**: Provides buttons to instantly set the `ImportOption` for all goods in the district to either `Disabled`, `Auto`, or `Forced`.

### 3. Individual Good Settings (`GoodDistributionSettingItem`)
For every good in a district, this component renders the specific controls needed to manage its logistics.
* **Import Toggle**: Uses a `SliderToggle` created by `ImportToggleFactory` to let players click between the three import states (Disabled, Auto, Forced).
* **Export Threshold Slider**: 
    * A UI `Slider` (managed by `ExportThresholdSlider`) allowing players to drag and set the percentage threshold.
    * It snaps to increments defined by `ExportThresholdSliderScale = 0.05f` (5%).
    * It features a custom tooltip that appears over the drag handle while the user is actively adjusting the slider.
* **Fill Rate Display**: A visual `ProgressBar` showing the current fill rate of the good within the district. A tooltip on the bar provides the exact text breakdown (e.g., `45/100 (45%)`).

### 4. Grouping by Category (`DistributionSettingGroup`)
To prevent the UI from becoming a massive, unreadable list, goods are grouped by their `GoodGroupSpec` (e.g., Food, Materials). 
* The `DistributionSettingGroupFactory` creates a visual wrapper for each category, adding the category's icon at the top of the group.

---

## How to Use This in a Mod

### Adding Custom Goods to the UI
If your mod adds a new good (e.g., "Steel") using standard `GoodSpec` JSON definitions and assigns it to an existing or new `GoodGroupSpec`, the `DistributionSystemBatchControl` will automatically detect it. The `DistributionSettingsRowItemFactory` iterates through all registered `GoodGroupSpecs`, meaning custom goods will populate in this menu without requiring additional UI code.

---

## Modding Insights & Limitations

* **Slider Snapping**: The `ExportThresholdSlider` enforces a strict 5% snapping interval (`0.05f`). Modders cannot change this granularity to 1% without rewriting the slider logic.
* **Update Frequency**: The `UpdateRowItem` method is called frequently by the core Batch Control system. The slider logic specifically checks `Math.Abs(_slider.value - _setting.ExportThreshold) > 0.0001f` before updating the visual position using `SetValueWithoutNotify` to prevent the slider handle from jittering while being dragged.

---

## Related DLLs
* **Timberborn.BatchControl**: The core framework managing the window, tabs, and row structures.
* **Timberborn.DistributionSystem**: The logic backend containing `DistrictDistributionSetting` and `GoodDistributionSetting`.
* **Timberborn.SliderToggleSystem**: The UI utility used for the 3-state Import option toggle.
* **Timberborn.GameDistricts**: Supplies the `DistrictCenter` references used to populate the rows.

Would you like to examine the **Timberborn.DistributionSystemUI** module to see how these settings are displayed on individual District Crossings outside of the Batch Control window?
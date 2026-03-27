# Timberborn.DistributionSystem

## Overview
The `Timberborn.DistributionSystem` module manages the automated movement of goods between game districts via **District Crossings**. It calculates supply and demand across district borders, handles worker behaviors for hauling goods to crossings, and automates the equalization of resource "fill rates" between adjacent districts.

---

## Key Components

### 1. District Crossing Logic (`DistrictCrossing`)
A District Crossing acts as a portal between two adjacent districts. 
* **Linked Buildings**: Every crossing is paired with another crossing building on the opposite side of the district line via the `LinkedBuilding` system.
* **Fill Rate Equalization**: The system attempts to balance resources so that both districts have a similar percentage of their storage capacity filled. It calculates the `AmountToExport` based on the difference in fill rates between the local district and the linked district.
* **Export Validation**: A district can only export a good if its current fill rate is higher than the user-defined `ExportThreshold` and higher than the linked district's fill rate.

### 2. Supply & Demand Tracking (`DistrictDistributableGoodProvider`)
This component aggregates the total storage state for a specific district.
* **Inventory Registry**: It uses the `DistributionInventoryRegistry` to track all inventories in the district that are allowed to "Give" (Stock) or "Take" (Capacity) specific goods.
* **Import Options**: Players can set three modes for goods per district:
    * **Disabled**: No imports allowed.
    * **Auto**: Imports only if there is unreserved capacity in local warehouses.
    * **Forced**: Imports even if no specific warehouse is requesting the good, effectively using the District Crossing itself as temporary storage.

### 3. Worker & Automated Behaviors
The movement of goods is handled by both beavers and background automation.
* **`DistrictCrossingWorkplaceBehavior`**: Directs beavers employed at the crossing. They prioritize either emptying the crossing's internal inventory into local warehouses or hauling needed goods from local warehouses to the crossing for export.
* **`DistrictCrossingAutoExporter`**: A background system that handles the instant transfer of stock between two linked crossings once the goods are physically at the border.

---

## Technical Data Structures

### `DistributableGood`
A snapshot of a specific resource's state within a district:
* **`Stock`**: Total units currently available.
* **`Capacity`**: Total storage space allowed for this good.
* **`FillRate`**: The percentage of capacity currently occupied ($Stock / Capacity$).
* **`MaxExportAmount`**: How many units can be sent out before hitting the user's `ExportThreshold`.

### `GoodDistributionSetting`
Stores the player's configuration for each resource.
* **`ExportThreshold`**: The fill rate below which a district will stop exporting.
* **`ImportOption`**: The behavior (Auto/Forced/Disabled) for bringing goods in.

---

## Modding Insights & Limitations

* **Hardcoded Capacity**: The internal inventory capacity for District Crossings is hardcoded at **30 units** per good via `DistrictCrossingInventoryInitializer`. Modders cannot change this value through JSON alone.
* **Prioritization**: `DistrictCrossingWorkplaceBehavior` uses a distance-based check (`PrioritizeEmptyingDistanceSquared = 4f`). If a worker is very close to the crossing, they will prioritize clearing out imports; if they are further away, they prioritize fetching exports.
* **Road Network Dependency**: For a crossing to function, it must be reachable by the district's road network. If the connection is invalid (e.g., both sides belong to the same district), a status icon (`Status.Distribution.InvalidConnection`) appears.

---

## Related DLLs
* **Timberborn.LinkedBuildingSystem**: Manages the 1-to-1 connection between crossing buildings.
* **Timberborn.InventorySystem**: Provides the underlying storage logic used by the registry.
* **Timberborn.GameDistricts**: Supplies the district identity and building reassignment events.
* **Timberborn.Hauling**: Provides the `WorkplaceWithBackpacks` decorator for crossing workers.

Would you like to examine the **Timberborn.LinkedBuildingSystem** next to see how buildings are paired across district lines?
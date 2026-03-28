# Timberborn.Emptying

## Overview
The `Timberborn.Emptying` module manages the systems and AI behaviors responsible for removing goods from building inventories. It handles player-initiated storage emptying, automatic evacuation of goods from disabled or blocked buildings, and the cleanup of disallowed "unwanted" stock.

---

## Core Components

### 1. `Emptiable`
A component that flags a building's inventory to be cleared out via the `IsMarkedForEmptying` property.
* **Emptying Status**: It displays a localized floating status icon (`Status.Emptying.EmptyingInProgress`) to visually inform the player while the emptying process is active.
* **Serialization**: It persists its marked state and UI status visibility across save files.

### 2. `AutoEmptiable` & `AutoEmptiableBlocker`
These components automate the emptying process for disrupted buildings.
* **`AutoEmptiable`**: Automatically forces a building into the emptying state if it becomes blocked, utilizing events from `BlockableObject` and `AutoEmptiableBlocker`.
* **`AutoEmptiableBlocker`**: Manages internal blocking toggles. It uses the `AutoEmptiableBlockerToggle` helper class to increment or decrement blocking reasons.

### 3. `EmptyingStarter`
The execution engine utilized by worker AI.
* **Capacity Calculation**: It calculates how many goods a worker can carry using the `CarryAmountCalculator`.
* **Destination Routing**: It queries the `CarrierInventoryFinder` to locate the closest valid destination inventory.
* **Safe Reservation**: It safely reserves the necessary stock at the source and the necessary space at the destination before the beaver begins moving.

---

## District Registries
These registries are attached to District Centers to optimize AI queries.
* **`DistrictEmptiableInventoriesRegistry`**: Maintains a list of all `Inventories` currently marked for emptying.
* **`DistrictUnwantedStockInventoryRegistry`**: Monitors all inventories holding "unwanted stock" (goods that exist in storage but are no longer permitted by the current filters).

---

## AI Behaviors
Beavers evaluate these tasks to determine if they should carry goods out of a building.

### Workplace Behaviors
* **`EmptyInventoriesWorkplaceBehavior`**: Instructs workers employed at a specific building to prioritize emptying their own workplace if it is marked for emptying.
* **`EmptyOutputWorkplaceBehavior`**: Directs workers to move manufactured goods out of their building's output inventory.
* **`RemoveUnwantedStockWorkplaceBehavior`**: Prompts building workers to clean up disallowed goods from their own local storage.

### Labor Behaviors (District-Wide)
* **`EmptyInventoriesLaborBehavior`**: Directs general district laborers (haulers/builders) to empty any marked building found in the `DistrictEmptiableInventoriesRegistry`.
* **`RemoveUnwantedStockLaborBehavior`**: Directs general district laborers to remove unwanted goods from any affected building in the district using the `DistrictUnwantedStockInventoryRegistry`.

### Hauling Providers
* **`EmptiableHaulBehaviorProvider`**: Hooks into the hauling system to generate prioritized hauling tasks for marked buildings, using a hardcoded behavior weight of `0.51f`.
* **`UnwantedStockHaulBehaviorProvider`**: Hooks into the hauling system to generate hauling tasks for unwanted stock, using a hardcoded behavior weight of `0.5f`.

---

## Modding Insights & Limitations

* **Priority Hardcoding**: The behavior weights for haulers handling these tasks are strictly hardcoded (`0.51f` for intentional emptying and `0.5f` for unwanted stock). Modders cannot adjust these priorities via JSON specifications.
* **Safety Constraints**: The `EmptyingStarter` distinguishes between regular stock and unwanted stock when reserving goods. Unwanted stock uses `ReserveExactStockAmount`, while regular emptying uses `ReserveNotLessThanStockAmount` to prevent logic deadlocks when multiple beavers interact with the same inventory.

---

## Related DLLs

* **Timberborn.InventorySystem**: Supplies the underlying inventory components, capacity checks, and the `HasUnwantedStock` property.
* **Timberborn.Hauling**: Provides the `WeightedBehavior` system and hauling task integration.
* **Timberborn.Carrying**: Supplies the `CarryAmountCalculator` and `GoodCarrier` components to determine beaver lifting limits.
* **Timberborn.GameDistricts**: Provides the district center context necessary for the registries.
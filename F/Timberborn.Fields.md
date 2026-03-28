# Timberborn.Fields

## Overview
The `Timberborn.Fields` module manages agricultural systems, specifically governing the lifecycle of crops and the task-prioritization logic of farmhouses and their workers. It serves as the bridge between natural resource management (planting/growth) and inventory systems (harvesting/storage).

---

## Key Components

### 1. `Crop`
This component is attached to individual agricultural plant entities.
* **Harvesting Integration**: It uses a `Cuttable` component to determine when a plant has been successfully harvested.
* **GoodStack Management**: Upon being cut, it creates a `GoodStack` (physical items on the map) and registers it with the `GoodStackService<FarmHouse>` so workers can locate the produce.
* **Life Cycle**: It monitors the `LivingNaturalResource` state; if a plant dies, its `Yielder` is disabled to prevent beavers from harvesting dead crops.

### 2. `FarmHouse`
The primary workplace component for agricultural labor.
* **Prioritization**: It maintains a `PlantingPrioritized` flag, toggled by the player, which dictates the worker AI's preference between sowing new seeds or harvesting mature plants.
* **Validation**: It implements `IPlantingSpotValidator` to verify that chosen coordinates are valid for planting and not blocked by other objects.
* **Persistence**: The prioritization state and finished building status are saved and loaded across game sessions.

### 3. AI and Workplace Behaviors
These classes define the logic sequence workers follow when stationed at a farmhouse.
* **`FarmHouseWorkplaceBehavior`**: The central decision-maker for farm tasks.
    * If **Planting** is prioritized: It attempts to sow seeds first; if no spots are available, it transitions to harvesting mature crops.
    * If **Harvesting** is prioritized: It harvests mature crops first; if the building's output is full, it attempts to empty the inventory before sowing seeds.
* **`HarvestStarter`**: A utility behavior used by workers to find harvestable `Yielder` components within range and reserve inventory capacity before moving to harvest.
* **`FarmHouseGoodStackRetrieverWorkplaceBehavior`**: Directs workers to retrieve produce from `GoodStacks` already dropped in the field.

---

## Technical Data Structures

### `GoodStackService<FarmHouse>`
A specialized registry that tracks all physical items dropped on the ground that are relevant to farmhouses. This allows farm workers to efficiently locate the nearest unreserved items to bring back to storage.

---

## How to Use This in a Mod

### Creating a Custom Crop
To add a new agricultural plant, define a prefab with the following components in its JSON:
* `CropSpec`: Required for the system to identify the entity as a farm crop.
* `Cuttable`: To allow the plant to be harvested.
* `Yielder`: To define what items (and how many) the plant produces when harvested.

### Customizing Worker Efficiency
The `HarvestStarter` relies on the `GoodCarrier` lifting capacity to determine how much produce a worker can claim in a single harvest action. Adjusting the worker's carrier capacity will directly affect how many items they can harvest before returning to the farmhouse.

---

## Related DLLs
* **Timberborn.Planting**: Supplies the `PlantBehavior` and `PlantablePrioritizer` used by farmhouses.
* **Timberborn.Yielding**: Defines the `Yielder` and `YielderRemover` mechanics used for the actual extraction of goods.
* **Timberborn.GoodStackSystem**: Provides the core logic for physical item stacks appearing in the world.
* **Timberborn.NaturalResourcesLifecycle**: Supplies `LivingNaturalResource` to track plant health and death.
* **Timberborn.BuildingRange**: Supplies `BuildingWithTerrainRange` which defines the farmhouse's operational area.
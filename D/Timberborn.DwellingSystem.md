# Timberborn.DwellingSystem

## Overview
The `Timberborn.DwellingSystem` module manages housing for beavers. It handles the logic for assigning beavers (`Dweller`) to houses (`Dwelling`), balancing population demographics (adults vs. children), providing population statistics, and ensuring beavers are evicted if their home becomes unreachable or changes districts.

---

## Key Components

### 1. `Dwelling`
This component is attached to buildings that provide housing (e.g., Lodges).
* **Capacity Management**: It calculates `ChildSlots` and `AdultSlots` based on the `MaxBeavers` defined in the `DwellingSpec`. Specifically, it allocates one-third of the slots to children (`Mathf.FloorToInt(MaxBeavers / 3f)`) and the rest to adults.
* **Assignment**: It manages internal sets of `_adults` and `_children` currently assigned to the building, exposing events like `NumberOfDwellersChanged` when a beaver moves in or out.
* **Sleep Effects**: It exposes the `ContinuousEffectSpec` (like comfort or rest buffs) that apply to beavers while they sleep inside.

### 2. `Dweller`
This component is attached to beavers, representing their status as a resident.
* **Home State**: It tracks the beaver's current `Home` and saves/loads this reference across game sessions using a `ReferenceSerializer`.
* **Desire for Better Housing**: A dweller will actively look for a better home (`IsLookingForBetterHome()`) if their current home is overpopulated (e.g., too many children in one house) or underpopulated (a lone adult in a house with free slots).

### 3. Auto-Assignment & Balancing
The system automates the process of moving beavers into homes.
* **`DwellerHomeAssigner`**: A global tickable singleton that runs every frame. It requests the "stalest" dwelling (the one that has gone the longest without an assignment attempt) and tries to fill its empty slots by iterating through the district's homeless or unsatisfied beavers.
* **`AutoAssignableDwelling`**: An entity component that dictates *who* can move in. It enforces rules like `CanChildMoveIn` (ensuring at least one adult is present or the house is underpopulated by children) and `CanAdultMoveIn` (ensuring adults consolidate to free up space in other homes).

### 4. Reachability & Eviction (`UnreachableHomeUnassigner`)
This component ensures beavers don't stay assigned to homes they can no longer use.
* **District Changes**: It listens to the `Citizen.ChangedAssignedDistrict` event. If a beaver is reassigned to a new district, it is immediately evicted from its old home.
* **NavMesh Updates**: It implements `INavMeshListener`. If the pathfinding network changes (e.g., a path is deleted), it schedules a check to verify the beaver can still reach its home.

---

## Technical Data Structures

### `DwellingStatistics`
A struct used to track housing capacity.
* **`OccupiedBeds`**: The total number of beavers currently assigned to homes.
* **`FreeBeds`**: The total number of empty slots across all available housing.
* These statistics are aggregated at both the District level (`DistrictDwellingStatisticsProvider`) and the Global level (`GlobalDwellingStatisticsProvider`) for use by the UI.

---

## Modding Insights & Limitations

* **Hardcoded Demographics**: The ratio of children to adults in a dwelling is hardcoded (`MaxBeavers / 3f` for children). Modders cannot change this ratio via JSON specs; custom housing logic would require a C# override.
* **Orphan Prevention**: The `CanChildMoveIn` logic specifically prevents children from moving into an empty house unless absolutely necessary (`UnderpopulatedByChildren`).
* **Performance Optimization**: The `DwellerHomeAssigner` only processes *one* dwelling per tick using the `StaleAssignableDwellingService`. This prevents severe lag spikes during massive population booms or housing district reassignments.

---

## Related DLLs
* **Timberborn.Beavers**: Defines the `BeaverSpec`, `AdultSpec`, and `Child` markers used to determine demographics.
* **Timberborn.GameDistricts**: Provides the `DistrictBuilding` and `DistrictPopulation` tracking necessary for assignments.
* **Timberborn.PopulationStatisticsSystem**: Defines the `DwellingStatistics` struct and aggregates the data for the UI.
* **Timberborn.Navigation**: Provides the `INavMeshListener` to handle pathfinding-based evictions.
# Timberborn.DistanceHeatmap

## Overview
The `Timberborn.DistanceHeatmap` module provides visual feedback on the walking distance between a selected building and other structures within the same district. It is primarily used when a player selects a building that has a limited operational range (like a Builder's Hut or Forester), causing other buildings in the district to be highlighted with a color gradient representing their distance along the road network.

---

## Key Components

### 1. `DistanceHeatmapEnabler`
This component acts as the trigger for the heatmap effect.
* **Selection Trigger**: It implements `ISelectionListener`. When a building with a `BlockObjectWithPathRangeSpec` is selected, it enables itself.
* **District Integration**: It uses a `PathDistrictRetriever` to find the `DistrictCenter` currently serving that building. 
* **Activation**: In its `Update()` loop, it calls the `DistanceHeatmapShower` attached to the district center to display the heatmap.

### 2. `DistanceHeatmapShower`
Attached to every `DistrictCenter`, this component manages the actual rendering of the highlight colors on buildings.
* **Heatmap Generation**: When `ShowHeatmap()` is called, it iterates through every enabled building in the district using the `DistrictBuildingRegistry`.
* **Distance Calculation**: It uses the `Accessible` system to find the path distance along roads (falling back to `FindInstantRoadPath` if a standard path isn't cached) from the district center to the target building.
* **Visual Application**: It converts the walking distance into a color using `DistanceToColorConverter` and applies it to the target building via the `Highlighter` service. Highlights are modified by a `DarkeningFactor` (0.5f) to ensure they are readable against the terrain.
* **Dynamic Updates**: It listens for buildings being added or removed from the district (`FinishedBuildingInstantRegistered/Unregistered`) to update the highlights in real-time as the player builds or deletes structures.

### 3. `DistanceHeatmapConfigurator`
A standard Bindito configurator that registers these components into the game context.
* **Decorators**: It automatically attaches `DistanceHeatmapShower` to all `DistrictCenter` entities and `DistanceHeatmapEnabler` to any building containing a `BlockObjectWithPathRangeSpec`.

---

## Modding Insights

### Enabling Heatmaps for Custom Buildings
If you are creating a modded building that needs to show a district-wide distance heatmap when selected, you simply need to ensure your building prefab includes the `BlockObjectWithPathRangeSpec` component in its JSON/Unity template.

### Calculation Logic
The heatmap logic is strictly tied to **Road Distance**, not Euclidean (as-the-crow-flies) distance. If a building is physically close but lacks a road connection, it will not be highlighted by this system.

---

## Related dlls
Based on the namespaces and dependencies, these assemblies are closely linked to the Distance Heatmap System:
* **Timberborn.GameDistricts**: Supplies the `DistrictCenter` and building registry logic.
* **Timberborn.Navigation**: Provides the pathfinding distance calculations.
* **Timberborn.SelectionSystem**: Supplies the `ISelectionListener` interface and high-level highlighting services.
* **Timberborn.BuildingsNavigation**: Connects buildings to the road and district network.

**Would you like me to analyze how the `DistanceToColorConverter` determines the specific colors used in the gradient?**
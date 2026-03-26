# Timberborn.BuildingsReachability

## Overview
The `Timberborn.BuildingsReachability` module manages the systems that check if buildings are connected to the road network and if construction sites can be physically reached by builders. It ensures players cannot place invalid constructions (like placing a building with its door facing a cliff) and provides the UI status warnings (like the red path icon) when a building is severed from a district.

---

## Key Components

### 1. Construction Site Validation
These components prevent players from placing impossible ghost buildings.
* **`ConstructionSiteEntranceBlockedPreviewValidator`**: When a player is trying to place a building, this validator checks if the entrance is blocked by terrain (cliffs), lack of a NavMesh (floating in the air), or by an intersecting object (like a solid wall). If blocked, it highlights the offending geometry in red and displays the `Buildings.EntranceBlocked` warning.
* **`ReachabilityPreviewValidator`**: Checks if the ghost building's construction site will actually be reachable by builders. It queries the `ReachableConstructionSite` component.
* **`ReachableConstructionSite`**: Implements `IUnreachableEntity`. It queries the `IDistrictService` to check if the construction site's `Accessible` node is located on `InstantDistrictRoadSpill` (meaning a builder can physically walk there from a District Center).

### 2. Disconnected Building Warnings
These components handle buildings that are already built but become orphaned (e.g., the player deletes the road connecting them to the town).
* **`UnconnectedBuildingStatus`**: Attached to `BuildingAccessible` entities. When the building enters the finished state, it listens to the `ReassignedInstantDistrict` event on the `DistrictBuilding` component. If the building has no `InstantDistrict`, it activates the "UnconnectedBuilding" floating icon and UI alert.
* **`UnconnectedBuildingBlocker`**: A generic marker component (`IUnconnectedBuildingBlocker`) that suppresses the "Unconnected" warning. If a building has this component (via `UnconnectedBuildingBlockerSpec` in JSON), `UnconnectedBuildingStatus` will ignore its disconnected state. This is crucial for isolated decorative elements or specialized ruins that don't need road connections.

### 3. Dynamic UI Updating
* **`EntityReachabilityStatus`**: A `TickableComponent` that manages the UI state of unreachable objects. It finds all components on the entity implementing `IUnreachableEntity`. If *any* of them report being unreachable during a tick, it activates the `UnreachableObject` status. To save performance, it disables itself when the object is unselected by the player and only ticks when selected.

---

## How to Use This in a Mod

### Suppressing the "Unconnected" Warning
If you create a custom modded building that does not require a road connection to function (e.g., a decorative statue, a wild tree spawner, or a hidden logic controller), you do not want the player to see a flashing red warning icon over it.

You can easily suppress this by adding the `UnconnectedBuildingBlockerSpec` to your building's JSON template:

```json
{
  "BuildingSpec": {
    "BuildingCost": [ ... ]
  },
  "UnconnectedBuildingBlockerSpec": {}
}
```
The configurator will automatically attach the `UnconnectedBuildingBlocker`, and the `UnconnectedBuildingStatus` component will detect it and suppress the UI warning.

### Creating Custom Reachability Rules
If your mod introduces a new way for beavers to reach buildings (e.g., teleportation pads, or builders who can swim across deep water), you need to tell the game that these sites are reachable, even if they aren't connected to a road.

You can implement `IExpandedConstructionSiteReachability`:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.BuildingsReachability;

// Attach this component to your custom building
public class TeleporterReachability : BaseComponent, IExpandedConstructionSiteReachability
{
    private MyCustomTeleporterNetwork _teleporterNetwork;

    public void Awake()
    {
        _teleporterNetwork = DependencyContainer.GetInstance<MyCustomTeleporterNetwork>();
    }

    public bool IsReachable()
    {
        // If a teleporter is nearby, tell the game it's reachable!
        // This prevents the ReachableConstructionSite component from marking it invalid.
        return _teleporterNetwork.IsWithinTeleportRange(this.Transform.position);
    }
}
```

---

## Modding Insights & Limitations

* **Event-Driven vs Ticking**: Notice the difference in architecture between `UnconnectedBuildingStatus` and `EntityReachabilityStatus`. The former is highly optimized, updating only when a specific `ReassignedInstantDistrict` event fires. The latter is a brute-force `TickableComponent` that polls the reachability state every frame while the entity is selected. Modders adding heavy calculations to `IUnreachableEntity.IsUnreachable()` must be careful, as it will execute constantly while the player has the building clicked.
* **Instant Path Requirement**: `ReachableConstructionSite` relies on `IsOnInstantDistrictRoadSpill`. "Instant" means the path must actually exist and be fully constructed. You cannot place a construction site at the end of a long line of *planned* (ghost) paths. The paths must be built first before the building site becomes "reachable" and builders are dispatched.
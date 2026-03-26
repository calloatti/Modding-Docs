# Timberborn.BlockSystemNavigation

## Overview
The `Timberborn.BlockSystemNavigation` module serves as the critical bridge between the physical block grid (`Timberborn.BlockSystem`) and the game's pathfinding engine (`Timberborn.Navigation`). It is responsible for translating the physical footprint of a building (its solid blocks, floors, and entrances) into a network of walkable edges and blocked nodes that citizens (beavers/bots) use to calculate routes.


---

## The Pathfinding Translation Process
In Timberborn, buildings aren't just obstacles; they often contain walkable surfaces (like platforms or the roofs of lodges). The game must calculate how a beaver can transition from the ground onto the building.

This translation is handled primarily by the `NavMeshObjectUpdater`. When a building is placed, this updater performs several steps:
1.  **Base Footprint Blocking**: It looks at the `PositionedBlocks` of the `BlockObject`. Any block intersecting `BlockOccupations.Bottom` is marked as a restricted coordinate.
2.  **Wall Generation**: By default, it generates "walls" (blocked edges) around the bottom occupied coordinates to prevent actors from clipping through the sides of solid buildings.
3.  **Entrance Pathing**: If the building has an entrance, it automatically creates a walkable `NavMeshEdge` between the `DoorstepCoordinates` and the actual `Coordinates` of the entrance.
4.  **Custom Modifiers**: It applies any data-driven overrides defined in the `BlockObjectNavMeshSettingsSpec`, such as explicitly unblocked edges or custom path costs.

---

## Key Components

### 1. `BlockObjectNavMesh` & `BlockObjectNavMeshAdder`
These two components manage the lifecycle of a building's navigation data.
* **`BlockObjectNavMesh`**: Attached to the building, it creates and holds the `NavMeshObject` (the actual graph data) using an `INavMeshObjectFactory`. It exposes a `RecalculateNavMeshObject()` method to force a refresh.
* **`BlockObjectNavMeshAdder`**: Implements `IInitializableEntity` and `IDeletableEntity`. When the building finishes construction (is no longer a preview), it enqueues the `NavMeshObject` into the global regular NavMesh. When the building is destroyed, it enqueues its removal.

### 2. `BlockObjectPreviewNavMesh`
Previews (construction ghosts) have their own navigation logic. This component implements `IPreviewServiceMember`. When a ghost is placed, it adds the pathing data to a specific *preview* NavMesh, allowing the game to calculate if a proposed building placement will trap beavers or cut off vital routes before the player commits to it.

### 3. `BlockObjectNavMeshSettingsSpec` (Data-Driven Configuration)
This system is highly data-driven, meaning modders can vastly alter how a building interacts with pathfinding without writing any C# code. The spec allows defining:
* `NoAutoWalls` (bool): If true, prevents the game from automatically drawing blocked edges around the building's base.
* `GenerateFloorsOnStackable` (bool): If true, it automatically creates walkable edges on the block *above* any block marked as `Stackable` (e.g., wooden platforms).
* `EdgeGroups`, `UnblockedCoordinates`, `BlockedEdges`: Arrays that allow for precise, coordinate-level overrides of the NavMesh.

---

## How to Use This in a Mod

Because `BlockSystemNavigation` relies heavily on templates and specs, you will primarily interact with it via JSON when creating new buildings or paths.

### Configuring Custom Pathing in JSON
If you are creating a custom building (like a toll bridge or a decorative archway) where beavers need to walk *through* a space that the game might otherwise consider blocked, you configure the `BlockObjectNavMeshSettingsSpec` in your prefab's JSON file:

```json
{
  "BlockObjectNavMeshSettingsSpec": {
    "NoAutoWalls": true,
    "GenerateFloorsOnStackable": false,
    "UnblockedCoordinates": [
      {
        "Group": "Default",
        "Coordinates": { "X": 1, "Y": 0, "Z": 0 }
      }
    ],
    "EdgeGroups": [
      {
        "Cost": 1.5,
        "IsPath": true,
        "AddedEdges": [
          {
            "Start": { "X": 0, "Y": 0, "Z": 0 },
            "End": { "X": 2, "Y": 0, "Z": 0 },
            "IsTwoWay": true
          }
        ]
      }
    ]
  }
}
```

### Forcing a NavMesh Recalculation via C#
If you create a mod that dynamically changes a building's shape or walkability (like a drawbridge that raises and lowers), you must tell the NavMesh to recalculate. You can fetch the `BlockObjectNavMesh` component and call its recalculation method:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.BlockSystemNavigation;

public class DynamicDrawbridge : BaseComponent
{
    private BlockObjectNavMesh _navMesh;

    public void Awake()
    {
        _navMesh = GetComponent<BlockObjectNavMesh>();
    }

    public void OnDrawbridgeLowered()
    {
        // ... your custom logic to change physical blocks ...
        
        // Force the NavMesh to update so beavers realize they can walk here now
        _navMesh.RecalculateNavMeshObject();
    }
}
```

---

## Modding Insights & Limitations

* **Group Initializer Requirement**: The `BlockObjectNavMeshGroupInitializer` scans all `BlockObjectNavMeshSettingsSpec` templates on load. If your JSON uses a custom `Group` name for edges, the game automatically registers it via `_navMeshGroupService.GetOrAddGroupId()`.
* **Elevated Entrances**: The `NavMeshObjectUpdater` contains specific logic for elevated entrances (`AddEdgesBlockedByElevatedEntrance`). If a building has an entrance on a Z-level greater than 0, it explicitly blocks edges for coordinates directly *below* the entrance level to prevent pathing confusion. Modders creating suspended buildings must be aware of this automated blocking behavior.
* **Top Occupied Blocking**: The system inherently assumes that a tile occupied by `BlockOccupations.Top` blocks vertical movement. The updater specifically finds all `_topOccupiedCoordinates` and blocks the edge transitioning to the tile directly above it (`coordinate.Above()`).
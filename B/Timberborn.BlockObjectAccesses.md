# Timberborn.BlockObjectAccesses

## Overview
The `Timberborn.BlockObjectAccesses` module determines exactly where beavers can stand in the game world to interact with a specific building, resource, or block object. It calculates the valid adjacent grid tiles (neighbors) around an object's footprint, checks the terrain height and NavMesh to ensure those tiles are actually reachable, and feeds this data into the entity's `Accessible` component.

For modders, this module is crucial when designing custom buildings with unique shapes, entrances, or multi-level interaction points. It provides both automatic perimeter access generation and manual JSON-driven overrides.

---

## Key Components

### 1. `BlockObjectAccessible` (The Main Integration)
This is the primary component attached to buildings that need to be reached by beavers.
* **Integration**: It implements `IAccessibleNeeder`, which means the game engine injects an `Accessible` component into it. 
* **Dynamic Updates**: It implements `INavMeshListener`. If the terrain or paths around the building change (e.g., the player deletes a road or builds a platform nearby), it dynamically recalculates its access points and updates the `Accessible` component.
* **Verticality**: It calculates accesses between `MinZ` (the building's base level) and `MaxZ` (determined by `_accessLevelsAboveGround`).

### 2. `BlockObjectAccessGenerator` (The Math Engine)
This component performs the heavy lifting to find valid standing points.
* **Neighbor Calculation**: It uses `ParentedNeighborCalculator` to find all tiles bordering the building's 2D footprint.
* **Validation**: It checks if a neighboring tile is blocked by terrain (`NoTerrainInTheWay`), is on the navigation mesh (`_navMeshService.IsOnNavMesh`), or is blocked by another object (`IsAccessBlockedBySelf`).
* **Visual Offsets**: It adjusts the world-space vector of the access point so the beaver stands slightly towards the building. It applies a `StraightOffsetScale` (0.2f) or a `DiagonalOffsetScale` (0.3f) depending on the angle of approach.

### 3. Explicit Control (`BlockObjectAccesses` & `BlockObjectAccessesSpec`)
Sometimes automatic perimeter calculation isn't enough. This component allows explicit whitelist/blacklist control over access tiles.
* **`BlockingCoordinates`**: Forces specific relative coordinates to be treated as blocked, preventing beavers from standing there to access the building.
* **`AllowedCoordinates`**: Forces specific relative coordinates to be treated as valid access points, even if they might otherwise be rejected by the generator (provided they are still on the NavMesh).

### 4. `HighBlockObjectAccessesAdder`
By default, the system only looks for access points at the base elevation of the building. Attaching this component tells `BlockObjectAccessible` to search for access points all the way up to the building's maximum height (`Blocks.Size.z`), allowing players to build platforms next to the second or third floor of your building to reach it.

---

## How to Use This in a Mod

### 1. Enabling High-Level Access
If you are creating a tall building (like a massive water tank or a multi-story factory) and want beavers to be able to reach it from platforms built alongside its upper levels, you do not need to write C# code. You simply need to ensure `HighBlockObjectAccessesAdder` is attached to your entity. Since there isn't a dedicated Spec for it in this module, you may need to add it via a custom configurator if it's not applied to your building type by default.

### 2. Manual Access Overrides via JSON
If you have a 3x3 building but only want beavers to access it from the front door (and ignore the sides and back), you can use the `BlockObjectAccessesSpec` in your building's JSON template to explicitly block the other coordinates.

```json
{
  "Components": {
    "BlockObjectAccessesSpec": {
      "BlockingCoordinates": [
        {"X": -1, "Y": 0, "Z": 0},
        {"X": -1, "Y": 1, "Z": 0},
        {"X": 1, "Y": 0, "Z": 0}
      ],
      "AllowedCoordinates": [
        {"X": 0, "Y": -1, "Z": 0}
      ]
    }
  }
}
```
*Note: Coordinates in this spec are defined relative to the building's origin (usually the bottom-left corner or center, depending on the block definition).*

---

## Modding Insights & Limitations

* **NavMesh Dependency**: Even if you explicitly add a coordinate to `AllowedCoordinates`, a beaver cannot access the building from that tile unless it is natively recognized by the `INavMeshService`. The tile must be walkable terrain, a path, or a platform.
* **Underground Behavior**: The `BlockObjectAccessGenerator` has specific logic for `_isFullyUnderground`. If all blocks of a building are marked as underground, the access generator searches for access points strictly on the terrain layer *above* the building's top level.
* **Bottom Accesses**: For buildings with `BlockStackable.UnfinishedGround` or foundation blocks, the generator also yields access points directly below the object (`current.Coordinates.Below()`). This allows beavers to build platforms or certain structures from underneath.
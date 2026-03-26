# Timberborn.BuildingDoorsteps

## Overview
The `Timberborn.BuildingDoorsteps` module is a small visual enhancement system responsible for automatically spawning a standardized 3D "doorstep" mesh in front of building entrances. This ensures a consistent visual language across all buildings, indicating exactly where beavers will enter or exit a structure, even while the building is still an unfinished construction site.

---

## Key Components

### 1. `BuildingDoorstepSpawner`
This singleton manages the dynamic instantiation of the doorstep mesh.
* **Asset Loading**: During `Load()`, it fetches the standard doorstep prefab model from `ConstructionBases/Doorstep/Doorstep.Model` via the `IAssetLoader`.
* **Event Hook**: It listens to the global `EntityInitializedEvent` on the `EventBus`. When any entity is initialized, it checks if that entity possesses a `BuildingModel`. 
* **Spawn Logic**: If the building has an entrance, it uses the `OptimizedPrefabInstantiator` to clone the doorstep mesh and parents it directly to the building's `UnfinishedModel` transform. 
* **Positioning**: It calculates the correct local position relative to the building's base using `component.Entrance.Coordinates + DoorstepModelOffset - new Vector3Int(0, 0, component.BaseZ)`.
* **Material Sync**: Finally, it calls `AddMaterials()` on the building's `EntityMaterials` component to ensure the newly spawned doorstep perfectly matches the visual rendering state (e.g., ghost shader, unfinished wood) of the parent building.

### 2. `DoorstepSpawnDisablerSpec`
An empty configuration record used as a negative constraint. The `CanSpawnDoorstep` method explicitly checks for the presence of this spec; if found, the game will *not* spawn the automated doorstep mesh for that building.

---

## How to Use This in a Mod

Modders generally do not need to interact with this C# code directly. If you create a custom building with an entrance in your JSON template, the game will automatically spawn a doorstep for you.

### Disabling the Automated Doorstep
If you are creating a custom building where the automated wooden doorstep looks visually incorrect (e.g., a massive stone temple where you have modeled a grand staircase into your own custom mesh), you must tell the game *not* to spawn the default doorstep.

Simply add the `DoorstepSpawnDisablerSpec` to your building's JSON file:

```json
{
  "BlockObjectSpec": {
    "Entrance": {
      "HasEntrance": true,
      "Coordinates": { "X": 1, "Y": 0, "Z": 0 }
    }
  },
  "DoorstepSpawnDisablerSpec": {}
}
```

---

## Modding Insights & Limitations

* **Ground-Level Only**: The `CanSpawnDoorstep` method enforces a strict height check: `blockObject.Entrance.Coordinates.z - blockObject.BaseZ == 0`. The automated doorstep will *only* spawn if the building's entrance is located exactly on the building's foundational base layer. Elevated entrances (like those on suspended lodges) will never receive an automated doorstep mesh.
* **Unfinished Model Parenting**: The spawner explicitly parents the new mesh to the `buildingModel.UnfinishedModel.transform`. This means the doorstep is treated as part of the construction site itself. If your custom building uses complex multi-stage construction models, be aware that this doorstep is injected directly into that specific transform hierarchy.
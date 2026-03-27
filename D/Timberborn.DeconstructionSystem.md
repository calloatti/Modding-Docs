# Timberborn.DeconstructionSystem

## Overview
The `Timberborn.DeconstructionSystem` module manages the events and visual feedback associated with removing buildings and terrain from the game world. It provides the data structures to identify removable objects, notifies other game systems when a deconstruction occurs, and handles the performance-optimized spawning of "dust" particles during the demolition process.

---

## Key Components

### 1. `Deconstructible`
This component is automatically decorated onto every entity possessing a `BuildingSpec` via the `DeconstructionSystemConfigurator`. 
* It serves as a marker that an object is eligible for removal.
* It provides a `DisableDeconstruction()` method to programmatically prevent an entity from being removed.

### 2. `DeconstructionNotifier`
This singleton monitors the lifecycle of entities and broadcasts removal events to the rest of the game.
* **Event Interception**: It listens for `EntityDeletedEvent`.
* **Building Coordinates**: If the deleted entity has an enabled `Deconstructible` component, the notifier calculates the spatial footprint of the building. It prefers foundation coordinates but falls back to all occupied coordinates if no specific foundation is defined.
* **Broadcast**: It posts a `BuildingDeconstructedEvent`, containing the `Deconstructible` reference and the list of affected grid coordinates.

### 3. `DeconstructionParticleFactory`
This system manages the visual "rubble" or "dust" effects that appear when something is destroyed.
* **Triggers**: It listens for both `BuildingDeconstructedEvent` and `TerrainDestroyedEvent`.
* **Performance Optimization**: To prevent framerate drops when large numbers of objects are deleted simultaneously (e.g., using a mass-delete tool), it implements a spawning threshold:
    * If the number of particles is below `MinParticlesForThreshold`, all are spawned.
    * If above the threshold, it uses a random probability based on neighboring destruction density (`_particlesInNeighbours`) and a `countFactor` to selectively skip particle spawning.
* **Time Sensitivity**: It supports particles that run on either scaled game time or unscaled real-time, depending on the destruction context.

---

## How to Use This in a Mod

### Preventing Deconstruction
If you are creating a special quest building or a critical piece of infrastructure that the player should not be able to delete, you can use the `Deconstructible` component.

```csharp
using Timberborn.DeconstructionSystem;
using Timberborn.BaseComponentSystem;

public class MyIndestructibleBuilding : BaseComponent, IAwakableComponent {
    public void Awake() {
        // This will hide the deconstruction button in the UI 
        // and prevent removal tools from targeting this building.
        GetComponent<Deconstructible>().DisableDeconstruction();
    }
}
```

### Reacting to Deconstruction
If your mod needs to perform logic when a building is removed (e.g., spawning a "Scrap" resource or updating a global counter), you should listen for the `BuildingDeconstructedEvent`.

```csharp
[OnEvent]
public void OnBuildingDeconstructed(BuildingDeconstructedEvent buildingEvent) {
    foreach (var coord in buildingEvent.Coordinates) {
        // Custom logic for every tile the building occupied
    }
}
```

---

## Modding Insights & Limitations

* **Batch Spawning**: The `DeconstructionParticleFactory` processes all queued particles during `LateUpdateSingleton`, ensuring that logic happens exactly once per frame regardless of how many items were deleted.
* **Hardcoded Foundation Logic**: The `DeconstructionNotifier` prioritizes `GetFoundationCoordinates()`. If a building is modeled with a large overhang but small foundations, the dust particles will only appear at the ground level where the building was "anchored".
* **Neighbor Density Math**: The probability of a particle spawning decreases as the number of neighboring tiles being destroyed increases. This uses a square root curve (`Mathf.Sqrt`) to determine the threshold, ensuring the visual "cloud" looks dense without over-spawning.

---

## Related dlls
* **Timberborn.BlockSystem**: Used to retrieve `PositionedBlocks` and grid coordinates for demolition.
* **Timberborn.TerrainPhysics**: Provides the `TerrainDestroyedEvent` which the particle factory monitors.
* **Timberborn.Buildings**: The system into which `Deconstructible` is decorated.
* **Timberborn.AssetSystem**: Used by the particle factory to load prefabs from specified paths.
# Timberborn.BlockAndTerrainLoadValidation

## Overview
The `Timberborn.BlockAndTerrainLoadValidation` module is a small but critical piece of the game's loading pipeline. It acts as a bridge between the entity deserialization phase and the start of the simulation physics. 

When a save file or custom map is loaded, the game instantiates hundreds or thousands of entities. This module ensures that all block-based entities (buildings, natural resources) are bulk-registered to the block system, and immediately following that, forces the terrain physics system to validate and recalculate itself based on those newly placed blocks.

---

## Key Components

### 1. `BlockAndTerrainBatchLoader`
This class implements the `IEntityBatchLoader` interface, which is called by the `WorldPersistence` system when a batch of entities has finished loading.
* **`AddToServices`**: It first passes the loaded entities to the `BlockObjectBatchLoader`, which registers every `BlockObject` to the game's internal 3D grid.
* **`ValidateAll`**: Once all blocks are registered, it calls `TerrainPhysicsPostLoader.ValidateAll()`. This is crucial because terrain walking paths, physics, and collisions often depend on what buildings or blocks are currently occupying the grid.

### 2. `BlockAndTerrainLoadValidationConfigurator`
This configurator injects the batch loader into the game using a `MultiBind<IEntityBatchLoader>`.
* **Contexts**: Unlike many gameplay modules, this configurator operates in both the `"Game"` and `"MapEditor"` contexts, as terrain and block validation is strictly required in both environments to prevent falling through the map or placing blocks illegally.

---

## How to Use This in a Mod

### Creating a Custom Batch Loader
Modders generally do not need to interact with `BlockAndTerrainBatchLoader` directly. However, it serves as a perfect template if your mod needs to perform bulk calculations on entities immediately after a save file loads, but *before* the game starts ticking.

If your mod introduces a complex network (like a power grid or custom fluid pipes) that needs to link up all its pieces at load time, you can implement your own `IEntityBatchLoader`:

```csharp
using System.Collections.Generic;
using Timberborn.EntitySystem;
using Timberborn.WorldPersistence;

public class MyCustomNetworkBatchLoader : IEntityBatchLoader
{
    private readonly MyCustomNetworkManager _networkManager;

    public MyCustomNetworkBatchLoader(MyCustomNetworkManager networkManager)
    {
        _networkManager = networkManager;
    }

    // Called automatically by the game during the load sequence
    public void BatchLoadEntities(IEnumerable<EntityComponent> entities)
    {
        foreach (var entity in entities)
        {
            var networkNode = entity.GetComponent<MyCustomNetworkNode>();
            if (networkNode != null)
            {
                _networkManager.RegisterNode(networkNode);
            }
        }
        
        // After all nodes are found, build the network
        _networkManager.RecalculateGraph();
    }
}
```
You would then bind it in your configurator using `MultiBind<IEntityBatchLoader>().To<MyCustomNetworkBatchLoader>().AsSingleton();`.

---

## Modding Insights & Limitations

* **Order of Operations**: By observing this module, we can infer the game's load lifecycle: Entities are instantiated -> `IEntityBatchLoader`s run (where blocks are pushed to the grid and terrain is validated) -> `IAwakableComponent` / `IInitializableEntity` methods likely finish settling. If your mod tries to query the `BlockService` or `TerrainService` in an entity's `Awake()` method during game load, it might fail because this batch loader hasn't run yet.
* **Dependency Delegation**: Notice that this module does not actually contain the logic for loading blocks or validating terrain; it merely coordinates the `BlockObjectBatchLoader` and `TerrainPhysicsPostLoader`. This strict separation of concerns is a hallmark of Timberborn's architecture.
# Timberborn.Beavers

## Overview
The `Timberborn.Beavers` module defines the foundational entities, collections, and lifecycles of the beavers themselves. It distinguishes between adult and child beavers, handles their initialization, names them, sets their visual textures based on faction, manages their growth from childhood to adulthood, and tracks the global population count.

This module is essential for modders who want to interact directly with the beaver entities, hook into their lifecycle events (like birth or growing up), or query the global population statistics.

---

## Key Components

### 1. `Beaver` and Specifications
* **`Beaver`**: A simple marker component attached to all beavers (both adults and children). It implements `IDeadNeededComponent`.
* **`AdultSpec` / `ChildSpec` / `BeaverSpec`**: Record classes used to identify blueprints in the `TemplateService` and configure components during game initialization. `BeaverSpec` applies to all beavers, while `AdultSpec` and `ChildSpec` apply specifically to adults or children.

### 2. Population Management (`BeaverCollection` & `BeaverPopulation`)
* **`BeaverCollection`**: A utility class that maintains separate lists for all `Beavers`, `Adults`, and `Children`. It categorizes a beaver as a child if it has the `ChildSpec` component; otherwise, it is considered an adult.
* **`BeaverPopulation`**: A singleton that acts as the public API for settlement statistics. It listens to `CharacterCreatedEvent` and `CharacterKilledEvent` on the `EventBus` to keep the `BeaverCollection` up to date.

### 3. Beaver Creation (`BeaverFactory`)
* **`BeaverFactory`**: This singleton is responsible for instantiating new beavers.
* It fetches the appropriate `Blueprint` for an adult or child via the `TemplateService` during `Load()`.
* It handles calculating `DayOfBirth` and `LifeProgress` based on the provided inputs.
* **`CreateAdultFromChild`**: This crucial method handles the transition from child to adult. It creates a new adult entity at the child's position and uses `IChildhoodInfluenced` to transfer necessary state (like contamination incubation) from the old child entity to the new adult entity.

### 4. Naming and Textures
* **`BeaverNameService`**: Loads a pool of names from the localization key `"Beaver.NamePool"`, shuffles them, and provides a guaranteed unique (until the pool runs out) name for new beavers. It saves and loads the remaining name pool to ensure consistency across play sessions.
* **`BeaverEntityNamer`**: Implements `IEntityNamer` to assign names from the `BeaverNameService` to the beaver entities.
* **`BeaverTextureSetter`**: Assigns a random texture to the beaver's `CharacterMaterialModifier` upon creation. It pulls from either `FactionSpec.ChildTextures` or `FactionSpec.Textures` depending on whether the beaver has a `Child` component.

### 5. Childhood and Growth (`Child` & `ChildRootBehavior`)
* **`Child`**: A tickable component that continuously increments its `GrowthProgress` based on `LifeService.CalculateGrowthProgress`. It respects a generic bonus multiplier using the ID `"GrowthSpeed"`.
* **`GrowUpIfItIsTime()`**: Checks if `GrowthProgress >= 1f`. If true, it calls `GrowUp()`, which swaps the child entity for a new adult entity using `BeaverFactory.CreateAdultFromChild`, transfers the player's selection focus if necessary, destroys the child entity, and posts a notification.
* **`ChildRootBehavior`**: The root AI behavior for children. It ensures newborn babies wait in an idle state immediately after birth (`WaitedAfterBirth`) before starting their routine. It then continuously checks `_child.GrowUpIfItIsTime()`.

---

## How to Use This in a Mod

### Spawning Custom Beavers
If you are creating a mod that spawns beavers via a custom event or building (e.g., an cloning vat or rescue beacon), you should inject and use the `BeaverFactory`:

```csharp
using Timberborn.Beavers;
using Timberborn.SingletonSystem;
using UnityEngine;

public class MyCustomSpawner : ILoadableSingleton
{
    private readonly BeaverFactory _beaverFactory;

    public MyCustomSpawner(BeaverFactory beaverFactory)
    {
        _beaverFactory = beaverFactory;
    }

    public void Load() { }

    public void SpawnAnAdult(Vector3 position)
    {
        // Spawns a brand new adult beaver at the specified position
        _beaverFactory.CreateNewbornAdult(position);
    }
}
```

### Adding New Names
To expand the list of names beavers can have, you do not need C# code. You simply need to append names to the `Beaver.NamePool` string in a custom `.csv` localization file provided with your mod. The `BeaverNameService` splits this localized string by newlines (`\n`).

---

## Modding Insights & Limitations

* **Entity Swapping**: When a child grows up, the game does not change the components on the existing entity; it completely destroys the child `GameObject` and spawns a brand new adult `GameObject`. If you are attaching custom runtime data to a child beaver, it will be lost upon reaching adulthood unless your custom component implements `IChildhoodInfluenced` to transfer that data during the `BeaverFactory.CreateAdultFromChild` phase.
* **Adult vs Child Hardcoding**: The logic in `BeaverCollection` and `BeaversConfigurator` firmly establishes a binary state: a beaver is either an adult or a child. Adding a third life stage (e.g., "Elder") would require significant overriding of the collection logic, factory instantiation, and UI reporting.
* **Longevity Variability**: `BeaverLongevity` gives every beaver an `ExpectedLongevity` multiplier between `0.9` and `1.1` upon spawning. This introduces natural randomness to their lifespans so mass-spawned beavers don't all die on the exact same tick.
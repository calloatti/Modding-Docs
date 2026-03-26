# Timberborn.Bots

## Overview
The `Timberborn.Bots` module establishes the core definition, instantiation, and tracking mechanisms for mechanical citizens (Bots). It separates bots from organic beavers by providing specific template decorators, an independent factory for creation, and visual modifiers like constant illumination.

---

## Key Components

### 1. `Bot` & `BotSpec`
* **`BotSpec`**: An empty record acting as the blueprint identifier for bots. If an entity has this spec, the game treats it as a mechanical citizen.
* **`Bot`**: A lightweight component attached to bot entities. It implements `IDeadNeededComponent`, meaning the game's death system requires this component to remain on the entity even after it transitions into a "dead" state (e.g., broken down and waiting for salvage).

### 2. `BotFactory`
This singleton is responsible for spawning bots into the world.
* **Initialization**: During `Load()`, it fetches the `Blueprint` associated with the `BotSpec` via the `TemplateService` and uses `TemplateInstantiator.CacheInstance` to pre-load it for faster spawning.
* **Creation**: The `Create(Vector3 position)` method uses the `EntityService` to instantiate the blueprint. It importantly fetches the `Character` component and sets the `DayOfBirth` to the current `_dayNightCycle.DayNumber` before returning the `Bot` component.

### 3. `BotPopulation`
A tracking singleton that maintains a real-time list of all active bots on the map.
* **Event Listening**: It listens to the `EventBus` for `CharacterCreatedEvent` and `CharacterKilledEvent`. If the affected character has a `BotSpec`, it adds or removes them from its internal `_bots` list.
* **Historical Tracking**: It persists a boolean flag (`BotCreated`) to the save file via `ISaveableSingleton`. This flag permanently records if the player has *ever* built a bot in this settlement, which is useful for unlocking achievements or UI elements.

### 4. `BotIlluminationController` & `BotColors`
Bots in Timberborn emit a distinct glow.
* **`BotColors`**: Loads a specific color defined by `BotColorsSpec` (configured in JSON) and uses the `IlluminationService` to resolve it into a usable `Color` object.
* **`BotIlluminationController`**: Attached to every bot, this component runs during `Awake()` and uses the `MaterialColorer` to apply the `BotIlluminationColor` and enable lighting on the bot's 3D model.

### 5. `BotLongevity`
A simple component implementing the `ILongevity` interface specifically for bots. It hardcodes the `ExpectedLongevity` to `1f` (100%), as bots do not suffer from the same variable lifespan mechanics (like old age or wellbeing bonuses) as organic beavers.

---

## How to Use This in a Mod

### Spawning a Bot via C#
If you create an event mod or a custom building (like an advanced bot assembly line) that needs to spawn a bot, you inject the `BotFactory`:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Bots;
using UnityEngine;

public class CustomBotSpawner : BaseComponent
{
    private BotFactory _botFactory;

    [Inject]
    public void InjectDependencies(BotFactory botFactory)
    {
        _botFactory = botFactory;
    }

    public void SpawnBotAtDoor()
    {
        // Assuming 'transform.position' is the drop-off point
        Bot newBot = _botFactory.Create(this.Transform.position);
        Debug.Log("Spawned a new mechanical citizen!");
    }
}
```

### Checking if a Character is a Bot
If you are writing logic that affects beavers but should *not* affect bots (e.g., an infection or a specific food buff), check for the `Bot` component:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Bots;
using Timberborn.Characters;

public void ApplyCustomBuff(Character character)
{
    // Timberborn's BaseComponent system allows implicit boolean checks
    if (character.GetComponent<Bot>()) 
    {
        // It's a bot, ignore!
        return; 
    }
    
    // Apply organic buff here
}
```

---

## Modding Insights & Limitations

* **Single Template Restriction**: The `BotFactory` hardcodes its `_botTemplate` by searching for a single `BotSpec` during the `Load()` phase (`_templateService.GetSingle<BotSpec>().Blueprint`). This implies the game's architecture is currently designed around having exactly one type of bot blueprint. Modders attempting to add a *second* distinct species of bot (e.g., a flying drone with a different blueprint) cannot easily use the vanilla `BotFactory`, as `GetSingle()` will throw an exception if multiple specs exist.
* **Component Overlap**: Notice in `BotsConfigurator.ProvideTemplateModule()` that `BotSpec` is decorated with both the `Bot` component *and* the `Character` component. Bots are functionally a sub-category of Characters. They interact with all vanilla systems that expect a `Character` (like selection, naming, and basic movement) unless specifically filtered out.
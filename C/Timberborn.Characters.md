# Timberborn.Characters

## Overview
The `Timberborn.Characters` module forms the foundational layer for all individual agents (beavers and bots) in the game. It provides the base `Character` component that defines a living entity, manages the global population list, provides utilities for modifying character materials (colors/tints), and includes a performance safeguard that throttles the game simulation speed as the population grows.

---

## Key Components

### 1. `Character`
This is the root component attached to every beaver and bot.
* **State**: It tracks basic properties: `Alive`, `DayOfBirth`, and `Age` (calculated dynamically using `_dayNightCycle.DayNumber - DayOfBirth`).
* **Lifecycle Events**: It provides the `KillCharacter()` method. When called, it sets `Alive = false`, invokes the local `Died` event, and posts a global `CharacterKilledEvent` to the `EventBus`. It also provides `DestroyCharacter()`, which kills the character and then completely deletes the `GameObject` via the `EntityService`.
* **Persistence**: It saves and loads the character's grid `Position`, `Alive` state, and `DayOfBirth`.

### 2. `IChildhoodInfluenced`
This interface is a crucial part of Timberborn's growth mechanic.
* When a kit (child beaver) grows up, the game deletes the kit entity and spawns a new adult entity in its place.
* Components implementing `IChildhoodInfluenced` ensure seamless data transfer during this transition.
* For example, the `Character` component copies the `DayOfBirth` and the `FirstName` from the child to the new adult. `CharacterTint` copies any custom material colors.

### 3. Material & Visual Modifications
Because many identical characters exist on screen, Unity material instancing must be handled carefully to avoid memory bloat while still allowing individual customization.
* **`CharacterMaterialModifier`**: This component grabs the `Renderer` and provides wrapper methods (`SetColor`, `SetFloat`, `SetTexture`) that act directly on `_meshRenderer.material`. *Note: Accessing `.material` in Unity automatically creates a unique clone of the material for that specific object.* To prevent a memory leak, this component implements `IDeletableEntity` and explicitly calls `Object.Destroy(_meshRenderer.material)` when the beaver dies or is deleted.
* **`CharacterTint`**: Built on top of the material modifier, it exposes a simple `SetTint(Color)` method that maps to the `_TintColor` and `_TintEnabled` shader properties, likely used for faction colors, selection highlighting, or status effects.

### 4. Population & Performance Throttling
* **`CharacterPopulation`**: A simple, globally accessible singleton that maintains a `ReadOnlyList<Character>` by listening to `CharacterCreatedEvent` and `CharacterKilledEvent`.
* **`GameSpeedThrottler`**: An automated performance safeguard. 
    * It listens for any change in the population.
    * It reads `GameSpeedThrottlerSpec` to get limits like `MinPopulation`, `MaxPopulation`, `MaxGameSpeedScale`, and `MinGameSpeedScale`.
    * As the `NumberOfCharacters` increases toward `MaxPopulation`, it uses `Mathf.Lerp` to gradually lower the `_speedManager.ChangeSpeedScale(speedScale)`. This prevents the game from lagging uncontrollably at the highest fast-forward speeds when hundreds of beavers are calculating paths and jobs.

---

## How to Use This in a Mod

### Spawning a Custom Character
If your mod introduces a new event that spawns characters (e.g., a "Rescue Pod" building), you must remember to post the `CharacterCreatedEvent` so the population tracker and speed throttler recognize the new entity.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Characters;
using Timberborn.SingletonSystem;

public class RescuePod : BaseComponent
{
    private EventBus _eventBus;
    private EntityService _entityService;

    [Inject]
    public void InjectDependencies(EventBus eventBus, EntityService entityService)
    {
        _eventBus = eventBus;
        _entityService = entityService;
    }

    public void SpawnRescuedBeaver(BlockObjectSpec beaverSpec)
    {
        // Instantiate the prefab
        BaseComponent newBeaver = _entityService.Instantiate(beaverSpec, this.Transform.position);
        
        Character character = newBeaver.GetComponent<Character>();
        character.DayOfBirth = 1; // Or pull from current day
        
        // CRITICAL: Notify the game that a new character exists
        _eventBus.Post(new CharacterCreatedEvent(character));
    }
}
```

---

## Modding Insights & Limitations

* **No Automated Creation Event**: Notice that `Character.Awake()` or `Character.Start()` do *not* post the `CharacterCreatedEvent`. The spawning systems (like the Breeding Pod or Migration Center) are responsible for posting this event manually after fully initializing the prefab. If a modder spawns a character but forgets to post this event, the beaver will exist in the world but will not count towards the population total or the speed throttler.
* **Destructive Material Cloning**: As noted, `CharacterMaterialModifier` clones the material. Modders should be extremely careful not to spam `SetColor` or `SetTexture` every frame, as changing material properties on instantiated materials breaks Unity's dynamic batching, meaning 100 beavers on screen will result in 100 separate draw calls.
* **Throttler Scaling**: The `GameSpeedThrottler` uses standard linear interpolation (`Mathf.Lerp`) between the Min and Max population thresholds defined in the JSON spec. It does not use exponential decay or curves, meaning the fast-forward speed drop-off will feel very linear as the colony grows.
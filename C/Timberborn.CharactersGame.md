# Timberborn.CharactersGame

## Overview
The `Timberborn.CharactersGame` module is an extremely focused micro-module that handles sending on-screen notifications when a new character (e.g., a beaver kit) is born or constructed. It acts as a listener that waits for the entity to finish initializing and then posts a localized message to the global `NotificationBus`.

---

## Key Components

### 1. `CharacterBirthNotifier`
This component implements `IPostInitializableEntity`, allowing it to act immediately after the `EntityService` finishes creating the character and attaching all its components.
* **State Management**: It has a private `_notificationEnabled` flag. By default, this is false. It must be explicitly set to true via the `EnableNotification()` method.
* **Execution**: During `PostInitializeEntity()`, if the notification is enabled, it reads the `NotificationLocKey` from its spec, retrieves the character's newly generated name via `NamedEntity`, and posts a formatted string to the `NotificationBus`.

### 2. `CharacterBirthNotifierSpec`
The JSON representation required to attach the notifier.
* **`NotificationLocKey`**: A string pointing to the localization dictionary (e.g., `"Notification.BeaverBorn"` -> `"{0} has been born!"`).

---

## Architectural Insight: Why the `_notificationEnabled` flag?

You might wonder why `CharacterBirthNotifier` doesn't just send a notification every time `PostInitializeEntity()` fires. 

Timberborn has two ways characters enter the world:
1. **Natural Birth/Creation**: A kit is born in a lodge, or a bot is assembled in a factory. The player should be notified.
2. **Save Loading**: When a player loads a saved game, *every single beaver* is instantiated and goes through `PostInitializeEntity()`. If this component fired automatically, the player would receive 300+ "A beaver has been born" notifications the moment they load a late-game save.

By keeping `_notificationEnabled` false by default, the game ensures notifications only happen when the spawning structure (like the Breeding Pod or Assembly Plant) explicitly calls `EnableNotification()` on the newly instantiated prefab *before* it finishes initializing.

---

## How to Use This in a Mod

If you are creating a custom building that spawns characters (e.g., an alien cloning vat) and you want a UI notification to appear when a character pops out, you need to follow this pattern.

**1. Add the Spec to your Character's JSON:**
```json
{
  "CharacterBirthNotifierSpec": {
    "NotificationLocKey": "MyMod.Notification.CloneCreated"
  }
}
```

**2. Enable it during spawning:**
```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CharactersGame;
using Timberborn.EntitySystem;

public class CloningVat : BaseComponent
{
    private EntityService _entityService;
    private BlockObjectSpec _cloneSpec;

    [Inject]
    public void InjectDependencies(EntityService entityService)
    {
        _entityService = entityService;
    }

    public void SpawnClone()
    {
        // Instantiate the character prefab
        BaseComponent newClone = _entityService.Instantiate(_cloneSpec, this.Transform.position);
        
        // CRITICAL: Enable the notification before the entity finishes initializing
        CharacterBirthNotifier notifier = newClone.GetComponent<CharacterBirthNotifier>();
        if (notifier != null)
        {
            notifier.EnableNotification();
        }
    }
}
```

---

## Modding Insights & Limitations

* **Context Restriction**: The `CharactersGameConfigurator` is restricted to the `[Context("Game")]`. This means if a character is somehow spawned in the Map Editor, no notification component will be attached, preventing UI spam during map creation.
* **Single Message Format**: The `Post` method hardcodes the string formatting to pass exactly one parameter: `GetComponent<NamedEntity>().EntityName`. If a modder wants a localization string that includes multiple parameters (e.g., `"The clone {0} was born in {1}"`), they cannot use this vanilla component and must write their own custom notifier.
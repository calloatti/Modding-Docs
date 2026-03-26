# Timberborn.BonusSystem

## Overview
The `Timberborn.BonusSystem` module is responsible for managing dynamic multiplier modifiers (bonuses or penalties) applied to characters. It provides a centralized architecture to track, bound, and visually describe statistical modifiers using a data-driven configuration system. 

---

## Key Components

### 1. `BonusManager`
This is the core state component attached to entities to manage their active bonuses.
* **Attachment**: The `BonusSystemConfigurator` automatically attaches this component to any entity that has the `Character` component.
* **State Tracking**: During `Awake()`, it initializes a private dictionary (`_bonuses`) with a starting base value of `1.0f` for every single bonus ID registered in the game.
* **Modification**: Modders can manipulate these values using `AddBonus()` or `RemoveBonus()`, passing the `bonusId` and a `multiplierDelta`. Internally, it uses simple addition and subtraction (`_value += change`).
* **Clamping**: When the `Multiplier(string bonusType)` method is called to read the current value, it automatically clamps the output between the minimum and maximum boundaries defined for that specific bonus type.
* **Events**: It triggers a `BonusValueChanged` event whenever a bonus is added or removed.

### 2. Data Specifications
The system relies on JSON-configurable specs to define rules.
* **`BonusTypeSpec`**: Defines the universal rules for a specific bonus category. It holds the `Id`, a localized `DisplayName`, the `MinimumValue`, the `MaximumValue`, and an `Icon` asset reference.
* **`BonusSpec`**: A simple record used to apply a specific instance of a bonus. It pairs an `Id` with a `MultiplierDelta`.

### 3. `BonusTypeSpecService`
A singleton service that loads and caches all `BonusTypeSpec` definitions at the start of the game. It provides the `GetSpec(string bonusId)` method to safely retrieve the rules for any bonus.

### 4. `BonusDescriber`
A utility singleton used to generate human-readable UI strings for bonuses.
* **Formatting**: It automatically converts the float delta into a percentage string (e.g., `+10%` or `-5%`).
* **Color Coding**: It uses the `BonusDescriberColorsSpec` to wrap the strings in HTML color tags (`<color=#HEX>`) depending on whether the `multiplierDelta` is positive or negative.

---

## How to Use This in a Mod

### Creating a New Bonus Type
If you are creating a mod that adds a new status effect (like a "Caffeinated" speed boost), you must first define the bonus type in JSON:

```json
{
  "BonusTypeSpec": {
    "Id": "MyMod.MovementSpeed",
    "LocKey": "Bonus.MyMod.MovementSpeed",
    "MinimumValue": 0.5,
    "MaximumValue": 2.0,
    "Icon": "Sprites/Bonuses/MySpeedIcon"
  }
}
```

### Applying the Bonus via C#
To apply an active bonus to a beaver, you fetch the `BonusManager` and pass the ID you created:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.BonusSystem;
using Timberborn.Characters;

public class CoffeeBuffEffect : BaseComponent
{
    private BonusManager _bonusManager;

    public void Awake()
    {
        // This is safe because BonusManager is natively attached to all Characters
        _bonusManager = GetComponent<BonusManager>();
    }

    public void ApplyCoffeeBuff()
    {
        // Adds a 25% boost to the base multiplier
        _bonusManager.AddBonus("MyMod.MovementSpeed", 0.25f);
    }

    public void RemoveCoffeeBuff()
    {
        // Remember to clean up your bonuses!
        _bonusManager.RemoveBonus("MyMod.MovementSpeed", 0.25f);
    }
}
```

### Reading the Bonus
Other systems can then check this value to alter their logic:
```csharp
float speedMultiplier = _bonusManager.Multiplier("MyMod.MovementSpeed");
```

---

## Modding Insights & Limitations

* **Character Exclusive**: By default, the `BonusSystemConfigurator` only decorates `Character` entities with the `BonusManager`. If you want buildings to have trackable multiplier bonuses, you will need to add the `BonusManager` to your building templates manually or via your own configurator.
* **Global Initialization**: The `BonusManager` iterates through *all* `_bonusTypeSpecService.BonusIds` during `Awake()` and initializes a tracking object for every single bonus type in the game. If a mod adds hundreds of custom bonus types, every single beaver will allocate tracking memory for all of them upon spawning.
* **Additive Nature**: Despite the `MultiplierDelta` name, the underlying math in the `Bonus` class is strictly additive (`_value += change`). If a beaver has two +10% bonuses, the total multiplier becomes `1.2` (1.0 + 0.1 + 0.1), not `1.21` (1.0 * 1.1 * 1.1).
* **Strict IDs**: `BonusTypeSpecService.GetSpec` will throw an `InvalidOperationException` if you attempt to look up a bonus ID that has not been defined in a loaded JSON spec. Always ensure your data files are loaded correctly before your C# code executes.
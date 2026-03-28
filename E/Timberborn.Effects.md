# Timberborn.Effects

## Overview
The `Timberborn.Effects` module defines the core data structures and formatting tools used to represent how various activities, buildings, and consumed goods impact the "Needs" (wellbeing) of beavers and bots. This module serves as the bridge between gameplay actions (like sleeping or eating) and the resulting statistical buffs.

---

## Key Components

### 1. Data Structures
These structs define the mathematical impact an effect has on a specific need.
* **`ContinuousEffect`**: Represents an effect applied over time, typically while a beaver is inside a building (e.g., sleeping in a Lodge). 
    * Stores the `NeedId` (e.g., "Comfort") and the `PointsPerHour` rate at which the need is fulfilled.
* **`InstantEffect`**: Represents a burst effect, typically applied when consuming a good or finishing an activity (e.g., drinking water or using a shower).
    * Stores the `NeedId`, the `Points` awarded per tick, and the `Count` of how many times those points should be applied.
    * Provides a `DiscretizeContinuousEffect` utility method that converts a continuous effect into a standard chunked format (`0.05f` points applied `20` times).
* **`Effect`**: A simplified struct derived from `InstantEffect` that strips the `NeedId`, used when calculating raw numerical impacts without needing context on the specific need.

### 2. Serialization (`ContinuousEffectValueSerializer`)
Because `ContinuousEffect` data must be persisted in save files, this class handles the serialization.
* It safely loads the `NeedId` and `PointsPerHour`.
* **Safety Check**: During deserialization, it verifies that the saved `NeedId` still exists in the game's `FactionNeedService`. If a mod that added a custom need was removed, the game will safely ignore the missing need rather than crashing, logging a warning to the debug console.

### 3. UI Describers
These classes convert abstract effect data into human-readable text for tooltips and UI panels.
* **`EffectDescriber`**: Takes an `IEnumerable` of `InstantEffectSpec` or `ContinuousEffectSpec` and formats them into a string using the `NeedSpecFormatter`. It appends a bullet point (`SpecialStrings.RowStarter`) before each formatted need.
* **`GoodEffectDescriber`**: Specifically designed to describe the effects of consuming a good (e.g., eating Carrots). It looks up the `GoodSpec`, extracts its `ConsumptionEffects`, and formats them. It provides methods to return the description with or without the standard item header.

---

## How to Use This in a Mod

### Adding Custom Effects
You rarely need to instantiate these structs manually via C#. Instead, you define them in your JSON specification files. The game parses those specs into the `ContinuousEffectSpec` and `InstantEffectSpec` objects, which these tools then read.

*Example of a JSON definition that this module parses:*
```json
"NeedEffects": {
  "SleepEffects": [
    {
      "NeedId": "Sleep",
      "PointsPerHour": 50.0
    }
  ]
}
```

### Displaying Custom Effects in UI
If you create a custom UI panel that needs to show the effects of a building, you should inject the `EffectDescriber`:

```csharp
using System.Text;
using Timberborn.Effects;
using Timberborn.NeedSpecs;
using System.Collections.Generic;

public class MyCustomPanel {
    private readonly EffectDescriber _effectDescriber;
    private readonly StringBuilder _stringBuilder = new StringBuilder();

    public MyCustomPanel(EffectDescriber effectDescriber) {
        _effectDescriber = effectDescriber;
    }

    public string GetTooltip(IEnumerable<ContinuousEffectSpec> effects) {
        _stringBuilder.Clear();
        _effectDescriber.DescribeEffects(effects, _stringBuilder);
        return _stringBuilder.ToString();
    }
}
```

---

## Related dlls
* **Timberborn.NeedSpecs**: Contains the base definitions (`NeedSpec`, `ContinuousEffectSpec`, `InstantEffectSpec`) that these runtime structs are built from.
* **Timberborn.GameFactionSystem**: Provides the `FactionNeedService`, which maintains the registry of all valid Needs in the game (used for serialization safety checks).
* **Timberborn.Goods**: Supplies the `GoodSpec` definitions read by the `GoodEffectDescriber`.
* **Timberborn.Persistence**: Defines the `IValueSerializer` interface used for save data handling.
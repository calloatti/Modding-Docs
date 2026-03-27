# Timberborn.CharacterMovementSystemUI

## Overview
The `Timberborn.CharacterMovementSystemUI` module is an extremely small presentation layer that accompanies the `Timberborn.CharacterMovementSystem`. Its sole responsibility is to display the movement speed bonus provided by specific buildings (like Roads or Paths) in the entity selection panel when the player clicks on them.

---

## Key Components

### 1. `MovementSpeedBoostingBuildingDescriber`
This component implements `IEntityDescriber`, which allows it to inject formatted text into the standard Entity Panel.
* **Entity Binding**: It requires the entity to have a `MovementSpeedBoostingBuildingSpec` attached, which it retrieves during `Awake()`.
* **Description Generation**: When `DescribeEntity()` is called by the UI system, it retrieves the `BoostPercentage` from the spec, localizes the string `"Bonus.MovementSpeed"`, and formats it as `"+X%"`. It returns this text prepended with a `SpecialStrings.RowStarter` (typically a bullet point or specific UI indentation).

### 2. `CharacterMovementSystemUIConfigurator`
A standard Bindito configurator running in the `[Context("Game")]`.
* **Template Decoration**: It automatically decorates any entity that has a `MovementSpeedBoostingBuildingSpec` with the `MovementSpeedBoostingBuildingDescriber`. This means modders simply add the JSON spec, and the UI text handles itself.

---

## How to Use This in a Mod

If you are creating a custom path, bridge, or moving walkway that speeds up beavers, you do not need to interact with this C# code directly. You only need to add the correct spec to your building's JSON template.

```json
{
  "MovementSpeedBoostingBuildingSpec": {
    "BoostPercentage": 25
  }
}
```

The configurator will automatically attach the describer, and when the player clicks your custom bridge, the Entity Panel will display something like:
`• Movement Speed: +25%`

---

## Modding Insights & Limitations

* **Hardcoded Formatting**: The string format `"+{_movementSpeedBoostingBuildingSpec.BoostPercentage}%"` is hardcoded in the C# file. It assumes that the boost will always be a positive percentage. 
* **Negative Values**: If a modder attempts to create a "Mud Path" that slows beavers down by providing a negative `BoostPercentage` (e.g., `-10`), the UI will awkwardly format it as `Movement Speed: +-10%`.
* **No Map Editor Support**: Like other dynamic gameplay UI elements, this configurator is excluded from the `MapEditor` context, meaning building stats won't display if the player clicks a path while creating a custom map.
# Timberborn.BotsUpkeep

## Overview
The `Timberborn.BotsUpkeep` module contains the logic and visual controllers for the "Bot Manufactory" building—the structure responsible for constructing new mechanical citizens during standard gameplay. It hooks into the game's existing workshop and production systems to trigger the physical spawning of a bot when a manufacturing cycle completes.

---

## Key Components

### 1. `BotManufactory`
This component bridges the generic manufacturing process with the specific action of spawning a bot.
* **Event Hook**: During `Start()`, it subscribes to the `ProductionFinished` event of the `Manufactory` component.
* **Spawning Logic**: When production finishes, it asks the `BotFactory` to create a new bot.
* **Positioning**: The spawn position is calculated using `_buildingAccessible.CalculateAccessFromLocalAccess()`, ensuring the bot spawns at the correct doorway. The initial rotation is explicitly set to match the building's `_enterable.ExitWorldSpaceRotation` so the bot walks out facing the right way.
* **District Assignment**: It automatically assigns the newly born bot to the same `DistrictCenter` that the Manufactory belongs to (`bot.GetComponent<Citizen>().AssignInitialDistrict(district)`).
* **Notifications**: It enables the `CharacterBirthNotifier` on the new bot (to trigger UI alerts) and posts a global `BotManufacturedEvent` to the `EventBus`.

### 2. `BotManufactoryAnimationController`
This component manages the complex, multi-stage visual animation of the manufactory building. It is highly data-driven via the `BotManufactoryAnimationControllerSpec`.
* **State Listening**: It enables or disables its `Update()` loop based on the `WorkshopStateChanged` event (`e.CurrentlyProducing`).
* **Two-Stage Animation**:
    * **Ring Rotation**: It uses an `IRandomNumberGenerator` to pick a random target angle between 90 and 270 degrees, and a random direction (clockwise/counter-clockwise). The `UpdateRingRotation()` method rotates the transform defined by `RingName` until this target is met.
    * **Assembling Phase**: Once the ring is in position, it transitions to the assembling phase (`_remainingAssemblyDuration`). During this phase, it rotates the transform defined by `DrillName`, enables particle emissions via `ParticlesRunner`, and turns on a specific `Light` attachment.
* **Speed Scaling**: All animation speeds (`DrillRotationSpeed`, `RingRotationSpeed`) are multiplied by `_nonlinearAnimationManager.SpeedMultiplier` so the visual speed matches the player's current game speed setting.

---

## How to Use This in a Mod

### Creating a Custom Bot Factory
If you are creating a custom building that acts as a secondary way to manufacture bots (like a smaller, slower version of the vanilla manufactory), you can easily utilize this module without writing C# code. You only need to include the proper specs in your building's JSON file.

You must ensure your prefab has the following standard crafting components configured correctly, alongside the `BotManufactorySpec`:

```json
{
  "BotManufactorySpec": {},
  "ManufactorySpec": {
    // Defines how long it takes and what it outputs.
    // The BotManufactory component listens to this process.
  },
  "RecipeConsumerSpec": {
    // Defines what goods (e.g., gears, metal) are required
  }
}
```

Because `BotUpkeepConfigurator` decorates `BotManufactorySpec` with the `BotManufactory` component, your building will automatically spawn bots when `Manufactory.ProductionFinished` fires.

---

## Modding Insights & Limitations

* **Hardcoded Output Hook**: The `BotManufactory` strictly listens to the `Manufactory.ProductionFinished` event. It does not check *what* was produced. If a modder creates a manufactory that produces both bots *and* a physical good (like scrap metal) via multiple recipes, a bot will spawn every single time *any* production finishes.
* **Animation Transform Names**: The `BotManufactoryAnimationController` uses `GameObject.FindChildTransform()` to locate the moving parts based on strings defined in the spec (`RingName`, `DrillName`). Modders must ensure their Unity prefabs have child objects with exact matching names if they intend to use this animation controller.
* **Light Discovery**: The controller's logic for finding the assembling light (`GetLightAttachment`) is highly specific. It iterates through `AttachmentIds` defined in the spec, fetches the attachment, and uses `GetComponentInChildren<Light>(includeInactive: true)`. It only stores the *first* light it finds. If your building has multiple lights that need to turn on during assembly, you will need to write a custom animation controller.
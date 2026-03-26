# Timberborn.BotsUI

## Overview
The `Timberborn.BotsUI` module is the user interface and presentation layer specifically for mechanical citizens (Bots). It provides the visual and auditory feedback players experience when interacting with bots, including custom selection sounds, entity panel badges, and a developer-mode tool for spawning bots directly into the world.

---

## Key Components

### 1. `BotEntityBadge`
This component implements the `IEntityBadge` interface to customize how bots appear in the entity selection panel when clicked by the player.
* **Attachment**: The `BotsUIConfigurator` automatically decorates any entity possessing a `BotSpec` with this component.
* **Avatar**: It overrides the default avatar by fetching the `BotAvatar` defined by the currently active faction via the `FactionService`.
* **Subtitle Logic**: It formats the subtitle to display the bot's "Age". If the bot's `Character` component indicates it is no longer alive, it appends a localized "DeadNameSuffix" to the age string.
* **Clickable District Link**: If the bot is assigned to a district (`_citizen.HasAssignedDistrict`), it creates a `ClickableSubtitle` showing the `DistrictName`. Clicking this subtitle uses the `EntitySelectionService` to refocus the camera and select the `DistrictCenter`.

### 2. `BotSelectionSound`
A custom audio component that plays specific voice lines or mechanical noises when a player selects a bot.
* **Implementation**: It implements `ISelectionListener` and triggers the `PlaySound()` method during `OnSelect()`.
* **State-Based Audio**: The sound played depends on the bot's current status. 
    * If the bot's `StatusSubject` has zero active statuses (i.e., no warning icons floating above its head), it plays the `"Content"` variant of the sound.
    * If there is *any* active status (e.g., out of fuel, broken), it plays the `"Discontent"` variant.
* **Dead Check**: It explicitly checks the `Mortal` component and aborts playback if the bot is dead.

### 3. `BotGeneratorTool` & `BotGeneratorButton`
These classes provide a developer-only debugging tool to spawn bots instantly using the mouse cursor.
* **Tool Logic**: The `BotGeneratorTool` implements `ITool`, `IInputProcessor`, and `IDevModeTool`. When active, clicking the main mouse button over a valid grid coordinate uses the `BotFactory` to instantly instantiate a bot. If the player holds down a specific binding key (`SpawnManyCharacters`), it spawns 10 bots at once.
* **UI Injection**: The `BotGeneratorButton` implements `IBottomBarElementsProvider` and uses `ToolButtonFactory.CreateGrouplessRed()` to create the UI button. The configurator injects this button into the left section of the `BottomBarModule`. Because the tool implements `IDevModeTool`, the game engine automatically hides this button from standard players unless Dev Mode is active.

---

## How to Use This in a Mod

### Adding Custom Selection Sounds to New Bots
If you create a mod that introduces a completely new type of bot (e.g., a flying drone) and want it to have unique selection noises, you do not need to write a new C# class. You simply add the `BotSelectionSoundSpec` to your prefab's JSON file:

```json
{
  "BotSelectionSoundSpec": {
    "SoundNameKey": "MyDrone"
  }
}
```

You must then ensure that your mod's audio asset bundles contain files that match the exact naming convention expected by `BotSelectionSound.PlaySound()`:
* `UI.Bots.Selected.MyDrone_Content`
* `UI.Bots.Selected.MyDrone_Discontent`

The `BotsUIConfigurator` will automatically detect the spec and attach the `BotSelectionSound` logic to your entity.

---

## Modding Insights & Limitations

* **Hardcoded Sound Paths**: The `BotSelectionSound` class hardcodes the prefix `"UI.Bots.Selected."` and the suffixes `"_Content"` and `"_Discontent"`. Modders cannot customize this path structure via JSON; they must conform their FMOD/audio event names to this exact string format.
* **Strict "Discontent" Definition**: The logic for determining if a bot plays a "Discontent" sound is extremely broad: `if (_statusSubject.ActiveStatuses.Count <= 0)`. *Any* active status—even a positive buff if a modder were to implement one using the Status System—will cause the bot to play its negative/discontent voice line.
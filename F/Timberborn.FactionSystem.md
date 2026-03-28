# Timberborn.FactionSystem

## Overview
The `Timberborn.FactionSystem` module defines the data structures and services required to manage playable factions in the game (such as Folktails and Iron Teeth). It dictates how faction data is loaded from JSON specifications, how faction-specific assets are referenced, and handles the persistent meta-progression of unlocking new factions across playthroughs.

---

## Key Components

### 1. `FactionSpec`
This record class serves as the master blueprint for a faction, containing all the data parsed from the faction's JSON file.
* **Identity**: `Id`, `Order`, `DisplayName`, and `Description`.
* **Visuals**: References to UI sprites (`Avatar`, `Logo`, `BotAvatar`, etc.) and 3D materials (`PathMaterial`, `BaseWoodMaterial`, `Textures`) used to style the faction's buildings and characters.
* **Gameplay Definers**: 
    * `StartingBuildingId`: The District Center prefab spawned at the start of the game.
    * `BlueprintModifiers`: Defines which buildings are swapped or restricted for this faction.
    * `NeedCollectionIds` / `GoodCollectionIds`: Defines the specific needs and items available to this faction.
* **Endgame**: Localization keys for `GameOverMessage` and `GameOverFlavor`.

### 2. `UnlockableFactionSpec` & `StartingFactionSpec`
These are sub-components attached to a `FactionSpec` in the JSON file to define their availability.
* **`StartingFactionSpec`**: A simple marker component indicating the faction is unlocked by default (e.g., Folktails).
* **`UnlockableFactionSpec`**: Indicates the faction must be earned. It requires a `PrerequisiteFaction` string (the ID of the faction the player must play as) and an `AverageWellbeingToUnlock` integer.

### 3. `FactionUnlockingService`
This service handles the meta-progression of locked factions.
* **Persistence**: It saves the unlocked status directly to the player's global profile using `_playerDataService.SetBool(ComposeFactionUnlockKey(factionSpec.Id), true)`. This means unlocking a faction in one save file makes it available for all future new games.
* **Event Broadcasting**: When `UnlockFaction()` is called, it posts a `FactionUnlockedEvent` to the `EventBus`, allowing UI or achievement systems to react instantly.

### 4. `FactionSpecService`
A loadable singleton that acts as the central registry for all available factions.
* It uses the `ISpecService` to load all `FactionSpec` objects into an immutable array (`Factions`) during startup.
* It provides helper methods to easily query a specific faction by ID or to retrieve an `IEnumerable` of all factions that require unlocking (`UnlockableFactions`).

---

## How to Use This in a Mod

### Creating a Custom Faction
To add a new faction to the game, you must create a JSON file that defines the `FactionSpec`. If you want players to unlock your faction by playing as the Iron Teeth and reaching 25 wellbeing, you would include the `UnlockableFactionSpec`.

*Example JSON structure:*

    "FactionSpec": {
        "Id": "MyModFaction",
        "Order": 3,
        "DisplayNameLocKey": "Factions.MyModFaction.Name",
        "DescriptionLocKey": "Factions.MyModFaction.Description",
        "StartingBuildingId": "DistrictCenterMyModFaction",
        "BlueprintModifiers": [ ... ]
    },
    "UnlockableFactionSpec": {
        "PrerequisiteFaction": "IronTeeth",
        "AverageWellbeingToUnlock": 25
    }

### Checking if a Custom Faction is Unlocked
If you are writing custom UI or logic and need to know if the player has unlocked your faction yet, you can inject the `FactionUnlockingService`.

    using Timberborn.FactionSystem;
    
    public class MyFactionChecker {
        private readonly FactionUnlockingService _unlockingService;
        private readonly FactionSpecService _specService;

        public MyFactionChecker(FactionUnlockingService unlockingService, FactionSpecService specService) {
            _unlockingService = unlockingService;
            _specService = specService;
        }

        public bool CanPlayMyFaction() {
            FactionSpec myFaction = _specService.GetFaction("MyModFaction");
            return !_unlockingService.IsLocked(myFaction);
        }
    }

---

## Modding Insights & Limitations

* **Hardcoded Unlock Logic**: The `UnlockableFactionSpec` only supports unlocking via Wellbeing achieved by a specific prerequisite faction. The actual check for this happens in the `Timberborn.FactionGoalsSystem` module. If you want a faction to unlock via a different method (e.g., gathering 10,000 berries), you must manually call `_factionUnlockingService.UnlockFaction()` from your own custom C# tick loop.
* **Global Data Dependency**: The `FactionUnlockingService` relies entirely on `IPlayerDataService`. If a player clears their global player data (e.g., deleting settings/profile data outside of save files), their unlocked factions will reset to locked.

---

## Related DLLs
* **Timberborn.BlueprintSystem**: Provides the `ComponentSpec`, `ISpecService`, and serialization attributes required to load the faction JSON files.
* **Timberborn.PlayerDataSystem**: Provides the `IPlayerDataService` used to persist the unlock state globally across all save files.
* **Timberborn.SingletonSystem**: Supplies the `ILoadableSingleton` interface and the `EventBus` used to broadcast `FactionUnlockedEvent`.
* **Timberborn.FactionGoalsSystem**: The external module that actively reads the `UnlockableFactionSpec` during gameplay to determine when to trigger the unlock.
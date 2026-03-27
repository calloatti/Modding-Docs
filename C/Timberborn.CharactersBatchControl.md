# Timberborn.CharactersBatchControl

## Overview
The `Timberborn.CharactersBatchControl` module is responsible for populating and managing the "Population" tab within the game's Batch Control window (the global list view where players can see all their beavers and bots). It groups characters into logical categories (Adults, Children, Bots, Contaminated) and provides rows containing their status, assigned workplaces, and housing.

---

## Key Components

### 1. `CharacterBatchControlTab`
This class implements the `BatchControlTab` and manages the high-level grouping and lifecycle of the character list.
* **Initialization**: It sets the `TabNameLocKey` to `"BatchControl.Population"` and the `TabImage` to `"Characters"`.
* **Grouping Logic**: `GetGroupingKey` determines which list a character belongs to. 
    * First, it checks if the character has a `Contaminable` component that `IsContaminated`. If true, they are grouped under `"Beaver.Population.Contaminated"`.
    * Otherwise, it reads the `EntityNameLocKey` from the `SimpleLabeledEntitySpec` (which returns keys like `"Beaver.Adult.TemplateName"` or `"Bot.TemplateName"`).
* **Sorting Logic**: `GetSortingKey` forces the groups to appear in a specific visual order in the UI:
    1. Adults (`"1"`)
    2. Children (`"2"`)
    3. Contaminated (`"3"`)
    4. Bots (`"4"`)
* **Dynamic Updates**: It listens to `EntityInitializedEvent`, `EntityDeletedEvent`, and `ContaminableContaminationChangedEvent`. If a beaver gets contaminated while the Batch Control window is open, `OnContaminableContaminationChangedEvent` intercepts it, removes the beaver's row from the "Adult" group, and schedules it to be recreated in the "Contaminated" group.
* **Optimization**: To prevent performance lag, it checks `_isTabVisible`. If the batch control window is open but the player is looking at the "Buildings" tab instead of the "Population" tab, it doesn't immediately build the visual rows for new characters; instead, it stores them in `_entitiesScheduledToAdd` and builds them only when the player clicks the Population tab (`Show()`).

### 2. `CharacterBatchControlRowFactory`
This factory is responsible for assembling the individual data columns for a single character's row in the list.
* It loads the `Game/BatchControl/BatchControlRow` visual element.
* It delegates the creation of specific data cells to specialized factories (which exist in other UI modules):
    * `CharacterBatchControlRowItemFactory`: Basic character info (name/icon).
    * `BeaverBuildingsBatchControlRowItemFactory`: Assigned workplace and housing.
    * `DeteriorableBatchControlRowItemFactory`: Health/durability.
    * `AdulthoodBatchControlRowItemFactory`: Growth progress for kits.
    * `WellbeingBatchControlRowItemFactory`: Happiness/well-being score.
    * `StatusBatchControlRowItemFactory`: Current status icons (thirsty, hungry, etc.).

### 3. `CharactersBatchControlConfigurator`
A standard configurator that registers the tab with the `BatchControlModule`. 
* It uses `builder.AddTab(_characterBatchControlTab, 1)` to place the Population tab at index `1` (second from the left, usually right after the Buildings tab) in the UI window.

---

## How to Use This in a Mod

### Adding a Custom Character Group
If your mod introduces a new type of character (e.g., a "Mutant" beaver or a "SuperBot"), and you give them a custom `SimpleLabeledEntitySpec` in your JSON, they will automatically be grouped in this tab based on their localization key.

However, because `GetSortingKey` is hardcoded to throw an exception for unknown keys, a custom entity name key will currently crash the game when the tab tries to sort it. 

```json
{
  "SimpleLabeledEntitySpec": {
    "EntityNameLocKey": "MyMod.SuperBot.TemplateName" // <--- This will cause a crash in vanilla Timberborn
  }
}
```

To fix this, modders must use a Harmony patch to intercept `GetSortingKey` and provide a sorting string (like `"5"`) for their custom localization key.

```csharp
using HarmonyLib;
using Timberborn.CharactersBatchControl;

[HarmonyPatch(typeof(CharacterBatchControlTab), "GetSortingKey")]
public static class CustomSortingKeyPatch
{
    public static bool Prefix(string locKey, ref string __result)
    {
        if (locKey == "MyMod.SuperBot.TemplateName")
        {
            __result = "5"; // Place it at the bottom of the list
            return false; // Skip the vanilla method so it doesn't throw the ArgumentOutOfRangeException
        }
        return true; // Let vanilla handle the rest
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Sorting Keys**: As noted above, `GetSortingKey` uses a hardcoded `throw new ArgumentOutOfRangeException` if it encounters a `locKey` it doesn't recognize. This is highly restrictive for modders trying to add custom character factions or species without Harmony patching.
* **Hardcoded Contamination Override**: The `GetGroupingKey` method explicitly checks for `Contaminable.IsContaminated` and overrides the group to `"Beaver.Population.Contaminated"`. If a modder creates a new status effect (e.g., "Zombified" or "Broken Down"), they cannot easily separate those characters into a new group without Harmony patching both `GetGroupingKey` and the event listener that triggers the UI refresh.
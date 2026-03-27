# Timberborn.CarryingUI

## Overview
The `Timberborn.CarryingUI` module is a tiny presentation layer that bridges the physical carrying logic (`Timberborn.Carrying`) with the game's UI. Its sole responsibility is to render the "Carrying: X/Y kg" text block inside the Entity Panel when the player clicks on a beaver, bot, or other `GoodCarrier` entity.

---

## Key Components

### 1. `GoodCarrierFragment`
This class implements the `IEntityPanelFragment` interface, injecting a UI element into the bottom of the selected entity's panel.

* **Initialization**: During `InitializeFragment()`, it loads the `Game/EntityPanel/GoodCarrierFragment` UXML file and caches the `Label` named "GoodCarrierFragment".
* **Entity Binding**: When the player clicks an entity, `ShowFragment()` tries to fetch the `GoodCarrier` and `Contaminable` components.
* **Update Logic**: `UpdateFragment()` runs every frame the panel is open:
    * If the entity has no `GoodCarrier`, it does nothing.
    * **If Carrying Items**: It retrieves the `CarriedGoods` and the agent's current `LiftingCapacity`. It calculates the total weight (`carriedGoods.Amount * weight`) and formats the string using localization keys (e.g., "Carrying: 5 Logs (15/20 kg)").
    * **If Contaminated**: If the agent's hands are empty *but* they are currently "Contaminated" (e.g., covered in toxic waste), the fragment hides itself entirely (`_root.ToggleDisplayStyle(visible: false)`). This prevents the UI from awkwardly saying "Carrying: Nothing (0/20 kg)" while the beaver is actively suffering a status effect.
    * **If Empty**: If not contaminated and not carrying anything, it displays the fallback text "Carrying: Nothing (0/20 kg)".

### 2. `CarryingUIConfigurator`
A Bindito configurator that operates strictly within the `[Context("Game")]`. 
* It uses `EntityPanelModuleProvider` to register the `GoodCarrierFragment`.
* It specifically uses `builder.AddBottomFragment(_goodCarrierFragment)` to ensure this text appears near the bottom of the character's info panel, below their portrait, name, and primary job actions.

---

## How to Use This in a Mod

Because this UI module is completely automated, modders do not need to interact with it directly. If you create a custom character (like a modded hauler drone) and attach the `GoodCarrierSpec` in your JSON, this UI text will automatically appear in their selection panel.

### Hiding the Carry UI for Custom Statuses
If your mod introduces a new status effect where you want to hide the "Carrying: Nothing" text (similar to how vanilla hides it when the beaver is contaminated), you will face limitations.

The `GoodCarrierFragment` hardcodes the check for `_contaminable.IsContaminated`. There is no generic `IHideCarryUI` interface you can implement on your custom status effect to trigger this behavior. If you want your custom "Frozen" or "Stunned" status to hide the carrying UI, you would have to patch this class using Harmony to intercept `UpdateFragment()`.

---

## Modding Insights & Limitations

* **Hardcoded UI Path**: The fragment strictly looks for the `Game/EntityPanel/GoodCarrierFragment` visual element. If a modder attempts to completely replace the vanilla UI by deleting or renaming this UXML file, the game will throw a `NullReferenceException` when the player clicks a beaver.
* **No Map Editor Context**: The `CarryingUIConfigurator` lacks the `[Context("MapEditor")]` attribute. This is an optimization, as beavers and carry logic are completely suspended during map creation, meaning there is no need to load or process these UI fragments while designing a map.
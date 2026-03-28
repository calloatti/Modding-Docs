# Timberborn.FactionValidators

## Overview
The `Timberborn.FactionValidators` module is a defensive initialization system that runs during the loading phase of the game (MainMenu, Game, and MapEditor). It validates the JSON data defined in a `FactionSpec` to ensure that all referenced asset collections (like templates, goods, and materials) actually exist in the game's loaded specifications.

---

## Key Components

### 1. `FactionSpecValidationService`
This singleton service acts as the central executor for all validation logic.
* **Execution Window**: It implements `ILoadableSingleton`, meaning its `Load()` method is called early in the context startup sequence.
* **Modding Bypass**: The most critical aspect of this service is that it checks `ModdedState.IsModded`. If the game is modded, the service immediately returns without running any validations. This prevents the game from hard-crashing if a mod author makes a typo or leaves a placeholder string in their custom faction JSON.
* **Validation Loop**: If the game is vanilla, it loops through every `FactionSpec` loaded by the `FactionSpecService` and runs it through an `IEnumerable` of injected `IFactionSpecValidator` classes. If any validator returns false, it throws a hard `Exception` halting the load process.

### 2. The Validators (`IFactionSpecValidator`)
These classes perform the specific string-matching checks against the loaded JSON specifications. They all follow the same pattern: they grab an array of string IDs from the `FactionSpec` and verify that a corresponding `ComponentSpec` was successfully loaded by the `ISpecService`.

* **`FactionSpecGoodsValidator`**: Checks the `GoodCollectionIds` against all loaded `GoodCollectionSpec` definitions.
* **`FactionSpecMaterialsValidator`**: Checks the `MaterialCollectionIds` against all loaded `MaterialCollectionSpec` definitions.
* **`FactionSpecNeedsValidator`**: Checks the `NeedCollectionIds` against all loaded `NeedCollectionSpec` definitions.
* **`FactionSpecTemplateValidator`**: Checks the `TemplateCollectionIds` against all loaded `TemplateCollectionSpec` definitions.

---

## Modding Insights & Limitations

* **Disabled for Mods**: As mentioned above, the entire validation suite is disabled if the game detects any mods (`!ModdedState.IsModded`). While this prevents mod-induced crashes during the initial load screen, it means modders will *not* receive helpful error messages if they misspell a `GoodCollectionId` in their custom faction JSON. If a modder makes an error, the game might crash later during play or quietly fail to load certain assets, making debugging more difficult.
* **Internal Scope**: All validator implementations and the `IFactionSpecValidator` interface itself are marked as `internal`. Modders cannot inject custom validators into this specific pipeline using `MultiBind`.

---

## Related DLLs

* **Timberborn.FactionSystem**: Provides the `FactionSpec` definitions being validated.
* **Timberborn.BlueprintSystem**: Provides the `ISpecService` used to fetch the collection definitions.
* **Timberborn.GoodCollectionSystem**, **Timberborn.NeedCollectionSystem**, **Timberborn.TemplateCollectionSystem**, **Timberborn.TimbermeshMaterials**: The various modules that provide the specific Collection Specs being cross-referenced.
* **Timberborn.Modding**: Supplies the `ModdedState.IsModded` flag used to bypass validation.
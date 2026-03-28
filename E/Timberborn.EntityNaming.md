# Timberborn.EntityNaming

## Overview
The `Timberborn.EntityNaming` module governs how individual entities (like beavers, buildings, and districts) are named in the game. It supports fixed string labels, automatically incrementing numbered names (e.g., "Log Pile 1", "Log Pile 2"), and custom player-edited names. It also provides a registry system to verify if a name is unique across the map.

---

## Key Components

### 1. `NamedEntity`
This is the core component attached to any entity that possesses a distinct name.
* **Initialization**: Upon creation, if the entity does not have a saved name, it asks its attached `IEntityNamer` components to generate one. It uses the `IEntityNamer` with the highest `EntityNamerPriority`.
* **Persistence**: If `NamedEntitySpec.IsEditable` is true (meaning the player can rename it), it saves and loads the custom name (`EntityNameKey`) to the save file.
* **Sorting**: Provides a `NamedEntitySortingKey` that modifies the name to make it alphabetically sortable (e.g., zero-padding numbers using a regex so "Log Pile 2" sorts before "Log Pile 10").
* **Synchronization**: The `NamedEntityGameObjectSynchronizer` ensures that the internal Unity `GameObject.name` matches the `NamedEntity` name, making debugging in the Unity Hierarchy easier.

### 2. Entity Namers
Entities use one or more `IEntityNamer` implementations to generate their default names.
* **`LabeledEntityNamer`**: Simply returns the static `DisplayName` from the `LabeledEntity` component. It has a baseline priority of `0`.
* **`NumberedEntityNamer`**: Generates a name with an appended number (Priority `10`).
* **Inferred Generation**: By default, it searches the map for all other entities in its `NumberingGroup` (usually the `TemplateName`), finds the highest number, and adds 1. This is useful for things that might be deleted and replaced.
* **Persistent Generation**: If `IsPersistent` is true, it uses the global `NumberedEntityNamerService` to fetch a guaranteed unique, continuously incrementing number.

### 3. Unique Naming (`UniquelyNamedEntity`)
Certain entities (like District Centers) require globally unique names.
* **`UniquelyNamedEntityService`**: A global dictionary that tracks all registered names.
* **Conflict Handling**: When a new `UniquelyNamedEntity` is registered, the service checks if the name already exists. If a conflict occurs, it sets the `IsUnique` flag to `false` on *all* entities sharing that name. When the conflict is resolved (e.g., one is renamed or destroyed), the remaining entity's flag is restored to `true`.

---

## How to Use This in a Mod

### Creating an Auto-Numbering Building
If you create a custom building and want it to automatically count up (e.g., "My Custom Pump 1", "My Custom Pump 2"), you need to add the `NumberedEntityNamerSpec` and `NamedEntitySpec` to your prefab's JSON definition.

*Example JSON configuration:*

    "NamedEntity": {
      "IsEditable": true
    },
    "NumberedEntityNamer": {
      "FormatLocKey": "Core.NameWithNumber",
      "IsPersistent": false
    }

*Note: `Core.NameWithNumber` expects two arguments: `{0}` for the number and `{1}` for the base name.*

---

## Modding Insights & Limitations

* **Namer Priority**: Because `NumberedEntityNamer` has a priority of `10` and `LabeledEntityNamer` has a priority of `0`, the game will always choose to number the building if both components are present on the prefab.
* **Backwards Compatibility**: The `Load` method in `NamedEntity` contains legacy migration code (`[BackwardCompatible(2026, 2, 3, Compatibility.Save)]`) to handle old save files where names were stored inside specific components like `Character` or `DistrictCenter` rather than the generic `NamedEntity` component.
* **Sorting Regex**: The regex used to make names sortable (`\\d+`) limits padding to 5 digits (`digits.Value.PadLeft(5, '0')`). If an entity manages to get a number larger than 99,999, sorting may behave unexpectedly.

---

## Related DLLs

* **Timberborn.EntitySystem**: Provides the core `EntityComponent` required by this module.
* **Timberborn.TemplateSystem**: Used by `NumberedEntityNamer` to grab the `TemplateName` as the default numbering group if one isn't explicitly provided in the spec.
* **Timberborn.SingletonSystem**: Provides the `EventBus` used to broadcast `EntityNameChangedEvent`.
* **Timberborn.Persistence**: Provides the `IValueSerializer` necessary for saving the persistent numbering increments (`SerializedEntityNameNumberSerializer`).
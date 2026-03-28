# Timberborn.EntityNamingUI

## Overview
The `Timberborn.EntityNamingUI` module handles the user interface elements related to renaming game entities and alerting players when naming conflicts occur. It provides the input dialog for changing a building or character's name and adds visual status warnings for entities that require unique names.

---

## Key Components

### 1. `EntityNameDialog`
This class manages the pop-up window that appears when a player attempts to rename an entity (like a District Center or a beaver).
* **Input Box**: It utilizes the `InputBoxShower` to generate a standard text input modal.
* **Default Value**: The input box is pre-populated with the entity's current `EntityName`.
* **Validation & Assignment**: When the player confirms the new name, the dialog trims any leading/trailing whitespace (`newName.Trim()`) and ensures the string is not empty before passing it to `NamedEntity.SetEntityName`.

### 2. `DuplicateEntityNameStatus`
This component provides visual feedback to the player if they give a non-unique name to an entity that requires one.
* **Status Registration**: It listens to the `IsUniqueChanged` event fired by the `UniquelyNamedEntity` component.
* **Visuals**: If `IsUnique` becomes false, it activates a `StatusToggle`. This toggle is configured as a "PriorityStatusWithAlertAndFloatingIcon", meaning it will display a red error icon (`GenericError`) over the building and post an alert to the top-left notification feed.
* **Localization Keys**: It uses `Status.Naming.DuplicateName` for the full tooltip and `Status.Naming.DuplicateName.Short` for the floating icon.

### 3. `EntityNamingUIConfigurator`
A standard Bindito configurator that registers the UI elements within the dependency injection framework.
* **Context**: It operates in both the `Game` and `MapEditor` contexts, meaning developers and players can rename entities and see duplicate warnings while building maps.
* **Template Injection**: It uses a `TemplateModule` to automatically attach the `DuplicateEntityNameStatus` component to any prefab that already possesses a `UniquelyNamedEntity` component.

---

## Modding Insights & Limitations

* **No Regex Restrictions on User Input**: The `EntityNameDialog` does not enforce any character limits, profanity filters, or regex validations on the player's input beyond checking for `string.IsNullOrWhiteSpace`. Modders should be aware that players can inject practically any Unicode string into the `NamedEntity` component.
* **Automatic Decoration**: Because the configurator binds `DuplicateEntityNameStatus` as a decorator for `UniquelyNamedEntity`, modders do not need to manually add the status component to their custom building prefabs. If you make a building require a unique name in its JSON, the warning icon logic is applied automatically.

---

## Related DLLs

* **Timberborn.EntityNaming**: The core logic backend that provides the `NamedEntity` and `UniquelyNamedEntity` components tracked by this UI.
* **Timberborn.CoreUI**: Provides the `InputBoxShower` used to render the renaming dialog.
* **Timberborn.StatusSystem**: Supplies the `StatusToggle` and `StatusSubject` needed to render the floating error icons.
* **Timberborn.Localization**: Supplies the `ILoc` service used to translate the dialog header and error messages.
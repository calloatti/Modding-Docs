# Timberborn.CharactersUI

## Overview
The `Timberborn.CharactersUI` module provides user interface elements specifically related to individual characters. It includes factories for creating character portrait buttons (used in building panels to show workers/residents) and specific row items for the Batch Control window. It also provides a developer tool to toggle the visibility of all character models on the map.

---

## Key Components

### 1. `CharacterButton` & `CharacterButtonFactory`
These classes generate the visual buttons representing a beaver or bot. They are heavily utilized in other UI modules, such as the `WorkplaceFragment` (showing the 3 faces of the workers inside a lumber mill) or the `DwellingFragment` (showing who lives in a house).

* **Factory**: `CharacterButtonFactory` creates the button using the `Game/EntityPanel/CharacterButton` UXML template.
* **State Management**: The `CharacterButton` class manages the visual state and click logic of the button.
    * `ShowFilled()`: Displays the specific 3D avatar snapshot of a living character via the `EntityBadgeService` and assigns a click action (usually selecting the character).
    * `ShowAdultEmpty()`, `ShowChildEmpty()`, `ShowBotEmpty()`: If a workplace or house slot is empty, it queries the `FactionService.Current` to get the silhouette icon for that faction's specific species/type.
    * **Click Handling**: The `ClickAction` is assigned dynamically, meaning other systems can pass in lambda functions that execute when the portrait is clicked.

### 2. `CharacterBatchControlRowItem`
This generates the leftmost column of data in the "Population" Batch Control window.
* **Data Binding**: It takes a `Character` component and binds its `FirstName` to the `_entityName.text` label, updating it dynamically (`IUpdatableBatchControlRowItem`).
* **Interactions**: 
    * Clicking the avatar button triggers `_entitySelectionService.SelectAndFollow(entity)`, snapping the camera to that specific beaver.
    * Clicking the name label triggers `_entityNameDialog.Show()`, opening the pop-up that allows the player to rename the character.

### 3. `CharactersModelToggler`
A developer module (`IDevModule`) that adds an option to the Dev Menu: `"Toggle models: Characters"`.
* It loops through the `_characterPopulation.Characters` list and calls `Hide()` or `Show()` directly on the `CharacterModel` component, instantly making every character on the map invisible/visible.

---

## How to Use This in a Mod

### Adding Character Portraits to Custom UI
If you create a custom building that holds characters (like a prison, a vehicle, or an entertainment building), you should use the `CharacterButtonFactory` to display who is inside. This ensures your UI perfectly matches the game's aesthetic and automatically supports modded factions.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CharactersUI;
using UnityEngine.UIElements;

public class CustomVehicleFragment : IEntityPanelFragment
{
    private readonly CharacterButtonFactory _buttonFactory;
    private CharacterButton _driverButton;
    private MyCustomVehicle _vehicle;

    public CustomVehicleFragment(CharacterButtonFactory buttonFactory)
    {
        _buttonFactory = buttonFactory;
    }

    public VisualElement InitializeFragment()
    {
        // Assume you load a custom UXML root here
        VisualElement root = new VisualElement(); 
        
        // Use the factory to create a standard portrait button
        _driverButton = _buttonFactory.Create();
        root.Add(_driverButton.Root);
        
        return root;
    }

    public void UpdateFragment()
    {
        if (_vehicle.HasDriver)
        {
            // Show the driver's face. When clicked, select the driver.
            _driverButton.ShowFilled(_vehicle.Driver, () => SelectDriver(_vehicle.Driver));
        }
        else
        {
            // Show the empty silhouette for the current faction
            _driverButton.ShowAdultEmpty();
        }
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Faction Silhouettes**: `CharacterButton` relies directly on the `FactionService.Current` to get empty slot avatars (`AdultEmpty`, `ChildEmpty`, `BotEmpty`). If a modder creates a new custom faction that has completely different life stages (e.g., Larva, Worker, Queen), the `CharacterButton` API lacks methods to support them, and it will fall back to attempting to load the standard Adult/Child/Bot icons defined by the base `FactionService`.
* **UXML Dependency**: `CharacterButtonFactory` heavily relies on the structure of `Game/EntityPanel/CharacterButton`. If this UXML is overridden or modified carelessly, the `Root.Q<Button>("CharacterButton")` call will fail and crash UI initialization.
* **Context Restriction**: The `CharactersUIConfigurator` is restricted to `[Context("Game")]`. It is not available in the Map Editor or Main Menu contexts.
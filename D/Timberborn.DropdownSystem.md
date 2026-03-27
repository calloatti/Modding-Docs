# Timberborn.DropdownSystem

## Overview
The `Timberborn.DropdownSystem` module provides a comprehensive UI framework for creating and managing custom dropdown menus within the game. It supports simple text lists, extended lists with icons and CSS class styling, localized enum selection, and dynamic tooltips, all integrated with Unity's UI Toolkit (UIElements).

---

## Key Components

### 1. `Dropdown` (UXML Element)
This is the core custom visual element that can be placed directly in UXML files.
* **UXML Attributes**: It supports custom attributes like `label-loc-key` (for localized titles), `force-label` (to show the label even if the key is empty), and `buttons-only-selection` (to navigate via side arrows rather than opening a list).
* **Initialization**: The `DropdownInitializer` automatically wires up these elements when a UI panel is loaded.
* **Events**: It exposes `ValueChanged` and `Showed` events for external systems to react to player input.

### 2. `DropdownListDrawer`
This singleton manages the actual rendering of the expanded list of options when a player clicks on a dropdown.
* **Global Overlay**: Instead of drawing the list inside the parent container (which could cause clipping), it creates a single `DropdownListDrawer` UI element at the root level.
* **Dynamic Positioning**: It uses `CalculateDimensions` to figure out where the clicked dropdown is on the screen and automatically opens the list downwards or upwards depending on available screen space, capping at a `MaxHeight` of 510 pixels.
* **Input Handling**: It intercepts mouse clicks and scrolls to hide the list if the player clicks outside of it.

### 3. Dropdown Providers
To populate a dropdown, modders must supply an `IDropdownProvider` which tells the UI what the current value is and what the options are.
* **`IDropdownProvider`**: The basic interface requiring a list of string items, a getter, and a setter.
* **`IExtendedDropdownProvider`**: Adds support for custom display text formatting, icons (`Sprite`), and injecting custom CSS classes per item.
* **`IExtendedTooltipDropdownProvider`**: Further extends functionality by allowing specific tooltips to be assigned to individual items in the list.

### 4. `EnumDropdownProvider`
A specialized implementation of the provider system specifically designed for C# Enums.
* It uses `Enum.GetNames()` to automatically generate the list of available items.
* The `EnumDropdownProviderFactory` provides helper methods like `CreateLocalized`, which automatically formats the enum names into localization keys (e.g., `MyEnumPrefix.EnumValue`).

---

## How to Use This in a Mod

### Creating a Localized Enum Dropdown in UI
If you have a settings panel and want to let players choose from a custom Enum:

```csharp
using Timberborn.DropdownSystem;
using UnityEngine.UIElements;

public enum ModSettings { Fast, Normal, Slow }

public class MyModSettingsUI {
    private readonly DropdownItemsSetter _dropdownItemsSetter;
    private readonly EnumDropdownProviderFactory _enumFactory;
    
    private ModSettings _currentSetting = ModSettings.Normal;

    public void Initialize(VisualElement root) {
        // 1. Find the dropdown element (assuming it was placed in UXML)
        Dropdown myDropdown = root.Q<Dropdown>("MySpeedDropdown");
        
        // 2. Create the provider using the factory
        var provider = _enumFactory.CreateLocalized(
            () => _currentSetting, 
            (newValue) => _currentSetting = newValue, 
            "MyMod.SpeedSetting." // Loc key prefix
        );
        
        // 3. Bind the provider to the visual element
        _dropdownItemsSetter.SetLocalizableItems(myDropdown, provider);
    }
}
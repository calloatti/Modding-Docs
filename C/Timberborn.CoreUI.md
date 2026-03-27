# Timberborn.CoreUI

## Overview
The `Timberborn.CoreUI` module acts as the central framework for the game's user interface, built upon Unity's **UI Toolkit** (formerly UIElements). It provides standardized components, automated initialization logic (for sounds, localization, and tooltips), and a robust panel management system that handles hierarchical navigation and screen overlays.

---

## Key Components

### 1. Panel Management (`PanelStack`)
The `PanelStack` is the primary controller for all full-screen or major UI windows.
* **Hierarchical Navigation**: It manages a stack of `IPanelController` objects, ensuring that only the top-most panel captures input.
* **Overlay Support**: It can push panels as "Overlays" or "Dialogs". Dialogs automatically dim the background using a `Core/Overlay` visual element and can optionally lock game simulation speed.
* **Input Interception**: It implements `IInputProcessor` to capture "Confirm" and "Cancel" (ESC) keys, directing them to the active panel's `OnUIConfirmed()` or `OnUICancelled()` methods.
* **Event System**: It posts `PanelShownEvent` and `PanelHiddenEvent` to the global `EventBus`, allowing systems like audio or game speed to react when menus open.

### 2. Automated Initialization (`VisualElementInitializer`)
Timberborn uses a decorator pattern to automatically configure UI elements as they are loaded.
* **`VisualElementLoader`**: When a UXML file is loaded from `UI/Views`, it is passed through the `VisualElementInitializer`.
* **Multi-Bind Initializers**: Several specialized initializers run on every loaded element:
    * **`VisualElementLocalizer`**: Finds elements implementing `ILocalizableElement` and translates their text using the `text-loc-key` attribute.
    * **`UISoundInitializer`**: Attaches click sounds based on the `--click-sound` custom CSS property.
    * **`ButtonClickabilityInitializer`**: Ensures buttons respond to clicks even when modifier keys (like Shift or Ctrl) are held.
    * **`TextElementInitializer`**: Automatically blocks game input when a text field is focused to prevent beavers from moving while the player types.

### 3. Custom UI Controls
The module extends standard UI Toolkit elements with game-specific functionality.
* **`PreciseSlider`**: A composite control featuring a standard slider, "Increase/Decrease" buttons, and an optional visual "Marker" to show a recommended or current value.
* **`DoubleSidedProgressBar`**: A custom-rendered bar that can fill in two directions from a center point, used for displaying relative offsets or balanced values.
* **`NineSliceBackground`**: A manual mesh-writing implementation that allows UI elements to have textured borders that don't stretch, supporting custom CSS properties like `--background-slice` and `--background-image`.
* **`AlternateClickable`**: A wrapper that allows a single UI element to perform two different actions: a "Main Action" on a regular click, and an "Alternate Action" if a specific key (like Shift) is held.

### 4. Global UI Services
* **`UIScaler`**: Manages the global UI scale factor (typically between 0.8 and 1.4), updating the Unity `PanelSettings` to resize the entire interface.
* **`DialogBoxShower`**: A builder-pattern utility to quickly create and display popup windows with custom messages, "Confirm," "Cancel," and "Info" buttons.
* **`InputBoxShower`**: A specialized dialog for text input, featuring character limits and automated focus.
* **`Underlay`**: Manages a persistent UI layer that sits behind other panels, used for world-space indicators or background elements.

---

## How to Use This in a Mod

### Creating a Standard Dialog Box
If you need to ask the player for confirmation before performing a modded action, use the `DialogBoxShower`.

```csharp
using Timberborn.CoreUI;

public class MyModActions {
    private readonly DialogBoxShower _dialogBoxShower;

    public MyModActions(DialogBoxShower dialogBoxShower) {
        _dialogBoxShower = dialogBoxShower;
    }

    public void AskToDeleteEverything() {
        _dialogBoxShower.Create()
            .SetLocalizedMessage("MyMod.ConfirmDelete")
            .SetConfirmButton(() => PerformDelete(), "Delete")
            .SetDefaultCancelButton()
            .Show();
    }
}
```

### Loading Modded UXML with Auto-Initialization
When loading UI for a custom building fragment or window, always use `VisualElementLoader` to ensure localization and sound hooks are attached automatically.

```csharp
using Timberborn.CoreUI;
using UnityEngine.UIElements;

public class MyFragment : IEntityPanelFragment {
    private readonly VisualElementLoader _loader;

    public VisualElement InitializeFragment() {
        // Loads UI/Views/MyMod/MyUI.uxml and runs all initializers
        return _loader.LoadVisualElement("MyMod/MyUI");
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Character Limits**: The `InputBoxShower` has a hardcoded `CharacterLimit = 24`. Modders wanting to allow longer text input (like detailed building descriptions) must create their own custom input dialogs.
* **Button Modifier Handling**: The `ButtonClickabilityInitializer` is a significant convenience; in vanilla Unity UI Toolkit, buttons often fail to trigger if the user is holding Shift (e.g., for bulk actions). Timberborn fixes this by explicitly adding all possible `EventModifiers` to button activators.
* **Texture Resources**: Many custom elements like `SimpleProgressBar` or `NineSliceVisualElement` look for sprites using `Resources.Load<Sprite>`. Modders intending to use these classes with their own textures must ensure their assets are correctly placed in a `Resources` folder or handled via the game's asset loading system.
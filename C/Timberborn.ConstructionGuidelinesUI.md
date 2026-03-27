# Timberborn.ConstructionGuidelinesUI

## Overview
The `Timberborn.ConstructionGuidelinesUI` module provides the user interface hooks to interact with the grid overlays managed by `Timberborn.ConstructionGuidelines`. It adds a toggle button to the top-right of the screen and automates the grid visibility when the player enters or exits "Construction Mode".

---

## Key Components

### 1. `ConstructionGuidelinesTogglePanel`
This component is responsible for rendering the grid toggle button that is always visible in the game's main UI.
* **UI Construction**: It loads the standard `"Common/SquareToggle"` visual element and applies a specific CSS class (`"square-toggle--construction-guidelines"`) to give it the correct icon. 
* **Placement**: During `OnShowPrimaryUI()`, it uses `_uiLayout.AddTopRightButton(_root, 3)` to inject the button into the upper-right corner of the screen (typically next to the speed controls or slice tool).
* **Functionality**: It connects the UI toggle to `_constructionGuidelinesRenderingService.EnableGuidelines()` and `DisableGuidelines()`. It also binds to the `ToggleGuidelinesKey` (so players can press a hotkey to toggle the grid) and provides a dynamic tooltip showing the keybinding.

### 2. `ConstructionModeGuidelinesShower`
This singleton automates the grid visibility based on the player's current action.
* **Registration**: During `Load()`, it requests a `ConstructionGuidelinesToggle` token from the `ConstructionGuidelinesRenderingService`.
* **Event Listening**: It listens for `ConstructionModeChangedEvent`.
* **Logic**: If `_constructionModeService.InConstructionMode` becomes true (meaning the player clicked a build menu category), it calls `ShowGuidelines()`. When the player exits construction mode, it calls `HideGuidelines()`. This ensures the grid appears automatically when you are trying to place a building, without requiring the player to manually toggle it on via the top-right button.

---

## How to Use This in a Mod

### Understanding UI Injection
If you are creating a mod that adds a new global tool toggle (like an "Underground View" or "Water Depth Overlay"), you can mimic the approach used by `ConstructionGuidelinesTogglePanel`.

```csharp
using Timberborn.CoreUI;
using Timberborn.SingletonSystem;
using Timberborn.UILayoutSystem;
using UnityEngine.UIElements;

public class CustomOverlayTogglePanel : ILoadableSingleton
{
    private readonly UILayout _uiLayout;
    private readonly EventBus _eventBus;
    private VisualElement _root;

    [Inject]
    public void InjectDependencies(UILayout uiLayout, EventBus eventBus)
    {
        _uiLayout = uiLayout;
        _eventBus = eventBus;
    }

    public void Load()
    {
        // Load your custom button UI
        _root = LoadMyCustomButton(); 
        _eventBus.Register(this);
    }

    [OnEvent]
    public void OnShowPrimaryUI(ShowPrimaryUIEvent showPrimaryUIEvent)
    {
        // Add it to the top right next to the grid toggle.
        // The 'index' determines the order from right to left.
        _uiLayout.AddTopRightButton(_root, 4); 
    }
}
```

---

## Modding Insights & Limitations

* **Toggle Hierarchy**: Timberborn's guideline system handles "Permanent Toggle" and "Temporary Show" differently. 
    * `ConstructionGuidelinesTogglePanel` calls `EnableGuidelines()`, which turns the grid on permanently until explicitly turned off.
    * `ConstructionModeGuidelinesShower` uses a `ConstructionGuidelinesToggle` token to request temporary visibility. As seen in the underlying service logic, if the player permanently disables the grid via the top-right button, entering construction mode will *still* force the grid to appear temporarily. Modders should be aware of this distinction when designing UI that interacts with the grid.
* **CSS Dependency**: The button's visual icon is driven entirely by the `square-toggle--construction-guidelines` class added in C#. Modders attempting to replace or alter this button cannot just edit the UXML file; they must also ensure the USS files correctly map this specific class to the desired sprite.
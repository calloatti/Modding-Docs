# Timberborn.BuilderPrioritySystemUI

## Overview
The `Timberborn.BuilderPrioritySystemUI` module acts as the interactive presentation layer for the `Timberborn.BuilderPrioritySystem`. It provides the visual tools that allow players to view and modify construction priorities, including a dedicated mass-selection tool group in the bottom bar and dynamic color highlighting for active construction sites.

---

## Key Components

### 1. `BuilderPriorityTool` & `BuilderPrioritiesButton`
These components manage the player-facing tool used to drag and select multiple buildings to alter their priority.
* **`BuilderPrioritiesButton`**: This class implements `IBottomBarElementsProvider` to inject a tool group dropdown (the blue folder icon) into the Left section of the bottom bar. It iterates through all available `Priority` enum values (Lowest to Highest) and uses the `BuilderPrioritiesButtonFactory` to generate a button for each one.
* **`BuilderPriorityTool`**: The actual tool logic that runs when the player clicks one of the priority buttons.
    * It implements `IInputProcessor` and `ITool`.
    * It uses an `AreaBlockObjectPicker` to detect which blocks the player is dragging their mouse over.
    * During the `ActionCallback` (when the player releases the mouse), it iterates through the selected `BlockObject` entities, checks if they possess an active `BuilderPrioritizable` component, and calls `SetPriority(_priority)` on them.
    * It uses `BlockObjectSelectionDrawer` to draw the colored selection boxes on the terrain while the player drags the mouse.

### 2. `BuilderPrioritizableHighlighter`
This singleton provides visual feedback indicating the current priority of active construction sites.
* **Activation**: It listens to the `EventBus` for `ToolGroupEnteredEvent` and `ToolGroupExitedEvent`. If the active tool group has a `BuilderPriorityToolGroupSpec`, it sets `_enabled = true` and calls `HighlightAll()`. This is why construction site priorities light up with colors when you open the builder priority menu.
* **Highlighting**: It iterates through its internal list of `_builderPrioritizables` and delegates the actual rendering to the `Highlighter` service, mapping the `Priority` enum to a specific color defined by `PriorityColors.GetHighlightColor()`.

### 3. `BuilderPrioritizableHighlightUpdater`
This component is attached as a decorator to any entity that possesses `BuilderPrioritizable`. 
* **State Syncing**: During `Awake()`, it hooks into the `PrioritizableEnabled`, `PrioritizableDisabled`, and `PriorityChanged` events of its parent `BuilderPrioritizable` component. 
* **Registration**: When enabled, it registers itself with the global `BuilderPrioritizableHighlighter`, and unregisters when disabled, ensuring the highlighter only tracks active construction sites. 

### 4. `BuilderPriorityToggleGroupFactory`
A utility factory that helps other UI panels (like a building's individual entity panel) generate the standard five-button priority toggle row. It wraps the generic `PriorityToggleGroupFactory` and explicitly binds the `DecreaseBuildersPriority` and `IncreaseBuildersPriority` keyboard shortcut keys to the buttons.

---

## How to Use This in a Mod

### Adding the Priority Toggle Row to a Custom Panel
If you are creating a custom UI panel for a new type of building that uses the `BuilderPrioritizable` component, you can easily add the standard priority selection row using the provided factory.

```csharp
using Timberborn.BuilderPrioritySystemUI;
using Timberborn.PrioritySystemUI;
using UnityEngine.UIElements;

public class MyCustomBuildingPanelFragment
{
    private readonly BuilderPriorityToggleGroupFactory _toggleGroupFactory;
    private PriorityToggleGroup _priorityToggleGroup;
    private VisualElement _root;

    public MyCustomBuildingPanelFragment(BuilderPriorityToggleGroupFactory toggleGroupFactory)
    {
        _toggleGroupFactory = toggleGroupFactory;
    }

    public void Initialize(VisualElement rootContainer)
    {
        _root = rootContainer;
        
        // This generates the 5 buttons, hooks up the Sprites, 
        // and binds the standard +/- hotkeys automatically.
        _priorityToggleGroup = _toggleGroupFactory.Create(_root, "Priorities.Builder");
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Input Bindings**: The `BuilderPriorityToggleGroupFactory` hardcodes the keyboard shortcuts `"DecreaseBuildersPriority"` and `"IncreaseBuildersPriority"` for the UI buttons. Modders cannot easily remap these default inputs for the standard builder priority UI without completely bypassing this factory.
* **Sprite Naming Convention**: The `BuilderPrioritySpriteLoader` assumes that all priority sprites are located in `Sprites/Priority/Panel` or `Sprites/Priority/Buttons`, and that the file names match the exact string representation of the `Priority` enum (e.g., `"Lowest"`, `"High"`). If a modder attempts to add a new custom `Priority` enum value, they must ensure corresponding sprites exist at these exact paths to prevent missing asset errors.
* **Event-Driven UI**: The UI system does not constantly poll for priority changes. The `BuilderPrioritizableHighlightUpdater` only updates the `Highlighter` when the underlying `BuilderPrioritizable` fires the `PriorityChanged` event. Modders must ensure they use `SetPriority()` rather than attempting to bypass the setter if they want the UI colors to update correctly.
# Timberborn.AutomationUI

## Overview
The `Timberborn.AutomationUI` module provides the core user interface components for the game's automation system. It is responsible for the visual feedback of automation states, the menus used to configure connections between buildings, and developer tools for monitoring the performance of the logic graph.

This DLL is essential for modders who want to integrate custom buildings into the automation network with a native-looking interface for selecting inputs and viewing logic status.

---

## Key Components

### 1. The Connection System (`TransmitterSelector` & `TransmitterPickerTool`)
This is the most complex part of the automation UI, allowing players to link a "Terminal" (receiver) to a "Transmitter" (source).
* **`TransmitterSelector`**: A custom UXML element (`VisualElement`) that contains a dropdown list of all named transmitters on the map. It also triggers the world-space picker.
* **`TransmitterPickerTool`**: A specialized cursor tool that enters a "picking mode". While active, the player can click directly on a building in the 3D world to set it as the automation source for the selected building.
* **`TransmitterPickerToolHighlighter`**: Handles the visual cues during picking, highlighting valid transmitters in colors defined by `TransmitterPickerColorsSpec` (e.g., highlighting finished vs. unfinished buildings differently).

### 2. State Visualization (`AutomationStateIcon`)
A standardized visual component used throughout the UI to show if a logic node is `On`, `Off`, `Error` (Cyclic), or `Processing`.
* **Functionality**: It applies USS classes like `automation-state-icon--on` and tints the icon using the `CustomizableIlluminator.IconColor` of the building.
* **Interaction**: Using the `AutomationStateIconBuilder`, these icons can be made clickable, which automatically selects and focuses the camera on the building providing that signal.

### 3. Entity Panel Fragments
The DLL provides several fragments injected into the building info panel:
* **`TransmitterFragment`**: Shows the current state of a logic source and how many other buildings are currently using its signal (`Usages`).
* **`AutomatableFragment`**: Appears on buildings that can be controlled (Terminals). It displays the input selection UI.
* **`SequentialTransmitterResetFragment`**: Provides "Reset" and "Reset All" buttons for stateful logic components like Timers or Memory latches.

### 4. Status and Debugging
* **`AutomationLoopStatus`**: A decorator for the `Automator` component that triggers a floating "Automation Loop" warning icon above a building if the logic graph detects an infinite feedback loop.
* **`AutomationDebuggingPanel`**: Injects an "Automation" section into the dev debug menu, showing real-time metrics for partitioning, planning, and evaluation times in milliseconds.

---

## How to Use This in a Mod

### Adding an Automation Input to a Custom Building Panel
If you have a custom component that needs a user-selectable automation input, you should use the `TransmitterSelector` pattern in your `IEntityPanelFragment`.

```csharp
using Timberborn.Automation;
using Timberborn.AutomationUI;
using Timberborn.BaseComponentSystem;
using Timberborn.EntityPanelSystem;
using UnityEngine.UIElements;

public class MyModTerminalFragment : IEntityPanelFragment
{
    private readonly VisualElementLoader _visualElementLoader;
    private readonly TransmitterSelectorInitializer _selectorInitializer;
    private TransmitterSelector _inputSelector;
    private MyCustomTerminal _terminal;

    public MyModTerminalFragment(
        VisualElementLoader visualElementLoader, 
        TransmitterSelectorInitializer selectorInitializer)
    {
        _visualElementLoader = visualElementLoader;
        _selectorInitializer = selectorInitializer;
    }

    public VisualElement InitializeFragment()
    {
        // Load UXML that contains a <Timberborn.AutomationUI.TransmitterSelector />
        var root = _visualElementLoader.LoadVisualElement("MyMod/MyTerminalFragment");
        _inputSelector = root.Q<TransmitterSelector>("InputSelector");

        // Initialize the selector with getters/setters for your component
        _selectorInitializer.Initialize(
            _inputSelector, 
            () => _terminal.InputTransmitter, 
            transmitter => _terminal.SetInput(transmitter)
        );

        return root;
    }

    public void ShowFragment(BaseComponent entity)
    {
        _terminal = entity.GetComponent<MyCustomTerminal>();
        if (_terminal != null) 
        {
             _inputSelector.Show(_terminal);
        }
    }

    public void UpdateFragment()
    {
        if (_terminal != null) _inputSelector.UpdateStateIcon();
    }

    public void ClearFragment()
    {
        _terminal = null;
        _inputSelector.ClearItems();
    }
}
```

---

## Modding Insights & Limitations

* **Click-to-Focus**: The `AutomationStateIcon` is extremely useful for UX. If your mod displays a list of connected buildings, using `AutomationStateIconBuilder.SetClickableIcon()` allows players to jump between nodes in their logic network easily.
* **UXML Integration**: `TransmitterSelector` is a `[UxmlElement]`. This means you can reference it directly in your UXML files by name, provided the `Timberborn.AutomationUI` namespace is available to the UI Toolkit loader.
* **Automatic Reset Logic**: If you are making a complex logic mod with internal state (like a counter), adding the `ISequentialTransmitter` interface to your logic component will automatically grant your building a "Reset" button in its UI via the `SequentialTransmitterResetFragment` decorator.
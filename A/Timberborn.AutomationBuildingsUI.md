# Timberborn.AutomationBuildingsUI

## Overview
The `Timberborn.AutomationBuildingsUI` module bridges the simulation logic of automation buildings (from `Timberborn.AutomationBuildings`) with the game's UI Toolkit systems. It provides the menus, dropdowns, sliders, and toggles that appear when a player clicks on an automation building.

Additionally, it handles "pinned" global UI elements (like pinned levers and indicators) and in-world visual markers that represent automation states.

---

## Key Components

### 1. `IEntityPanelFragment` Implementations
For almost every component in `Timberborn.AutomationBuildings`, there is a corresponding fragment here (e.g., `ChronometerFragment`, `MemoryFragment`, `DepthSensorFragment`).
* **Lifecycle:** These classes implement `InitializeFragment()`, `ShowFragment()`, `UpdateFragment()`, and `ClearFragment()`.
* **UI Binding:** They use `VisualElementLoader.LoadVisualElement(...)` to load UXML files and bind UI elements (like `PreciseSlider` or `Dropdown`) to the underlying building's C# properties and methods (e.g., `_chronometer.SetStartTime(...)`).

### 2. Pinned Global Panels
The system provides a way for players to pin specific automation buildings to their screen so they can view or interact with them without clicking the building.
* **`PinnedLeversPanel`:** Loads the `PinnedLeversPanel` UXML and registers itself to the `UILayout` using `_uiLayout.AddTopLeft(_root, 40)` when the primary UI is shown. It also implements `IInputProcessor` to listen for global hotkeys (`PinnedLever1` through `PinnedLever10`) to trigger lever presses instantly.
* **`PinnedIndicatorsPanel`:** Automatically populates a list of indicators that the player has set to `IndicatorPinnedMode.Always` or `IndicatorPinnedMode.WhenOn`, updating their status icons dynamically.

### 3. In-World Visualization
UI isn't restricted to 2D menus. This DLL handles 3D world overlays and statuses.
* **`DepthSensorMarker`:** An `ISelectionListener` that uses a `MarkerDrawerFactory` to physically draw a blue line (`Color.blue`) in the 3D world exactly at the height of the depth sensor's threshold (`_depthSensor.Threshold + MarkerYOffset`) whenever the player selects the building.
* **`GateConflictStatus`:** Listens to a gate's `StateChanged` event and uses the `StatusToggle` system to float a warning icon above floodgates that are receiving conflicting automation signals.

### 4. Dropdown Providers and Helpers
Translating C# Enums into localized UI dropdowns is a common task here.
* **`NumericComparisonModeDropdownFactory`:** A singleton factory that generates an `EnumDropdownProvider` for the `NumericComparisonMode` enum (Greater, Less, Equal, etc.), automatically pairing them with sprite icons.
* **`MemoryModeDescriptions` & `RelayModeDescriptions`:** Caches formatted, localized strings to explain what the currently selected logic gate mode does, updating the `Label` in the UI panel.

---

## How and When to Use This in a Mod

If your mod introduces a new custom automation building (like a "Wind Sensor"), you must create a UI fragment for it so the player can configure its threshold.

### Creating a Custom UI Fragment
You should mirror the pattern used by fragments like `ScienceCounterFragment`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CoreUI;
using Timberborn.EntityPanelSystem;
using Timberborn.Localization;
using UnityEngine.UIElements;
// using YourModNamespace;

public class WindSensorFragment : IEntityPanelFragment
{
    private readonly VisualElementLoader _visualElementLoader;
    private readonly ILoc _loc;
    
    private VisualElement _root;
    private IntegerField _thresholdInput;
    private WindSensor _windSensor; // Your custom building component

    public WindSensorFragment(VisualElementLoader visualElementLoader, ILoc loc)
    {
        _visualElementLoader = visualElementLoader;
        _loc = loc;
    }

    public VisualElement InitializeFragment()
    {
        // Load your custom UXML file
        _root = _visualElementLoader.LoadVisualElement("MyMod/EntityPanel/WindSensorFragment");
        _root.ToggleDisplayStyle(visible: false);
        
        _thresholdInput = _root.Q<IntegerField>("ThresholdInput");
        _thresholdInput.RegisterValueChangedCallback(ChangeThreshold);
        _thresholdInput.isDelayed = true;

        return _root;
    }

    public void ShowFragment(BaseComponent entity)
    {
        _windSensor = entity.GetComponent<WindSensor>();
        if (_windSensor != null)
        {
            _thresholdInput.SetValueWithoutNotify(_windSensor.Threshold);
            _root.ToggleDisplayStyle(visible: true);
        }
    }

    public void ClearFragment()
    {
        _windSensor = null;
        _root.ToggleDisplayStyle(visible: false);
    }

    public void UpdateFragment()
    {
        // Update live data here if needed (e.g., current wind speed)
    }

    private void ChangeThreshold(ChangeEvent<int> evt)
    {
        if (_windSensor != null)
        {
            _windSensor.SetThreshold(evt.newValue);
        }
    }
}
```

You then register this in a `Configurator` and add it to the `EntityPanelModule.Builder` via a provider, just like `AutomationBuildingsUIConfigurator` does.

---

## Modding Insights & Limitations

* **Dependency Separation:** Notice that this DLL only reads data and triggers setters on components from `Timberborn.AutomationBuildings`. It contains zero actual simulation logic. Always keep your UI code in a separate class (or ideally, assembly) from your simulation code to prevent desyncs and to respect multiplayer/headless environments.
* **`SetValueWithoutNotify`:** When updating UI elements based on the building's current state (inside `ShowFragment` or `UpdateFragment`), this DLL always uses `SetValueWithoutNotify(...)` rather than `value = ...`. This is a critical UI Toolkit practice that prevents infinite loops where changing the UI triggers the callback, which changes the backend, which triggers the UI again.
* **Delayed Inputs:** Input fields like `IntegerField` or `FloatField` are explicitly set to `isDelayed = true`. This ensures the callback (like `ChangeThreshold`) only fires when the user presses Enter or clicks away from the text box, rather than firing on every single keystroke.
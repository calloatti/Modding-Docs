# Timberborn.AlertPanelSystem

## Overview
The `Timberborn.AlertPanelSystem` module governs the UI panel located in the bottom-left corner of the game screen. This panel is responsible for displaying global alerts and warnings to the player, such as notifications for drought approaching, beavers dying of thirst, or buildings lacking power.

It uses a modular, fragment-based architecture similar to the `EntityPanelSystem` (the menu that appears when you click a beaver or building), allowing modders to easily inject custom alerts without overriding vanilla UI code.

---

## Key Components

### 1. `IAlertFragment` (The Contract)
This is the interface that your custom alerts must implement. 
* **`InitializeAlertFragment(VisualElement root)`:** Called once during loading. You should instantiate your UI elements, add them to the provided `root` container, and hide them by default.
* **`UpdateAlertFragment()`:** Called every frame (via `AlertPanel.UpdateSingleton`) when the UI is visible. This is where you check your custom logic and toggle your UI fragment's visibility (`ToggleDisplayStyle(true/false)`) based on game conditions.

### 2. `AlertPanelModule` & `Builder`
This is how fragments are grouped and ordered within the dependency injection container.
* A `Builder` allows you to register an `IAlertFragment` with a specific integer `order`.
* The `AlertPanel` iterates through all injected modules, extracts the fragments, and sorts them by their `order` key so they appear in a consistent top-to-bottom sequence on the screen.

### 3. `AlertPanelRowFactory`
A highly useful utility provided by the game to generate standardized UI rows for the alert panel.
* **`Create(string labelLocKey, string statusIconName)`:** Creates a standard alert button with an icon and text.
* **`CreateClosable(string statusIconName)`:** Creates an alert row with an "X" button that allows the player to manually dismiss the alert. The factory automatically wires up the click event to hide the row (`root.ToggleDisplayStyle(visible: false)`).
* Note that these rows are styled to look like native Timberborn alerts, using classes like `hover-enabled` and standard UXML structures.

### 4. `AlertPanel`
The central manager of the system.
* It listens to the `ShowPrimaryUIEvent` on the EventBus.
* Once the primary UI is requested to show, it injects its `_root` visual element into the `UILayout` at the `BottomLeft` position.
* It calls `UpdateAlertFragment()` on every registered fragment every tick.

---

## How and When to Use This in a Mod

If your mod introduces a new global mechanic (e.g., a "Rioting" mechanic, an "Overheating" mechanic, or an incoming enemy faction), you should use this system to warn the player.

### Step 1: Create the Custom Fragment
Implement `IAlertFragment` using the provided `AlertPanelRowFactory` to ensure it matches the game's aesthetic.

```csharp
using Timberborn.AlertPanelSystem;
using Timberborn.TickSystem;
using UnityEngine.UIElements;

public class MyCustomModAlertFragment : IAlertFragment
{
    private readonly AlertPanelRowFactory _rowFactory;
    private readonly MyCustomDangerTracker _dangerTracker; // Your custom logic class
    
    private VisualElement _myAlertRow;

    public MyCustomModAlertFragment(AlertPanelRowFactory rowFactory, MyCustomDangerTracker dangerTracker)
    {
        _rowFactory = rowFactory;
        _dangerTracker = dangerTracker;
    }

    public void InitializeAlertFragment(VisualElement root)
    {
        // Use a localization key for the text, and the name of a sprite for the icon
        _myAlertRow = _rowFactory.Create("MyMod.Alerts.DangerWarning", "DangerIconSpriteName");
        
        // Add it to the main alert panel
        root.Add(_myAlertRow);
        
        // Ensure it starts hidden
        _myAlertRow.ToggleDisplayStyle(visible: false);
    }

    public void UpdateAlertFragment()
    {
        // Toggle visibility based on your mod's state
        bool isDangerActive = _dangerTracker.IsDangerImminent();
        _myAlertRow.ToggleDisplayStyle(visible: isDangerActive);
    }
}
```

### Step 2: Register the Fragment
You must create an `AlertPanelModule` via a Provider and bind it into the `Game` context.

```csharp
using Bindito.Core;
using Timberborn.AlertPanelSystem;

[Context("Game")]
public class MyModAlertConfigurator : Configurator
{
    private class MyAlertPanelModuleProvider : IProvider<AlertPanelModule>
    {
        private readonly MyCustomModAlertFragment _myFragment;

        public MyAlertPanelModuleProvider(MyCustomModAlertFragment myFragment)
        {
            _myFragment = myFragment;
        }

        public AlertPanelModule Get()
        {
            AlertPanelModule.Builder builder = new AlertPanelModule.Builder();
            // Choose an order. Lower numbers appear higher in the list.
            builder.AddAlertFragment(_myFragment, 50);
            return builder.Build();
        }
    }

    protected override void Configure()
    {
        Bind<MyCustomModAlertFragment>().AsSingleton();
        MultiBind<AlertPanelModule>().ToProvider<MyAlertPanelModuleProvider>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Performance Consideration:** Because `UpdateAlertFragment()` is called every frame (via `IUpdatableSingleton` inside `AlertPanel`), you must ensure your visibility checks are extremely fast. Avoid complex linq queries or `GetComponent` calls inside `UpdateAlertFragment()`. Instead, cache your boolean states in a tracking manager and simply read the boolean here.
* **UI Elements:** The `AlertPanelRowFactory` assumes your UI will conform to the standard layout (`Common/AlertPanel/AlertPanelRow`). If you need a drastically different UI element (like a slider or dropdown) in the bottom left, you will need to load your own UXML file instead of relying on the factory, though you can still use `IAlertFragment` to inject it into the correct position.
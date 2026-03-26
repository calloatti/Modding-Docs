# Timberborn.BottomBarSystem

## Overview
The `Timberborn.BottomBarSystem` is the UI framework responsible for managing the primary horizontal toolbar at the bottom of the screen. This is the central hub where players access build menus, tools, and system controls. The module provides an interface-driven injection system, allowing different game systems and mods to insert buttons into specific sections (Left, Middle, Right) of the bar without directly modifying core UI files.

---

## Key Components

### 1. `BottomBarPanel`
This is the master UI container for the bottom bar.
* **Initialization**: It is an `ILoadableSingleton` that loads the `Common/BottomBar/BottomBarPanel` UXML layout during game startup.
* **Layout Registration**: It explicitly registers itself with the game's overarching `UILayout` system with an order weight of `100` (`_uiLayout.AddBottomBar(_root, 100)`).
* **Visibility Control**: The bar starts hidden (`visible: false`) and only appears when it receives a `ShowPrimaryUIEvent` via the `EventBus`.
* **Section Processing**: It iterates through all injected `BottomBarModule` instances, organizing the provided buttons into `LeftSection`, `MiddleSection`, and `RightSection` visual elements. If a section receives no buttons, it automatically hides itself (`visualElement.ToggleDisplayStyle(...)`).

### 2. `BottomBarElement`
A struct representing a single, insertable item in the bottom bar.
* **Two-Tier Support**: It holds both a `MainElement` (the primary button visible on the main bar) and an optional `SubElement`.
* **SubElements**: If a `SubElement` is provided (via `CreateMultiLevel`), the `BottomBarPanel` will place it in a dedicated `SubSection` visual container located above the main bar. This is used extensively by the game for tool groups (e.g., clicking the "Water" button opens a secondary sub-bar containing water pumps and dams).

### 3. `BottomBarModule` & `Builder`
This is the registration vehicle used by configurators to inject items into the bar.
* **Targeted Insertion**: The `Builder` provides methods to add an `IBottomBarElementsProvider` to the Left, Middle, or Right sections.
* **Ordering (Left Only)**: Noticeably, `AddLeftSectionElement` requires an `order` integer parameter. The `BottomBarPanel` specifically sorts the Left Section by this key (`dictionary.Keys.OrderBy((int key) => key)`) to ensure build menus appear in a consistent, predictable order. Middle and Right sections do not have explicit sorting parameters in the builder.

### 4. `IBottomBarElementsProvider`
Any class that wishes to place a button on the bottom bar must implement this interface. It requires a single method, `GetElements()`, which returns an `IEnumerable<BottomBarElement>`.

---

## How to Use This in a Mod

### Adding a Custom Tool Button
If your mod introduces a global tool (like a custom terrain flatter or a mass-delete tool), you can inject it into the bottom bar by implementing `IBottomBarElementsProvider` and binding it via a `BottomBarModule`.

**1. Create the Provider:**
```csharp
using System.Collections.Generic;
using Timberborn.BottomBarSystem;
using Timberborn.ToolButtonSystem;
using UnityEngine.UIElements;

public class MyCustomToolButton : IBottomBarElementsProvider
{
    private readonly ToolButtonFactory _toolButtonFactory;
    private readonly MyCustomTool _myCustomTool;

    public MyCustomToolButton(ToolButtonFactory toolButtonFactory, MyCustomTool myCustomTool)
    {
        _toolButtonFactory = toolButtonFactory;
        _myCustomTool = myCustomTool;
    }

    public IEnumerable<BottomBarElement> GetElements()
    {
        // Use a standard Timberborn factory to create the visual button
        ToolButton button = _toolButtonFactory.CreateGrouplessRed(_myCustomTool, "MyMod/Sprites/MyToolIcon");
        
        // Wrap it in a BottomBarElement and yield it
        yield return BottomBarElement.CreateSingleLevel(button.Root);
    }
}
```

**2. Inject it via a Configurator:**
```csharp
using Bindito.Core;
using Timberborn.BottomBarSystem;

[Context("Game")]
internal class MyModBottomBarConfigurator : Configurator
{
    private class BottomBarModuleProvider : IProvider<BottomBarModule>
    {
        private readonly MyCustomToolButton _myButton;

        public BottomBarModuleProvider(MyCustomToolButton myButton)
        {
            _myButton = myButton;
        }

        public BottomBarModule Get()
        {
            BottomBarModule.Builder builder = new BottomBarModule.Builder();
            // Add it to the Left section with an ordering weight (e.g., 90 puts it near the end)
            builder.AddLeftSectionElement(_myButton, 90);
            return builder.Build();
        }
    }

    protected override void Configure()
    {
        Bind<MyCustomToolButton>().AsSingleton();
        MultiBind<BottomBarModule>().ToProvider<BottomBarModuleProvider>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Left Section Collision Risk**: The `BottomBarModule.Builder` uses a standard `Dictionary<int, IBottomBarElementsProvider>` for the Left section. Furthermore, the `BottomBarPanel` merges *all* modules into a single dictionary (`dictionary.Add(item.Key, item.Value)`) before sorting. If two different mods attempt to use the exact same `order` integer for `AddLeftSectionElement`, the `Dictionary.Add` method will throw an `ArgumentException` for a duplicate key, crashing the UI initialization. Modders should avoid using common round numbers (like 10, 50, 100) when possible to reduce collision risks.
* **Middle & Right Section Limitations**: The Middle and Right sections are stored as flat `List<IBottomBarElementsProvider>` objects. They do not support explicit ordering parameters. The order in which buttons appear in these sections depends entirely on the unpredictable order in which Bindito resolves the `BottomBarModule` multi-bindings.
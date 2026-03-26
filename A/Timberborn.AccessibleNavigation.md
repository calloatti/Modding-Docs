# Timberborn.AccessibleNavigation

## Overview
The `Timberborn.AccessibleNavigation` module is a small, specialized assembly that acts as "glue" for Timberborn's navigation and Template Instantiation systems. Its primary purpose is to automatically link buildings or entities that require an access point (`IAccessibleNeeder`) with the actual component that provides that access (`Accessible`).

This is a prime example of Timberborn's custom "Decorator" initialization pattern, which safely wires up dependent components when an entity template is instantiated.

---

## Key Components

### 1. `AccessibleInitializer`
This class implements `IDedicatedDecoratorInitializer<IAccessibleNeeder, Accessible>`. It serves as the bridge between a component that needs access and the access component itself.
* **Initialization Flow:** 1. It grabs the `AccessibleComponentName` string from the `IAccessibleNeeder`.
  2. It passes that name to `decorator.Initialize(...)`.
  3. It calls `subject.SetAccessible(decorator)`, officially linking the two together.

### 2. `AccessibleNavigationConfigurator` & `TemplateModuleProvider`
The configurator registers the initializer into the game's dependency injection container for the `Game` and `MapEditor` contexts.
* **TemplateModule:** It uses a provider to register the `AccessibleInitializer` into a `TemplateModule` via `builder.AddDedicatedDecorator(...)`. This tells Timberborn's prefab instantiation engine to run this initializer whenever it creates an entity that has both an `IAccessibleNeeder` and an `Accessible` component.

---

## How and When to Use This in a Mod

As a modder, you will almost never call or instantiate these classes directly. Instead, you **opt-in** to this system by implementing the `IAccessibleNeeder` interface on your custom components.

### Implementing a Custom Building that needs Access
If you are making a custom workplace, house, or attraction that a beaver needs to physically walk to, you will need to know where its entrance is. You can use this system to automatically grab the `Accessible` component on your prefab without writing manual `GetComponent` boilerplate.

**Usage Pattern:**
```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Navigation; // Note: You'll need the Timberborn.Navigation DLL

public class MyCustomWorkplace : BaseComponent, IAccessibleNeeder
{
    private Accessible _accessible;

    // 1. Fulfill the interface requirement by providing the name of the access point
    // This string is usually exposed in the Unity Inspector on the vanilla Accessible component
    public string AccessibleComponentName => "Entrance";

    // 2. The AccessibleInitializer (from this DLL) will automatically call this method 
    // when your building is spawned!
    public void SetAccessible(Accessible accessible)
    {
        _accessible = accessible;
    }

    public void DoWork()
    {
        // Now you can use _accessible safely!
        if (_accessible != null && _accessible.IsAccessible)
        {
            // Logic for beavers arriving...
        }
    }
}
```

---

## Modding Insights & Limitations

* **The Decorator Pattern:** This DLL showcases how Timberborn avoids standard Unity `Awake()` or `Start()` calls for dependency wiring between components on the same GameObject. By using `IDedicatedDecoratorInitializer`, Timberborn guarantees that components are initialized in the correct order and dependencies are injected safely.
* **No `GetComponent` Needed:** By implementing `IAccessibleNeeder`, you are allowing Timberborn's engine to hand you the `Accessible` component. This is significantly faster and safer than calling standard Unity component fetching methods.
* **Dependencies:** To fully utilize the logic demonstrated here, your mod project will also need references to `Timberborn.Navigation` (where `IAccessibleNeeder` and `Accessible` are actually defined) and `Timberborn.TemplateInstantiation`.
# Timberborn.BaseComponentSystem

## Overview
The `Timberborn.BaseComponentSystem` is the architectural foundation of Timberborn's entity logic. It provides a high-performance alternative to Unity's standard `MonoBehaviour` system by using a centralized `ComponentCache` and specialized lifecycle interfaces.

In Timberborn, most logic classes inherit from `BaseComponent` rather than `MonoBehaviour`. This allows the game to manage thousands of entities (beavers, crops, buildings) with significantly lower overhead than the native Unity component system.

---

## Key Components

### 1. `BaseComponent`
The primary base class for almost all modded logic. 
* **Properties**: Provides direct access to the `GameObject` and `Transform` of the entity via an internal cache.
* **State Management**: Includes `Enabled` state and methods like `EnableComponent()` and `DisableComponent()`.
* **Component Retrieval**: Provides optimized versions of Unity's component fetching methods.

### 2. `ComponentCache`
An internal `MonoBehaviour` attached to every entity that maintains a flat list (`ReadOnlyList<object>`) of every component, specification (Spec), and behavior attached to that entity.
* **Speed**: By using a `TypeIndexMap`, the cache allows for near-instant lookup of components by type, avoiding the overhead of Unity's native `GetComponent`.

### 3. Lifecycle Interfaces
To receive engine callbacks, a `BaseComponent` must implement one or more of the following interfaces:
* **`IAwakableComponent`**: Defines `Awake()`. Called when the entity is initialized or activated.
* **`IStartableComponent`**: Defines `Start()`. Called once when the component is enabled for the first time.
* **`IUpdatableComponent`**: Defines `Update()`. Executed every frame.
* **`ILateUpdatableComponent`**: Defines `LateUpdate()`. Executed after all standard updates.

---

## Component Retrieval: The Proper Patterns

Because Timberborn uses a custom cache, modders must follow specific patterns to fetch components from an entity.

### Standard Retrieval
Use `GetComponent<T>()` or `TryGetComponent<T>(out T component)`.
```csharp
// Fast, cached lookup
var hunger = GetComponent<HungerComponent>();
```

### The List Pattern (CRITICAL)
Timberborn's version of `GetComponents<T>` returns **void** and requires you to pass a pre-allocated list. This is a performance optimization to prevent garbage collection (GC) allocation.

```csharp
// PRE-ALLOCATE the list (ideally as a class member)
private readonly List<Workplace> _workplaces = new();

public void DoSomething() {
    _workplaces.Clear();
    // POPULATE the existing list
    GetComponents(_workplaces); 
    
    foreach(var work in _workplaces) { ... }
}
```
> [!CAUTION]
> Using `var results = GetComponents<T>();` will cause a compiler error (CS7036/CS0815) because the method returns `void`.

---

## How to Create a Custom Component

When writing a mod, your logic classes should look like this:

```csharp
using Timberborn.BaseComponentSystem;
using UnityEngine;

public class MyModLogic : BaseComponent, IAwakableComponent, IUpdatableComponent
{
    private MyOtherComponent _other;

    public void Awake() 
    {
        // Internal cache lookup
        _other = GetComponent<MyOtherComponent>();
    }

    public void Update() 
    {
        if (Enabled) 
        {
            Debug.Log("I am ticking!");
        }
    }
}
```

---

## Modding Insights & Limitations

* **Type Blacklist**: You cannot use `GetComponent` to fetch `BaseComponent`, `ComponentSpec`, or `object` types. This is strictly forbidden to prevent ambiguous lookups. Use `BaseComponent.AllComponents` if you need to iterate through every part of an entity.
* **Implicit Boolean Operators**: `BaseComponent` supports an implicit boolean operator. You can check `if (myBaseComponent)` to see if the underlying GameObject is still alive.
* **GameObject Extensions**: This DLL adds `GetComponentSlow<T>` and `GetComponentInParentSlow<T>` to standard Unity `GameObject` instances. These are "slow" because they must first fetch the `ComponentCache` before doing the lookup, but they are useful when interacting with non-BaseComponent code.
* **Efficiency**: Update loops for `BaseComponent` are managed by `BaseComponentUpdateUnityAdapter`. If a component is disabled via `DisableComponent()`, it is automatically removed from the update list, saving CPU cycles.
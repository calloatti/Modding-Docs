# Timberborn.DuplicationSystem

## Overview
The `Timberborn.DuplicationSystem` module provides the foundational logic for copying settings, states, and parameters from one game entity to another. This system is utilized when transferring configuration data, such as copying storage limits from one warehouse and applying them to another.

---

## Key Components

### 1. `Duplicator`
This is the core singleton class that executes the data copying process between entities.
* The `Duplicate` method accepts a `sourceEntity` and a `targetEntity`. 
* It iterates through every component attached to the `sourceEntity`.
* It uses C# Reflection (`MethodInfo.MakeGenericMethod` and `Invoke`) to dynamically call a generic duplication helper method for each component type found.
* Within the target entity, it searches for components that exactly match the `GetType()` of the source component.
* If the component implements `INamedComponent`, it verifies that the `ComponentName` property matches before executing the duplication.

### 2. `IDuplicable<T>`
This is the interface that components must implement if they support having their internal data copied.
* It requires the implementation of a `DuplicateFrom(T source)` method.
* The `T` generic parameter represents the specific type of the component being copied.

### 3. `DuplicationBlocker`
A marker component (`BaseComponent`) with an empty implementation. 
* Its presence on a prefab typically signals to external UI or tool systems that the entity should not be selectable for copy-pasting.

### 4. `DuplicationSystemConfigurator`
A standard Bindito configurator that registers the duplication classes.
* It operates within both the `Game` and `MapEditor` contexts.
* It binds `Duplicator` as a Singleton.
* It binds `DuplicationBlocker` as a Transient component.

---

## How to Use This in a Mod

### Making a Custom Component Duplicable
If you create a custom building with settings the player can configure, you can make those settings copy-pasteable by implementing `IDuplicable<T>`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.DuplicationSystem;

public class MyModHeater : BaseComponent, IDuplicable<MyModHeater> {
    public float TargetTemperature { get; private set; }

    public void SetTemperature(float temp) {
        TargetTemperature = temp;
    }

    // This is called automatically by the Duplicator
    public void DuplicateFrom(MyModHeater source) {
        SetTemperature(source.TargetTemperature);
    }
}
```

---

## Modding Insights & Limitations

* **Reflection Overhead**: The `Duplicator` heavily relies on reflection via `MethodInfo.Invoke`. Modders should avoid calling `Duplicator.Duplicate` inside high-frequency loops (like `Tick()`) to prevent performance degradation.
* **Strict Type Matching**: The system demands exact type matches using `GetType() == sourceComponent.GetType()`. It will not duplicate data from a base class to a derived class unless specifically handled by the developer.
* **Execution Order**: The component iteration relies on `targetEntity.AllComponents`. The order in which components are duplicated is not guaranteed, so `DuplicateFrom` logic should avoid relying on the initialization state of other components.

---

## Related dlls
* **Timberborn.BaseComponentSystem**: Provides the `BaseComponent` class and the `INamedComponent` interface used for strict component matching.
* **Timberborn.WorldPersistence**: Supplies the context for entity loading and saving, closely tied to how states are maintained post-duplication.
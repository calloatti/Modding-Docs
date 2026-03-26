# Timberborn.BlueprintPrefabSystem

## Overview
The `Timberborn.BlueprintPrefabSystem` is a small but foundational module that bridges the gap between raw data (JSON/Specs) and the Unity engine's physical object hierarchy. It is responsible for dynamically translating a data-driven `Blueprint`—which contains various `ComponentSpec` definitions and nested child blueprints—into an actual Unity `GameObject` tree. 

This system is essential for the game's modability and data-driven design, allowing complex entities to be constructed entirely from configuration files rather than hardcoded Unity Prefabs.

---

## Key Components

### 1. `BlueprintPrefabConverter`
This is the core factory class responsible for the actual generation of Unity objects. 
* **Dependency Injection**: It takes an `IEnumerable<ISpecToPrefabConverter>`, meaning it automatically gathers every spec converter registered in the game's dependency injection container.
* **Recursive Generation**: The `Convert(Blueprint blueprint, Transform parent)` method is recursive. It first generates a `GameObject` for the parent `Blueprint`, processes all of its specs, and then iterates through the `blueprint.Children` array, calling `Convert()` on each child and parenting them to the newly created `GameObject`.
* **Naming**: The newly created Unity `GameObject` is explicitly given the name defined by `blueprint.Name`.

### 2. `ISpecToPrefabConverter`
This is the interface that defines the translation logic for specific types of data. 
* **`CanConvert(ComponentSpec spec)`**: A boolean check that allows the converter to declare whether it knows how to handle the given spec.
* **`Convert(GameObject owner, ComponentSpec spec)`**: The execution method where the converter typically attaches a new Unity `Component` (or Timberborn `BaseComponent`) to the provided `GameObject` using the data from the `spec`.

### 3. `BlueprintPrefabSystemConfigurator`
A standard Bindito configurator that registers the `BlueprintPrefabConverter` as a Singleton in both the `Game` and `MapEditor` contexts. This ensures the conversion engine is available whenever a map is loaded or edited.

---

## The Conversion Pipeline (Under the Hood)
When the game needs to turn a Blueprint into a Prefab, the following sequence occurs inside `BlueprintPrefabConverter.Convert`:
1.  A new empty `GameObject` is instantiated.
2.  The `GameObject` is attached to the provided parent `Transform`.
3.  The system iterates over every `ComponentSpec` attached to the `Blueprint`.
4.  For *each* `ComponentSpec`, it loops through *every* registered `ISpecToPrefabConverter`.
5.  If a converter returns `true` for `CanConvert`, its `Convert` method is executed, attaching the physical logic to the `GameObject`.
6.  The system then loops through all child `Blueprint` objects and recursively repeats steps 1-5, building out the physical hierarchy.

---

## How to Use This in a Mod

Most modding in Timberborn relies on the `TemplateModule.Builder` to attach standard `BaseComponent` classes to `ComponentSpec` definitions. However, if your mod introduces a completely alien data structure or requires complex Unity-specific setup (like generating procedural meshes or deeply nested Unity hierarchies from a single spec) *before* standard ECS initialization occurs, you can implement your own `ISpecToPrefabConverter`.

### Creating a Custom Spec Converter
Here is an example of how you might create a custom converter that reads a custom spec and attaches a specific Unity component:

```csharp
using Timberborn.BlueprintPrefabSystem;
using Timberborn.BlueprintSystem;
using UnityEngine;

// 1. Define your custom data spec (loaded from JSON)
public record CustomModLightSpec : ComponentSpec
{
    public float LightRadius { get; init; }
    public Color LightColor { get; init; }
}

// 2. Create the Converter
public class CustomModLightConverter : ISpecToPrefabConverter
{
    public bool CanConvert(ComponentSpec spec)
    {
        // Only trigger if the spec is exactly our custom type
        return spec is CustomModLightSpec;
    }

    public void Convert(GameObject owner, ComponentSpec spec)
    {
        CustomModLightSpec lightSpec = (CustomModLightSpec)spec;
        
        // Attach a standard Unity Light component based on the JSON data
        Light unityLight = owner.AddComponent<Light>();
        unityLight.type = LightType.Point;
        unityLight.range = lightSpec.LightRadius;
        unityLight.color = lightSpec.LightColor;
    }
}
```

You would then bind this in your configurator so the `BlueprintPrefabConverter` picks it up:
```csharp
using Bindito.Core;
using Timberborn.BlueprintPrefabSystem;

[Context("Game")]
internal class MyModConfigurator : Configurator
{
    protected override void Configure()
    {
        // MultiBind it to the ISpecToPrefabConverter interface
        MultiBind<ISpecToPrefabConverter>().To<CustomModLightConverter>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **O(N*M) Complexity Per Blueprint**: The `Convert` method uses nested loops. For *every* spec on a blueprint, it checks *every* single `ISpecToPrefabConverter` registered in the game. If modders indiscriminately add hundreds of custom converters, it could theoretically impact game load times when parsing complex blueprints.
* **No Short-Circuiting**: Notice that inside `BlueprintPrefabConverter.Convert`, when a converter's `CanConvert` returns true and `Convert` is executed, there is no `break` statement. The loop continues to check all other converters against the exact same spec. This means *multiple* converters can react to a single `ComponentSpec` if they choose to, which is powerful but requires modders to be precise in their `CanConvert` logic to avoid accidentally double-processing specs.
* **Pure Unity Context**: This module sits extremely low in the initialization order. It strictly deals with `GameObject` and `Transform` objects. Standard Timberborn `BaseComponent` lifecycle events (like `Awake()`, `Start()`) are not managed here; this system merely sets up the physical Unity hierarchy so that the subsequent Template and Component Cache systems can take over.
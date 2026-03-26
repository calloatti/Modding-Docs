# Timberborn.BlueprintSystem

## Overview
The `Timberborn.BlueprintSystem` is the data-driven backbone of Timberborn's entity creation architecture. Instead of hardcoding behaviors onto Unity GameObjects or Prefabs, the game defines entities (buildings, natural resources, even UI elements) as `Blueprint` objects loaded from external JSON files. This module handles the loading, parsing, deserialization, and caching of these blueprint files, making it the most critical system for modders wanting to add or modify game content.

---

## Key Components

### 1. `Blueprint` & `ComponentSpec`
These are the core data containers.
* **`Blueprint`**: Represents a complete entity definition. It holds a `Name`, an array of `ComponentSpec` definitions, and an array of nested `Children` Blueprints.
* **`ComponentSpec`**: An abstract `record` representing a specific set of configurations (e.g., `WaterPumpSpec`, `GatheringFlagSpec`). Because these are C# `record` types, they are highly optimized for data storage and serialization.

### 2. `SpecService` (The Central Registry)
This singleton is the primary entry point for fetching blueprint data.
* **Initialization**: During `Load()`, it asks the `BlueprintFileBundleLoader` for all blueprints, deserializes them, and caches them.
* **Caching Strategy**: It caches blueprints by their file path (`_cachedBlueprintsByPath`) and, crucially, by the types of `ComponentSpec` they contain (`_cachedBlueprintsBySpecs`).
* **Retrieval**: Modders use `GetSingleSpec<T>()` or `GetSpecs<T>()` to retrieve parsed configurations without needing to know the file path.

### 3. `BlueprintDeserializer` & Friends
A multi-layered system responsible for turning raw JSON text into C# objects.
* **`BasicDeserializer`**: Handles standard properties using reflection to match JSON keys to C# property names.
* **`AdvancedDeserializer`**: Uses the `[Serialize]` attribute to map data to different fields if the JSON structure doesn't perfectly match the target C# class structure (using the `SourceName` property).
* **`AssetRefDeserializer`**: Specifically handles loading Unity assets (like Meshes, Sprites, or Materials) referenced by path strings in the JSON via the `IAssetLoader`.

### 4. `SpecTypeCache`
This class scans the entire AppDomain during creation (`SpecTypeCache.Create()`) to find every class that inherits from `ComponentSpec`. It maps the class name (or custom aliases defined by `[SpecAlias]`) to the actual C# `Type`. This allows the deserializer to see a JSON key like `"WaterPumpSpec"` and instantly know which C# class to instantiate.

---

## The Modding Pipeline: Injecting Custom Specs

If you want to create a custom building with new behavior, you don't use Unity Editor tools; you write a C# `ComponentSpec` and a corresponding JSON file.

### 1. Define the C# Spec
Create a `record` that inherits from `ComponentSpec`. Use the `[Serialize]` attribute on properties you want to read from the JSON.
```csharp
using Timberborn.BlueprintSystem;

public record MyCustomHeaterSpec : ComponentSpec
{
    [Serialize]
    public float HeatRadius { get; init; }
    
    [Serialize]
    public int MaxFuelCapacity { get; init; }
}
```

### 2. Create the JSON File
Create a `.blueprint` or `.blueprint.json` file in your mod's asset folder. The key *must* match the name of your C# class.
```json
{
  "MyCustomHeaterSpec": {
    "HeatRadius": 15.5,
    "MaxFuelCapacity": 100
  },
  "BlockObjectSpec": {
    // ... standard block object data ...
  }
}
```

### 3. Fetching the Spec
The game will automatically discover your JSON and your C# class, linking them together. In your behavior logic (usually a `BaseComponent`), you fetch the spec during `Awake()`:
```csharp
using Timberborn.BaseComponentSystem;

public class MyCustomHeaterLogic : BaseComponent, IAwakableComponent
{
    private MyCustomHeaterSpec _heaterSpec;

    public void Awake()
    {
        // The BaseComponent system automatically links the instantiated object
        // back to the Blueprint that created it.
        _heaterSpec = GetComponent<MyCustomHeaterSpec>();
        
        // You can now use _heaterSpec.HeatRadius in your logic
    }
}
```

---

## Dynamic Blueprint Modification (Advanced)
Timberborn allows mods to alter existing blueprints without replacing the original files via `IBlueprintModifierProvider`.

During `SpecService.Deserialize`, the game loops through all registered `IBlueprintModifierProvider`s. If a provider returns modification JSON strings for a specific `blueprintPath`, that JSON is literally appended to the `BlueprintFileBundle` before deserialization.

```csharp
using System.Collections.Generic;
using Timberborn.BlueprintSystem;

public class MakeEverythingBurnModifier : IBlueprintModifierProvider
{
    public string ModifierName => "Make Everything Burn";

    public IEnumerable<string> GetModifiers(string blueprintPath)
    {
        // Add a fictional flammable spec to every building
        if (blueprintPath.StartsWith("Buildings/"))
        {
            yield return "{\"FlammableSpec\": { \"BurnTime\": 10 }}";
        }
    }
}
```

---

## Modding Insights & Limitations

* **Immutability Principle**: Note that `ComponentSpec` implementations are `record` types with `init` properties, and collections inside specs (like arrays of nested objects) are strictly `ImmutableArray<T>`. You cannot modify a spec's data at runtime after it has been loaded and cached by the `SpecService`.
* **Missing Type Handling**: If the `BlueprintDeserializer` encounters a JSON key it cannot map to a C# `Type` using the `SpecTypeCache`, its behavior depends on whether it is running in 'safe' mode. In safe mode, it creates a `NonExistingSpec` containing the raw JSON content. In unsafe mode (standard game load), it explicitly throws an `ArgumentException("No type found for key...")` and aborts. Modders must ensure their assembly is loaded *before* blueprint deserialization if they include custom specs.
* **Nested Blueprints Limit**: The system supports nesting blueprints via the `Children` property or the specialized `NestedBlueprintSpec`. However, `DeserializeNestedBlueprint` explicitly tracks the path stack (`nestedBlueprints.Contains(text)`) and will throw an `InvalidOperationException` if a circular reference is detected (e.g., A spawns B, B spawns A).
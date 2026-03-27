# Timberborn.Common

## Overview
The `Timberborn.Common` module is a foundational utility library that provides core data structures, extension methods, randomization wrappers, and mathematical helpers used throughout the entire game. It acts as the bedrock for performance-critical systems, offering memory-safe collection alternatives, rigid assertion testing, and deterministic random number generation.

---

## Key Components

### 1. Specialized Data Structures
Timberborn avoids standard C# collections in specific scenarios to improve memory management and performance.
* **`ReadOnlyList<T>` & `ReadOnlyHashSet<T>`**: Custom read-only wrappers that safely expose internal collections to other systems without allocating new arrays or risking unauthorized modifications.
* **`Array3D<T>`**: A generic three-dimensional grid structure (`TValue[,,]`) initialized with a default value provider, heavily utilized for voxel-like map data and fluid simulation tracking.
* **`BufferedArray<T>`**: Implements a double-buffering pattern containing a `_current` array and a `_buffered` array. This allows multithreaded or tick-based systems to read from one state while writing to the next, swapping them cleanly via the `Swap()` method.
* **`CyclicBuffer<T>`**: A fixed-size queue that automatically dequeues the oldest item when the capacity `_size` is reached, useful for rolling logs or temporary history states.

### 2. Extension Methods & Performance Helpers
The module includes numerous extension classes designed to reduce Garbage Collection (GC) spikes and simplify grid math.
* **`FastCollectionExtensions`**: Offers allocation-free alternatives to standard LINQ methods, such as `FastCount`, `FastAny`, and `FastContains`. These methods use standard `for` loops rather than `IEnumerator` interfaces, entirely avoiding the garbage collection overhead of standard delegates.
* **`VectorExtensions`**: Adds crucial spatial grid helpers for Timberborn's 3D architecture, such as `Above()` (which adds 1 to the Z-axis) and `Below()` (which subtracts 1 from the Z-axis). It also provides quick stripping methods like `XY()` to flatten a 3D coordinate into 2D.
* **`GameObjectExtensions`**: Provides recursive search functions like `FindChildTransform`. Unlike standard Unity methods, if the child is not found, this extension throws a highly descriptive `NullReferenceException` to immediately halt execution and aid debugging.

### 3. Random Number Generation (RNG)
The game abstracts randomness to support both unpredictable gameplay elements and deterministic map generation.
* **`IRandomNumberGenerator`**: An interface defining common random operations like `Range`, `InsideUnitCircle`, and `CheckProbability`.
* **`RandomNumberGenerator`**: The standard implementation that simply wraps Unity's built-in `UnityEngine.Random` class for generic, non-synchronized randomness.
* **`FakeRandomNumberGenerator`**: A deterministic RNG implementation that generates floats and bytes based on a static hash code, bit-shifted by an index.
* **`FakeRandomNumberGeneratorFactory`**: Creates instances of the deterministic RNG by seeding it with a specific `Guid` and salt. This ensures that procedurally generated elements (like map resources or specific visual variations) always load the exact same way for every player using the same seed.

### 4. Custom Assertions (`Asserts.cs`)
Timberborn uses a custom defensive programming library to validate data states during initialization and runtime.
* **Validation**: It provides methods like `FieldIsNull`, `CollectionIsNotEmpty`, and `ValueIsInRange`.
* **Feedback**: When an assertion fails, it throws an explicit `InvalidOperationException` or `ArgumentException`. It uses `GetObjectName(owner)` to prepend the exact Unity `MonoBehaviour` name to the error string, making it immediately obvious which specific entity in the scene is misconfigured.

---

## How to Use This in a Mod

### Utilizing Safe Randomness
Instead of calling `UnityEngine.Random.Range()` directly, modders should rely on Dependency Injection to retrieve the `IRandomNumberGenerator`. This guarantees that if Timberborn ever shifts to a fully deterministic multiplayer model, your mod won't cause desyncs.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Common;
using UnityEngine;

public class MyCustomSpawner : BaseComponent
{
    private IRandomNumberGenerator _rng;

    [Inject]
    public void InjectDependencies(IRandomNumberGenerator rng)
    {
        _rng = rng;
    }

    public void SpawnRandomItem()
    {
        // Generates a float between 1.0 and 5.0
        float randomDelay = _rng.Range(1f, 5f);
        
        // 25% chance to spawn a rare item
        if (_rng.CheckProbability(0.25f))
        {
            SpawnRareItem();
        }
    }
}
```

### Leveraging Vector Extensions for Grid Math
If you are building logic that scans the environment (like a modded pump checking for water), use `VectorExtensions` to keep your coordinate math clean.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Common;
using UnityEngine;

public class CustomPump : BaseComponent
{
    public void CheckPipeClearance(Vector3Int pumpCoordinates)
    {
        // Automatically returns (X, Y, Z - 1)
        Vector3Int tileBelow = pumpCoordinates.Below(); 
        
        // Automatically returns (X, Y, Z + 1)
        Vector3Int tileAbove = pumpCoordinates.Above(); 
        
        // Strip the Z height completely for 2D distance checks
        Vector2Int flatCoordinates = pumpCoordinates.XY();
    }
}
```

---

## Modding Insights & Limitations

* **Performance Over LINQ**: You will notice standard LINQ (`.Where()`, `.Select()`, `.Any()`) is rarely used in high-frequency Timberborn update loops. Modders writing `TickableComponents` should heavily prefer the methods inside `FastCollectionExtensions` (like `FastCount` and `FastAny`) to prevent your mod from causing micro-stutters during Garbage Collection.
* **Strict Structs**: Classes like `BoundingBox`, `ReadOnlyArray`, and `ReadOnlyList` are defined as `readonly struct`. This means they are value types passed by copy, not by reference, which avoids heap allocations but requires careful handling to avoid unnecessary copying overhead for very large sets.
* **Backward Compatibility Attributes**: The `[BackwardCompatible]` attribute is explicitly defined here and used across the codebase. Modders inspecting Timberborn's save/load methods will frequently see this applied to legacy property keys, informing the deserializer how to handle save files from older versions of the game.
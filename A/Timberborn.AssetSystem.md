# Timberborn.AssetSystem

## Overview
The `Timberborn.AssetSystem` module is a foundational system responsible for loading Unity assets (such as Prefabs, Textures, AudioClips, and Meshes) dynamically at runtime. 

Instead of relying on hardcoded calls to Unity's `Resources.Load`, Timberborn uses an `IAssetLoader` that aggregates assets from multiple `IAssetProvider` sources. This architecture is what makes modding possible: it allows custom mod providers to "override" vanilla game assets by supplying assets with a higher priority order.


---

## Key Components

### 1. `IAssetLoader` / `AssetLoader` (The Main Service)
This is the core service you will inject into your mod classes when you need to retrieve an asset.
* **Mechanics:** When you call `Load<T>(path)` or `LoadSafe<T>(path)`, the `AssetLoader` normalizes the path and iterates through a collection of registered `IAssetProvider` instances.
* **Override Logic:** It asks each provider if they have the asset via `TryLoad<T>`. Providers return an `OrderedAsset` struct. The loader keeps track of the highest `Order` it finds, ensuring that the asset with the highest priority wins.
* **`LoadAll<T>`:** Gathers all matching assets from all providers, wraps them in `LoadedAsset<T>` structs (which hold the asset, a boolean `IsBuiltIn` flag, and the `Order`), and returns them ordered by their priority.

### 2. `IAssetProvider` & `ResourceAssetProvider`
An `IAssetProvider` represents a source of assets. 
* **`ResourceAssetProvider`:** This is the default vanilla implementation provided in this DLL. It simply wraps Unity's native `Resources.Load<T>` and `Resources.LoadAll<T>` methods.
* **Priority Order:** The `ResourceAssetProvider` assigns an `Order` of `-1` to all vanilla assets it provides. 

### 3. `AssetPathHelper`
A static utility class that standardizes asset paths. 
* **Normalization:** It converts backslashes (`\`) to forward slashes (`/`), converts all characters to lowercase, and strips out file extensions.
* **Prefix Stripping:** It also removes the `assets/` and `resources/` prefixes from paths so they can be matched cleanly.

### 4. `BinaryData`
A simple `MonoBehaviour` that stores a raw byte array (`byte[] _bytes`). This can be used to attach binary files or custom serialized data directly onto Unity prefabs.

---

## How and When to Use This in a Mod

### 1. Loading an Asset
Whenever you need to instantiate a prefab or grab a sprite dynamically, you should inject `IAssetLoader`.

```csharp
using Timberborn.AssetSystem;
using UnityEngine;

public class MyModSpawner
{
    private readonly IAssetLoader _assetLoader;

    // Inject the loader
    public MyModSpawner(IAssetLoader assetLoader)
    {
        _assetLoader = assetLoader;
    }

    public void SpawnCustomBeaver()
    {
        // 1. Ask the loader for the asset. 
        // It will automatically check vanilla resources AND mod bundles.
        GameObject beaverPrefab = _assetLoader.Load<GameObject>("Path/To/BeaverPrefab");
        
        // 2. Instantiate it
        GameObject.Instantiate(beaverPrefab);
    }
}
```

### 2. Creating a Custom Mod Asset Provider
If your mod includes custom Unity AssetBundles, you will need to create your own `IAssetProvider` and bind it into the `Bootstrapper` context.

```csharp
using System.Collections.Generic;
using Timberborn.AssetSystem;
using UnityEngine;

public class MyModAssetProvider : IAssetProvider
{
    // Mark as false since these are modded assets, not vanilla
    public bool IsBuiltIn => false; 

    public bool TryLoad<T>(string path, out OrderedAsset orderedAsset) where T : Object
    {
        // Add your logic to check your loaded AssetBundles for the requested path.
        T myModdedAsset = FindInMyAssetBundle<T>(path);
        
        if (myModdedAsset != null)
        {
            // Give it an order > -1 to OVERRIDE vanilla assets!
            // E.g., an order of 10 ensures it beats ResourceAssetProvider's -1.
            orderedAsset = new OrderedAsset(10, myModdedAsset);
            return true;
        }

        orderedAsset = default;
        return false;
    }

    public IEnumerable<OrderedAsset> LoadAll<T>(string path) where T : Object
    {
        // Return all matching assets from your bundle, wrapped in OrderedAsset structs
        yield break; 
    }

    public void Reset() { /* Cleanup if necessary */ }
    
    private T FindInMyAssetBundle<T>(string path) where T : Object
    {
        // Pseudo-code for AssetBundle fetching
        return null;
    }
}
```

Register this provider in your configurator:

```csharp
using Bindito.Core;
using Timberborn.AssetSystem;

[Context("Bootstrapper")]
public class MyModAssetConfigurator : Configurator
{
    protected override void Configure()
    {
        // Bind to IAssetProvider using MultiBind so it joins the collection 
        // that AssetLoader loops through!
        MultiBind<IAssetProvider>().To<MyModAssetProvider>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **The Bootstrapper Context:** Notice that `AssetSystemConfigurator` uses `[Context("Bootstrapper")]`. This means the asset system is initialized before almost everything else in the game. If you are registering a custom `IAssetProvider`, you **must** bind it in the `Bootstrapper` context, otherwise it will be ignored by the `AssetLoader` during the initial game loading sequence.
* **Overriding Vanilla Behavior:** The `AssetLoader` strictly obeys the `Order` property. Because `ResourceAssetProvider` assigns an order of `-1`, any custom provider that returns an `OrderedAsset` with an `Order` of `0` or higher for the same path string will successfully override the vanilla asset.
* **File Extensions:** Do not include file extensions (like `.prefab` or `.png`) when calling `Load<T>()`. `AssetPathHelper.NormalizePath()` strips them out, and Unity's `Resources.Load()` does not support them.
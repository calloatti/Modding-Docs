# Timberborn.ApplicationLifetime

## Overview
The `Timberborn.ApplicationLifetime` module is a core infrastructure DLL that handles events and configurations occurring at the very beginning (boot) and the very end (shutdown) of the game. 

It contains vital setup logic that executes before any Unity scene is loaded, making it a foundational piece of Timberborn's architecture.

---

## Key Components

### 1. `CultureInitializer`
This static class ensures that Timberborn's internal data processing is immune to regional operating system settings.
* **Mechanism:** It uses Unity's `[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]` attribute to run automatically before the game even starts.
* **Action:** It forcefully sets `CultureInfo.DefaultThreadCurrentCulture` and `CultureInfo.DefaultThreadCurrentUICulture` to `CultureInfo.InvariantCulture`.
* **Why this matters for modders:** Because the game forces `InvariantCulture`, operations like `float.Parse("1.5")` or `myFloat.ToString()` will *always* use a period (`.`) as the decimal separator, regardless of whether the player's Windows OS is set to German, French, or Spanish (which typically use a comma `,`). You do not need to worry about writing regional-safe parsing logic when reading your own mod configuration files.

### 2. `GameStartLogger`
This static class runs at the same early stage (`BeforeSceneLoad`) and dumps critical diagnostic information to the Unity `Player.log`.
* **Logged Info:** It records the game version, OS, CPU model, core count, GPU model, VRAM, and System RAM. It also generates/retrieves a persistent `MachineId` using Unity's `PlayerPrefs`.
* **Modding Tie-in:** Crucially, this class calls `ExternalModFinder.CheckForMods()`. This means the game's native mod discovery system is initialized and scans the user's mod directory immediately upon boot, before any scenes or configurators run.

### 3. `GameQuitter`
A simple static wrapper around Unity's shutdown command.
* **Action:** Contains a single method, `Quit()`, which executes `Application.Quit()`.

---

## How and When to Use This in a Mod

As a modder, you will rarely, if ever, directly interact with or reference this DLL. Its methods are static, run automatically, and handle tasks that are already "solved" for you.

### Bootstrapping Mod Logic (Observation)
While you shouldn't modify this DLL, it teaches you how to run code *before* Timberborn's dependency injection (`Bindito`) kicks in. 
If your mod requires incredibly early initialization (e.g., patching a Unity engine method before the game starts, or pre-loading a native C++ DLL), you can use the same Unity attribute found here:

```csharp
using UnityEngine;

public static class MyModEarlyBootstrapper
{
    // This will run at the exact same time as CultureInitializer and GameStartLogger
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    public static void EarlyInit()
    {
        Debug.Log("My Mod is running extremely early setup logic!");
        // Perform pre-DI operations here
    }
}
```

---

## Modding Insights & Limitations

* **No Dependency Injection:** Because these classes run `BeforeSceneLoad`, they cannot participate in Timberborn's standard dependency injection (`Configurator` / `Bindito`). They are entirely static and decoupled from the rest of the game's architecture.
* **Safe Number Parsing:** Thanks to `CultureInitializer`, you can confidently use standard C# string interpolation (`$"{myFloat}"`) and parsing without fear of breaking on international keyboards.
# Timberborn.Autosaving

## Overview
The `Timberborn.Autosaving` module is the core logic assembly responsible for the game's automatic save functionality. It manages the timing frequency of saves, generates standardized filenames based on both real-world time and in-game dates, performs cleanup of old autosaves, and ensures an "exit save" is created when the player leaves the game.

For modders, this module provides the hooks necessary to prevent autosaving during critical operations and to listen for the results of the save process.

---

## Key Components

### 1. `Autosaver` (The Central Manager)
The `Autosaver` is a singleton that drives the entire process. 
* **Frequency Logic**: It reads `AutosaverSpec` to determine how often to save (using `FrequencyInMinutes`). It tracks timing using Unity's `Time.unscaledTime` to ensure saves occur consistently regardless of game speed or pausing.
* **Safety Checks**: Before saving, it iterates through all registered `IAutosaveBlocker` instances. If any blocker returns `IsBlocking == true`, the save is postponed.
* **Cleanup**: To prevent hard drive bloat, it automatically deletes older autosaves once the count exceeds `AutosavesPerSettlement` (default behavior is typically set in the game's configuration files).

### 2. `IAutosaveBlocker` (The Safety Switch)
This interface allows other systems to "veto" an autosave attempt.
* **Usage**: If a mod is performing a complex, non-thread-safe operation or is in a state where the data might be corrupted if saved mid-frame, it should implement this interface and register it via `MultiBind`.

### 3. `AutosaveNameService` (Naming Conventions)
This service ensures all autosaves follow a strict naming convention.
* **Format**: It combines a real-world timestamp (`yyyy-MM-dd HHhmmm`) with the in-game date (`Cycle X, Day Y`) and a specific `.autosave` suffix.

### 4. `AutosaveEvent`
A simple event object posted to the `EventBus` whenever an autosave attempt finishes. It carries a `Successful` boolean and a `GameSaverException` if the save failed (e.g., due to a full disk).

---

## How to Use This in a Mod

### 1. Blocking Autosaves
If your mod has a critical section where saving should be disabled (e.g., during a custom map generation step or a massive data migration), you can add a blocker.

```csharp
using Timberborn.Autosaving;
using Timberborn.SingletonSystem;

public class MyModSaveBlocker : IAutosaveBlocker, ILoadableSingleton
{
    public bool IsBlocking { get; private set; }

    public void StartCriticalWork() => IsBlocking = true;
    public void EndCriticalWork() => IsBlocking = false;

    public void Load() { /* Initialization logic */ }
}

// In your Configurator:
// MultiBind<IAutosaveBlocker>().To<MyModSaveBlocker>().AsSingleton();
```

### 2. Reacting to Saves
You can listen for `AutosaveEvent` to trigger logic after the game successfully saves itself.

```csharp
using Timberborn.Autosaving;
using Timberborn.SingletonSystem;

public class MySaveListener : ILoadableSingleton
{
    private readonly EventBus _eventBus;

    public MySaveListener(EventBus eventBus)
    {
        _eventBus = eventBus;
    }

    public void Load() => _eventBus.Register(this);

    [OnEvent]
    public void OnAutosave(AutosaveEvent autosaveEvent)
    {
        if (autosaveEvent.Successful)
        {
            // Logic for successful save
        }
    }
}
```

---

## Modding Insights & Limitations

* **Exit Saves**: The module includes an `AutosaverUnityAdapter` which hooks into `OnApplicationQuit`. This ensures that even if a player crashes or hard-quits, the game attempts to create one final save as long as a settlement is currently loaded.
* **Unscaled Time**: Because `Autosaver` uses `Time.unscaledTime`, the "Frequency in Minutes" setting in the game options refers to real-world minutes, not in-game minutes.
* **Cleanup Failure**: The system includes a fail-safe: if it fails to delete at least 3 excess autosaves, it throws an `InvalidOperationException`. This is a diagnostic measure to ensure the player's disk doesn't fill up silently due to permission errors.
* **Context**: This system is only bound in the `Game` context. It does not run in the Main Menu or the Map Editor.
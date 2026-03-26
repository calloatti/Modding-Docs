# Timberborn.AutosavingUI

## Overview
The `Timberborn.AutosavingUI` module is the presentation and user-interaction layer for the game's automatic saving system. While the simulation logic lives in `Timberborn.Autosaving`, this DLL handles player-facing notifications (success/failure) and implements specific logic to block autosaves based on the state of the UI (e.g., when specific menus are open or when the feature is disabled in settings).

---

## Key Components

### 1. `AutosaveNotifier`
This singleton listens for the results of an autosave attempt via the `EventBus`.
* **Feedback:** It uses `QuickNotificationService` to display a small toast notification to the player upon success or a warning upon failure.
* **Error Handling:** It contains specific logic to detect if a save failed due to a full disk by checking the `HResult` of the underlying `IOException` (error codes 39 and 112).

### 2. `PanelAutosaveBlocker`
This class implements the `IAutosaveBlocker` interface to prevent the game from saving during sensitive UI interactions.
* **Logic:** It listens for `PanelShownEvent` and `PanelHiddenEvent`. If a panel is shown that requires locking the game speed (`LockSpeed`), it sets `IsBlocking` to true, effectively pausing the `Autosaver` timer.

### 3. `SettingsAutosaveBlocker`
This component ensures that the `Autosaver` respects the player's choices in the Options menu.
* **Synchronization:** It injects `GameSavingSettings` and reacts to the `AutoSavingOnChanged` event. If the player disables autosaving in the settings, this component permanently returns `IsBlocking == true` to the saving service.

---

## How and When to Use This in a Mod

### Creating a Custom UI Save Blocker
If your mod introduces a complex UI (like a blueprint editor or a detailed statistics screen) that pauses the game and should not be interrupted by an autosave, you should implement a custom `IAutosaveBlocker`.

**Example Implementation:**
```csharp
using Timberborn.Autosaving;
using Timberborn.SingletonSystem;

public class MyModMenuBlocker : IAutosaveBlocker, ILoadableSingleton
{
    // Return true to prevent the game from attempting an autosave
    public bool IsBlocking { get; private set; }

    public void Load() 
    {
        // Initialization logic
    }

    public void ToggleMenu(bool isOpen)
    {
        IsBlocking = isOpen;
    }
}
```

To register this, add it to your mod's `Configurator`:
```csharp
protected override void Configure()
{
    Bind<MyModMenuBlocker>().AsSingleton();
    MultiBind<IAutosaveBlocker>().ToExisting<MyModMenuBlocker>();
}
```

---

## Modding Insights & Limitations

* **Notification Keys:** The module relies on specific localization keys for its messages: `Autosave.Success`, `Autosave.Failure`, and `Autosave.FailureDueToFullDisk`. Modders can override these strings in their own localization files to customize save messages.
* **HResult Mapping:** The check for full disks (`(ex.HResult & 0xFFFF) == 112`) is a low-level way to identify "Disk Full" errors in Windows/Mono environments. If you are writing a mod that performs its own file I/O, this is a useful pattern to replicate for robust error reporting.
* **Context Restriction:** Like the logical system, this UI module is bound only in the `Game` context. It will not be active in the Main Menu or Map Editor scenes.
* **Speed Lock Integration:** Note that `PanelAutosaveBlocker` doesn't just block on *any* panel; it specifically blocks when `panelShownEvent.LockSpeed` is true. This implies the developers want to avoid saving while the game is "hard-paused" by a modal UI.

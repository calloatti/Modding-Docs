# Timberborn.Debugging

## Overview
The `Timberborn.Debugging` module provides the core framework for managing "Debug Mode" and "Dev Mode" within the game. It acts as a gateway for developers and modders to enable diagnostic features, unlock hidden tools, and register custom developer methods that can be executed during gameplay.

---

## Key Components

### 1. Debug and Dev Mode Managers
The system differentiates between two primary elevated states:
* **`DebugModeManager`**: Manages the "Debug Mode" state. When enabled, it posts a `DebugModeToggledEvent`. This mode typically reveals technical data like coordinate readouts or grid overlays.
* **`DevModeManager`**: Manages the more powerful "Dev Mode" state. Enabling this mode also updates the `CrashSceneLoader.DevModeEnabled` flag, allowing for specialized error handling. It posts a `DevModeToggledEvent` upon state changes.

### 2. Controllers and Input Handling
* **`DebugModeController` & `DevModeController`**: These classes implement `IPriorityInputProcessor` to listen for specific key bindings (e.g., `ToggleDebugMode` and `ToggleDevMode`) to flip the respective mode states.
* **`DevModeKeyBindingBlocker`**: A safety utility that implements `IKeyBindingBlocker`. It ensures that any hotkey flagged as `DevModeOnly` in the keybinding system will only function if the `DevModeManager` is currently active.

### 3. Developer Modules (`IDevModule`)
This is the primary extensibility point for adding developer tools.
* **`DevMethod`**: A wrapper for a C# `Action` that can be named and optionally bound to a hotkey. When executed, it logs "Dev mode: [Method Name]" to the Unity console before running the action.
* **`DevModuleDefinition`**: A builder-pattern object used to group multiple `DevMethod` instances together.
* **`TestExceptionDevModule`**: A built-in example module. If the game is a development version, it provides methods to intentionally throw exceptions, trigger native aborts (crashes), or log test warnings to verify error-reporting systems.

---

## How to Use This in a Mod

Modders can create their own developer tools by implementing the `IDevModule` interface and registering it via Bindito.

### Creating a Custom Dev Module
```csharp
using Timberborn.Debugging;
using UnityEngine;

public class MyModDevModule : IDevModule
{
    public DevModuleDefinition GetDefinition()
    {
        return new DevModuleDefinition.Builder()
            .AddMethod(DevMethod.Create("Give 1000 Logs", GiveLogs))
            .AddMethod(DevMethod.Create("Destroy All Beavers", KillEveryone))
            .Build();
    }

    private void GiveLogs() { /* logic here */ }
    private void KillEveryone() { /* logic here */ }
}
```

### Registration in Configurator
To make your module appear in the dev menu, you must multi-bind it:
```csharp
[Context("Game")]
internal class MyModConfigurator : Configurator
{
    protected override void Configure()
    {
        MultiBind<IDevModule>().To<MyModDevModule>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Context Sensitivity**: The `DebuggingConfigurator` is registered in `MainMenu`, `Game`, and `MapEditor` contexts. This means dev tools can be written to function even before a save file is loaded.
* **Silently Enabling Dev Mode**: The `DevModeManager` contains an internal `EnableSilently()` method. This is used to set the state and post the event without printing the "Dev mode enabled" message to the Unity log.
* **Development Version Check**: Many built-in dev methods (like those in `TestExceptionDevModule`) are wrapped in checks for `GameVersions.CurrentVersion.IsDevelopmentVersion`. Modders should decide if their tools should be available in "stable" releases or only during their own internal testing.
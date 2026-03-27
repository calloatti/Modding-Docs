# Timberborn.Console

## Overview
The `Timberborn.Console` module provides a dedicated in-game UI panel to display Unity application logs (Info, Warnings, and Errors) to the player. This is primarily designed as a diagnostic tool for developers and modders, allowing them to view output without tabbing out to the external `Player.log` file.

---

## Key Components

### 1. `ConsoleLogListener`
This static class acts as a global interceptor for Unity's native logging system.
* **Interception**: It registers to `Application.logMessageReceived` during `RuntimeInitializeOnLoadMethod` (meaning it starts running before any scenes even load).
* **Storage**: It maintains a fixed-size `Queue<Log>` with a `MaxLogs` limit of 1000. This acts as a rolling buffer, ensuring the game's memory doesn't bloat if an error spams millions of lines.
* **Event Dispatching**: When it receives a log, it wraps it in a custom `Log` struct and fires `OnLogReceived`. If the log is a Warning or Error, it sets `AnyWarningOrError = true` and fires `OnFirstWarningOrErrorReceived`.

### 2. `ConsolePanel`
This class handles the actual rendering and interaction of the in-game console UI.
* **Initialization**: Loaded into the `Common/Console/ConsoleContainer` visual element, it implements `ILateUpdatableSingleton` to handle incoming log rendering.
* **Concurrency Handling**: Because `Application.logMessageReceived` can fire from background threads (like Unity's physics or asset loading threads), `ConsolePanel` uses a `ConcurrentQueue<Log>` to safely buffer incoming messages. During `LateUpdateSingleton` (which runs on the main thread), it dequeues these logs and appends them to the UI text field.
* **Auto-Open Logic**: If `GameVersions.CurrentVersion.IsDevelopmentVersion` is true (typically meaning the game is being played on an Experimental branch), the console will automatically open itself the moment the first Warning or Error is logged.
* **UI Management**: It limits the text field to `MaxCharacters = 20000` to prevent the UI layout engine from crashing. It uses HTML color tags to color-code logs (`<color=#ff0000>` for errors, `<color=#ffffff>` for info). It also provides a button that calls `IExplorerOpener.OpenDirectory()` to open the user's OS file explorer directly to the folder containing `Player.log`.

### 3. `ConsoleConfigurator`
A standard Bindito configurator that registers the `IConsolePanel` singleton. Notably, it is registered across all three major contexts: `[Context("MainMenu")]`, `[Context("Game")]`, and `[Context("MapEditor")]`. This guarantees the console can be opened at any point during gameplay.

---

## How to Use This in a Mod

### Logging Custom Information
Modders do not need to interact with the `Timberborn.Console` module directly to print messages to it. Because `ConsoleLogListener` intercepts standard Unity logs, any log written using Unity's native `Debug` class will automatically appear in this UI panel.

```csharp
using UnityEngine;

public class MyModManager
{
    public void InitializeMod()
    {
        // This will appear as white text in the in-game console
        Debug.Log("My Mod initialized successfully.");
        
        // This will appear as yellow text
        Debug.LogWarning("My Mod couldn't find an optional config file.");
        
        // This will appear as red text and force the console to open on Experimental branches
        Debug.LogError("My Mod critically failed!");
    }
}
```

### Forcing the Console Open
If your mod provides a custom "Debug Menu" and you want to offer a button that forces the console open, you can inject `IConsolePanel`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.Console;

public class MyCustomDebugMenu : BaseComponent
{
    private IConsolePanel _consolePanel;

    [Inject]
    public void InjectDependencies(IConsolePanel consolePanel)
    {
        _consolePanel = consolePanel;
    }

    public void OnClickOpenConsoleButton()
    {
        _consolePanel.Show();
    }
}
```

---

## Modding Insights & Limitations

* **Stack Trace Omission**: The `ConsoleLogListener.OnLogMessageReceived` method receives a `stacktrace` parameter from Unity, but completely ignores it when creating the `Log` struct. Therefore, the in-game console will only show the error message, not the lines of code that caused it. Modders tracking down exceptions must still open the actual `Player.log` file to see full stack traces.
* **No Input Field**: Despite being called a "Console", this module provides no mechanism for the player to type commands (like `spawn_item wood 50`). It is strictly an output log viewer. Modders wanting to create a functional command-line interface must build their own UI and command-parsing logic from scratch.
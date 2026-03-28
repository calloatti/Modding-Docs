# Timberborn.ErrorReporting

## Overview
The `Timberborn.ErrorReporting` module captures, formats, and transmits crash logs and exceptions when the game encounters a critical error. It is responsible for pausing game simulation, generating zip archives containing debug information, and uploading those reports to the developer's servers.

---

## Key Components

### 1. `ExceptionListener`
This static class hooks into Unity's application lifecycle before any scenes load to catch fatal errors.
* **Initialization**: It registers `OnLog` to `Application.logMessageReceived` via the `[RuntimeInitializeOnLoadMethod]` attribute.
* **Error Handling**: When a `LogType.Exception` occurs, it sets `AnyUncaughtException` to true, stopping further error spam.
* **Safety Shutdown**: It calls `StopAllRootObjects()`, which iterates through every root GameObject in the active scene and calls `SetActive(false)`. This immediately halts all physics, rendering, and game logic scripts to prevent save corruption or cascading errors.
* **Scene Transition**: Finally, it triggers `CrashSceneLoader.LoadCrashSceneIfEnabled()` to move the player to the dedicated crash UI scene.

### 2. `ErrorReporter`
Handles the creation of the diagnostic `.zip` file stored in the `Error reports` folder within the user's data directory.
* **Zip Contents**: When `CreateErrorReport()` is called, it packages the following into the zip archive:
    * `0 Version.txt`: The current game version.
    * `1 Exception.txt`: The specific stack trace that caused the crash.
    * `2 Player log.txt`: A copy of the full Unity `Player.log` file.
    * `5 Starting item.timber`: A copy of the map or save file the user loaded to start the session, retrieved from `WorldDataService.Data`.
    * `6 Error save.timber`: A memory dump or emergency save file, if one was successfully generated during the crash.

### 3. `ErrorReportSanitizer`
A security and privacy utility that scrubs sensitive path information from log files before they are written to disk or sent to the server.
* It uses Regex patterns (`WindowsAndMacRegex` and `LinuxRegex`) to detect operating system file paths (e.g., `C:\Users\JohnDoe\...` or `/home/JaneDoe/...`) and replaces the username segment with `***`.

### 4. `ErrorReportSender`
Handles the HTTP transmission of the crash zip file.
* **API Endpoint**: By default, it posts to `https://api.timberborn.com/v1/upload-error-report`.
* **Custom Endpoints**: Developers can override this URL using the `--errorUrl` command-line argument.

### 5. `PlayerLogCleaner`
A utility used to filter out standard, non-critical Unity and Timberborn initialization spam from the Player.log before analysis.
* It contains a massive list of `SafePatterns` (Regexes like `^Mono path\[0\] = ` or `^Using Windows\.Gaming\.Input`). Lines matching these patterns are discarded, leaving only warnings and custom log entries behind.

---

## Modding Insights & Limitations

* **Mod-Caused Crashes**: If a mod throws an unhandled exception, `ExceptionListener` will catch it, halt the game, and generate a crash report. Modders should ensure they use try/catch blocks for non-critical mod logic if they do not want to trigger a full game halt.
* **Warning Aggregation**: The `LoadingIssueService` aggregates warnings (like missing JSON keys or broken mod dependencies) during the loading phase using the `LoadingIssueMessage` struct. It groups identical warnings and counts them to prevent log flooding.

---

## Related DLLs

* **Timberborn.PlatformUtilities**: Provides the `UserDataFolder` reference used to build the path to the error reports directory.
* **Timberborn.Versioning**: Supplies the `GameVersions.CurrentVersion` string injected into the error zip.
* **Timberborn.CommandLine**: Parses startup arguments to allow overriding the upload URL (`CustomUrlKey`).
* **Timberborn.SingletonSystem**: Used by `WorldDataClearer` (`IUnloadableSingleton`) to clear out the cached starting map data if the scene unloads normally without a crash.
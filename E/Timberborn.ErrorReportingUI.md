# Timberborn.ErrorReportingUI

## Overview
The `Timberborn.ErrorReportingUI` module handles the user interface elements presented to the player when the game encounters critical errors or non-fatal loading issues. It includes the UI overlay for the dedicated crash screen, the modal popup for map loading warnings, and the "Crash Box" UI element that attempts to show if the dedicated crash scene fails to load.

---

## Key Components

### 1. `CrashScreen`
This is the `MonoBehaviour` attached to the UI Document in the dedicated crash scene (Scene Index 3, as referenced in `Timberborn.ErrorReporting.CrashSceneLoader`).
* **Initialization**: When the scene starts, it waits for a brief `Delay` (3 seconds) to ensure the file system has settled, then asks `ErrorReporter` to generate the crash zip file.
* **Modded State Handling**: It checks `ModdedState.IsModded` and `CrashSceneLoader.DevModeEnabled`. If the game is vanilla, it shows a streamlined "Send Report" UI. If the game is modded or in dev mode, it hides the automatic sender, displays the raw exception text on screen, and provides links instructing the user to remove their mods or report the bug to mod authors.
* **User Input**: For vanilla crashes, it provides text fields for an optional comment and email address, and a required Privacy Policy toggle.
* **Transmission**: Clicking the Send button triggers `ErrorReportSender.SendErrorReport` inside a coroutine, updating the button text to show success or failure.
* **Standalone Localization**: Because the standard DI container and localization services are destroyed during a fatal crash, `CrashScreen` manually instantiates its own `LocalizationLoader` and `Loc` service by reading the `LanguageSettings.LanguageKey` directly from Unity `PlayerPrefs`.

### 2. `CrashBox`
A fallback UI singleton that loads into the standard game interface.
* **Purpose**: If the game crashes but the `CrashSceneLoader.Enabled` flag is false (e.g., during certain editor or test environments), the `CrashBox` listens for the `FirstUncaughtException` event.
* **Visibility**: When triggered, it simply toggles a "Common/CrashBox" UXML element to visible.

### 3. `LoadingIssuePanel`
A non-fatal warning modal that appears if errors were encountered during the map/save loading sequence (such as missing modded buildings or invalid terrain heights).
* **Trigger**: It listens for the `ShowPrimaryUIEvent`. If `_loadingIssueService.HasAnyIssues` is true, it pushes itself onto the `PanelStack` as an overlay.
* **Display Format**: It retrieves all issues from the `ILoadingIssueService`, alphabetizes them, appends a count if the issue occurred multiple times, and formats them into a single block of text separated by `SpecialStrings.RowStarter` bullet points.
* **Player Options**: The panel gives the player the option to either "CloseButton/ContinuePlaying" to ignore the warnings and play anyway, or "ExitToMenu" to safely back out without corrupting their save file.

---

## Modding Insights & Limitations

* **Crash Screen Behavior**: If your mod causes a crash, the `CrashScreen` will detect that `ModdedState.IsModded` is true. It will *prevent* the user from sending the crash report to the developers, instructing them instead to check their mods. Ensure you are hooking into standard Unity `Debug.LogException` or throwing clear exceptions so users know which mod failed.
* **Loading Issues**: Modders should heavily utilize `ILoadingIssueService` when deserializing custom JSON or save data. Instead of throwing a hard exception when an optional spec is missing, use `AddIssue()` to gracefully warn the player via the `LoadingIssuePanel` while still allowing the map to load.

---

## Related DLLs

* **Timberborn.ErrorReporting**: The core logic backend that generates the zip file (`ErrorReporter`), catches exceptions (`ExceptionListener`), and aggregates loading warnings (`ILoadingIssueService`).
* **Timberborn.Modding**: Supplies the `ModdedState.IsModded` flag used to determine the UI layout on the crash screen.
* **Timberborn.PlatformUtilities**: Provides `ExplorerOpener` to open the local file directory containing the generated crash zip.
* **Timberborn.WebNavigation**: Provides `UrlOpener` to open the privacy policy and mod-removal wiki links in the user's default browser.
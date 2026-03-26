# Timberborn.AnalyticsUI

## Overview
The `Timberborn.AnalyticsUI` module handles the user interface associated with player data collection consent. Specifically, it provides the popup dialog that appears the very first time a player launches the game, asking them to opt in or opt out of telemetry.

This DLL is a great, simple example of how to implement `IPanelController` to create a blocking popup dialog using Timberborn's UI Toolkit `PanelStack`.

---

## Key Components

### 1. `AnalyticsConsentBox` (The UI Controller)
This class handles the logic, lifecycle, and rendering of the consent popup.
* **Interfaces:** * `ILoadableSingleton`: Loads the UI template (`"MainMenu/AnalyticsConsentBox"`) as soon as the Main Menu scene initializes.
  * `IPanelController`: Implements the required methods (`GetPanel`, `OnUIConfirmed`, `OnUICancelled`) allowing it to be pushed onto the `PanelStack`.
* **Dependencies:** It injects `AnalyticsConsent` (from `Timberborn.Analytics.dll`) to read the current consent state and apply the user's choice.
* **Behavior:**
  * When `Show(Action closedCallback)` is called, it checks `_analyticsConsent.WasConsentAsked`. If consent was already asked previously, it immediately fires the callback and skips showing the UI. If not, it pushes itself to the `_panelStack`.
  * The "Agree" button calls `_analyticsConsent.GiveConsent()`, while "Disagree" calls `_analyticsConsent.RemoveConsent()`.

### 2. `AnalyticsUIConfigurator`
This configurator registers the `AnalyticsConsentBox` into the dependency injection container.
* **Context:** Notice that it only uses `[Context("MainMenu")]`. This means the consent popup logic is entirely unloaded during actual gameplay or map editing, saving memory.

---

## Modding Insights & Patterns

### 1. Using `PanelStack` for Modal Dialogs
If your mod needs to display a popup window that interrupts the user (like a welcome message, a warning, or a configuration prompt), `AnalyticsConsentBox` serves as a perfect template.

**Pattern for Modders:**
1.  Create a class implementing `IPanelController`.
2.  Inject `PanelStack` into your constructor.
3.  Load your VisualElement in a `Load()` method (or lazily when requested).
4.  Return that element in `public VisualElement GetPanel()`.
5.  To show the window, call `_panelStack.Push(this)`.
6.  To close the window, call `_panelStack.Pop(this)`.

### 2. Handling Hardcoded Callbacks (`OnUICancelled`)
In the `IPanelController` interface, `OnUICancelled()` is usually triggered when the user presses the `Escape` key. 

In `AnalyticsConsentBox`, `OnUICancelled()` is left completely empty (`{ }`). This is an intentional design choice to **force** the player to click either "Agree" or "Disagree"; they cannot simply dismiss the analytics prompt by pressing Escape. If you are building an unavoidable modal for your mod (e.g., an End User License Agreement), you should replicate this behavior.

### 3. Hyperlink Integration
The class demonstrates how to safely open external web links from within a Timberborn UI using the `HyperlinkInitializer` and `UrlOpener` services. It grabs a UI Toolkit `Label` (named "Info") and binds it to `_urlOpener.OpenAnalyticsPrivacyPolicy`. If your mod needs to link to a GitHub repo or Mod.io page, you should inject `UrlOpener` and `HyperlinkInitializer`.
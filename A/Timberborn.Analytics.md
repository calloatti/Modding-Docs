# Timberborn.Analytics

## Overview
The `Timberborn.Analytics` module is a small, specialized assembly responsible for managing and persisting the player's telemetry and data collection consent. It is registered to operate universally across the `MainMenu`, `Game`, and `MapEditor` contexts. 

This DLL serves as the source of truth for whether the game (and potentially your mods) is allowed to track user behavior.

---

## Key Components

### 1. `AnalyticsConsent` (Singleton)
This is the core service of the module, implementing the `ILoadableSingleton` interface to load the player's preference as soon as the dependency injection framework initializes.
* **Dependencies:** It injects `IPlayerDataService` to read and write the consent state.
* **Properties:**
  * `IsConsentGiven`: A boolean indicating if the player has opted into analytics.
  * `WasConsentAsked`: A boolean indicating if the player has been prompted yet, determined by checking if the `"AnalyticsConsent_IsConsentGiven"` key exists in the player data.
* **Methods:**
  * `Load()`: Retrieves the consent status from the player's persistent data store.
  * `GiveConsent()`: Sets `IsConsentGiven` to true and saves this value to the player data.
  * `RemoveConsent()`: Sets `IsConsentGiven` to false and saves this value to the player data.

### 2. `AnalyticsConfigurator`
This class inherits from `Configurator` and binds `AnalyticsConsent` as a singleton.
* **Contexts:** It applies the `[Context("MainMenu")]`, `[Context("Game")]`, and `[Context("MapEditor")]` attributes to ensure the consent data is always accessible.

---

## How and When to Use This in a Mod

### Respecting Player Privacy
If you are developing a mod that includes external API calls, crash reporting, or custom telemetry (e.g., tracking which custom buildings players use most), it is highly recommended to respect the player's vanilla analytics opt-out settings.

You can do this by injecting `AnalyticsConsent` into your custom tracker.

**Usage Pattern:**
```csharp
using Timberborn.Analytics;

public class MyModTelemetryService
{
    private readonly AnalyticsConsent _analyticsConsent;

    public MyModTelemetryService(AnalyticsConsent analyticsConsent)
    {
        _analyticsConsent = analyticsConsent;
    }

    public void ReportCustomEvent(string eventName)
    {
        // Always check if the player has given consent before sending data
        if (!_analyticsConsent.IsConsentGiven)
        {
            return;
        }

        // Proceed with sending the custom telemetry event to your backend...
    }
}
```

---

## Modding Insights & Limitations

* **Global Persistence:** The consent setting is saved using `IPlayerDataService`, which means it is tied to the player's global game installation (likely stored in the user's Documents/Timberborn folder) rather than a specific save file.
* **Direct Manipulation:** While you *could* technically call `GiveConsent()` or `RemoveConsent()` from your mod, you should leave this responsibility to the vanilla UI menus to avoid overriding the player's manual choice without their knowledge.
* **No Telemetry Implementation:** This module solely tracks the *consent state*. It does not contain the actual HTTP clients or network logic used to transmit the analytics data to Timberborn's servers.
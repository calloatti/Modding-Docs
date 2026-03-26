# Timberborn.ApplicationSettingsSystem

## Overview
The `Timberborn.ApplicationSettingsSystem` module is a small, specialized assembly that acts as a bridge between the player's UI preferences and the underlying Unity application engine. Currently, its sole responsibility is to manage the game's "Run In Background" behavior.

This DLL provides a minimal, clean example of how Timberborn connects persistent user settings to global Unity engine properties.

---

## Key Components

### 1. `RunInBackgroundController`
This is the core logic class of the module, implemented as an `ILoadableSingleton`.
* **Dependencies:** It injects `UISettings` (which belongs to the `Timberborn.CoreUI` namespace) via its constructor.
* **Initialization (`Load`):** When the dependency injection framework loads this singleton, it immediately calls `UpdateSetting()`. This reads `_uiSettings.RunInBackground` and applies it directly to Unity's native `Application.runInBackground` property.
* **Event Listening:** During `Load()`, it also subscribes an anonymous delegate to the `_uiSettings.RunInBackgroundChanged` event. This ensures that if the player toggles the setting in the options menu, the Unity engine updates its behavior immediately.

### 2. `ApplicationSettingsSystemConfigurator`
This class registers the `RunInBackgroundController` into the dependency injection container.
* **Contexts:** It uses the `[Context("MainMenu")]`, `[Context("Game")]`, and `[Context("MapEditor")]` attributes. This ensures that the game respects the background execution setting regardless of which scene the player is currently in.

---

## How and When to Use This in a Mod

As a modder, you will likely never need to call or inject `RunInBackgroundController` directly. However, the architectural pattern it uses is exactly how you should implement your own global Unity engine modifications.

### Implementing Custom Engine Settings
If your mod needs to apply custom Unity application settings (like changing `Application.targetFrameRate`, modifying `Time.timeScale` globally, or altering Quality settings based on a custom mod configuration), you should copy this design pattern:

```csharp
using Timberborn.SingletonSystem;
using UnityEngine;
// using YourMod.SettingsSystem; 

public class MyCustomFramerateController : ILoadableSingleton
{
    private readonly MyModSettings _myModSettings;

    // 1. Inject your custom settings service
    public MyCustomFramerateController(MyModSettings myModSettings)
    {
        _myModSettings = myModSettings;
    }

    public void Load()
    {
        // 2. Apply the setting when the scene loads
        UpdateFramerate();

        // 3. Listen for changes so it updates dynamically if the user changes it in-game
        _myModSettings.FramerateLimitChanged += OnFramerateLimitChanged;
    }

    private void OnFramerateLimitChanged(object sender, System.EventArgs e)
    {
        UpdateFramerate();
    }

    private void UpdateFramerate()
    {
        // Apply to the Unity engine
        Application.targetFrameRate = _myModSettings.TargetFramerate;
    }
}
```

---

## Modding Insights & Limitations

* **Delegating to Engine Properties:** Notice that Timberborn does not constantly check `Application.runInBackground` in an `Update()` loop. It sets the native Unity property once on load and relies entirely on event callbacks (`RunInBackgroundChanged`) to know when to change it. This event-driven approach is a best practice for performance.
* **Separation of UI and Application State:** The actual toggle UI and the saving/loading of the preference to disk is handled externally by `UISettings` (in `Timberborn.CoreUI`). This DLL only handles the application of that data to the Unity Engine. Keep your mod's UI logic and Engine logic similarly separated.
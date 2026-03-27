# Timberborn.CameraSettingsSystem

## Overview
The `Timberborn.CameraSettingsSystem` is a small, specialized module dedicated to managing player preferences related to the game's camera. It demonstrates a clean architectural pattern by wrapping raw, string-based settings lookups into a strongly typed, injectable service. Currently, this module manages a single setting: the option to unlock the camera's zoom limits.

---

## Key Components

### 1. `CameraSettings`
This class acts as a strongly typed Facade around the game's core `ISettings` interface.
* **Key Encapsulation**: It encapsulates the raw string key `"UnlockZoom"` into a private static readonly field (`UnlockZoomKey`). This prevents magic strings from being hardcoded across multiple files.
* **State Management**: It exposes a public boolean property, `UnlockZoom`. 
    * The `get` accessor reads the boolean state from the injected `_settings`.
    * The `set` accessor writes the boolean state back to `_settings`.

### 2. `CameraSettingsSystemConfigurator`
A standard Bindito configurator that registers the `CameraSettings` class so it can be injected into other systems.
* **Global Contexts**: It is bound to `[Context("MainMenu")]`, `[Context("Game")]`, and `[Context("MapEditor")]`. This ensures that the camera settings can be read or modified regardless of the active scene (e.g., changing the setting from the main menu before loading a settlement).
* **Singleton Binding**: It is bound using `.AsSingleton()`, meaning exactly one instance of this wrapper exists in memory per context, acting as the single source of truth for camera settings.

---

## How to Use This in a Mod

### Reading the Vanilla Camera Settings
If you are building a mod that interacts with the camera (like a cinematic screenshot tool, a free-cam mode, or a custom camera controller), you should respect the player's vanilla settings. You can do this by injecting the `CameraSettings` singleton:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CameraSettingsSystem;
using UnityEngine;

public class MyCustomCameraController : BaseComponent, IUpdatableComponent
{
    private CameraSettings _cameraSettings;

    [Inject]
    public void InjectDependencies(CameraSettings cameraSettings)
    {
        _cameraSettings = cameraSettings;
    }

    public void Update()
    {
        float maxZoomOut = 50f;
        
        // Respect the player's vanilla "UnlockZoom" setting
        if (_cameraSettings.UnlockZoom)
        {
            maxZoomOut = 200f; // Allow the camera to zoom out much further
        }
        
        // ... apply your custom zoom logic ...
    }
}
```

### Creating Custom Settings
If your mod introduces *new* camera settings (such as a "Pan Speed" slider or "FOV" toggle), you should replicate this pattern. Do not scatter raw string keys (`_settings.GetBool("MyModPanSpeed")`) in your logic classes. Create your own `MyModCameraSettings` class that wraps `ISettings`, bind it as a singleton in your configurator, and inject it wherever your mod needs to read those preferences.

---

## Modding Insights & Limitations

* **Single Responsibility**: This module only *stores* and *retrieves* the setting. It does not contain the actual camera movement logic or the math that limits the zoom. The actual enforcement of the zoom limits occurs in a separate camera controller module that injects this `CameraSettings` class.
* **Limited Scope**: Currently, `UnlockZoom` is the only setting managed here. Other camera-related settings (like pan speed or edge scrolling) might be handled by the OS/Input layers or are hardcoded elsewhere in the engine.
# Timberborn.AccessibilitySettingsSystem

## Overview
The `Timberborn.AccessibilitySettingsSystem` module is a small, focused DLL responsible for managing specific player-facing accessibility options and applying them globally across the game. Currently, it handles a single accessibility toggle: disabling starfield rotation to reduce motion sickness.

This module provides a great reference for how Timberborn ties user settings to global Unity shader properties.

---

## Key Components

### 1. `AccessibilitySettings` (Singleton)
This is the core service of the module. It is bound as a singleton and implements `IPostLoadableSingleton`, meaning it automatically initializes its state immediately after the dependency injection framework finishes loading it.

* **Dependencies:** Injects `ISettings` to read and write persistent configuration data.
* **Properties:**
    * `StarfieldRotationDisabled` (bool): A getter/setter that interfaces directly with `ISettings` (using the key `"StarfieldRotationDisabled"`). 
* **Behavior:** When the `StarfieldRotationDisabled` property is updated, or during the `PostLoad` phase, it calls `UpdateShaderProperties()`. This method uses `Shader.SetGlobalInt("_StarfieldRotationDisabled", ...)` to globally toggle the shader behavior for the night sky.

### 2. `AccessibilitySettingsSystemConfigurator`
This is the Bindito configurator responsible for registering the system. 
* **Contexts:** `[Context("MainMenu")]`, `[Context("Game")]`, `[Context("MapEditor")]`
* **Purpose:** Ensures that `AccessibilitySettings` is bound as a singleton in almost every user-facing scene in the game, allowing the skybox shader to respect the accessibility setting regardless of where the player is.

---

## How and When to Use This in a Mod

### Respecting Player Accessibility Settings
If you are developing a mod that introduces custom night sky visuals, custom celestial bodies, or new shaders that involve background rotation, you should respect the player's accessibility choices.

**Usage Pattern:**
Inject `AccessibilitySettings` into your custom system to check if the player has requested motion reduction.

```csharp
using Timberborn.AccessibilitySettingsSystem;
using Timberborn.SingletonSystem;

public class MyCustomSkySystem : IUpdatableSingleton
{
    private readonly AccessibilitySettings _accessibilitySettings;

    // Inject the accessibility settings via the constructor
    public MyCustomSkySystem(AccessibilitySettings accessibilitySettings)
    {
        _accessibilitySettings = accessibilitySettings;
    }

    public void UpdateSingleton()
    {
        // Check the setting before applying custom rotational logic
        if (_accessibilitySettings.StarfieldRotationDisabled)
        {
            // Pause custom sky rotation or disable moving visual effects
            return;
        }

        // Apply normal rotation logic here
    }
}
```

### Extending Settings (Observation)
While you cannot add new properties directly to the `AccessibilitySettings` class, its architecture provides a perfect blueprint for how to implement your own Mod Settings:
1. Create a class implementing `IPostLoadableSingleton`.
2. Inject Timberborn's `ISettings`.
3. Use C# properties to proxy `_settings.GetBool()` / `_settings.SetBool()`.
4. Apply those settings to global Unity states (like Shaders or Time/Physics) inside `PostLoad()`.

---

## Modding Insights & Limitations

* **Global Shader Properties:** Note that Timberborn uses `Shader.SetGlobalInt` rather than modifying specific material instances. If you are writing custom shaders for your mod, you can hook into this vanilla behavior simply by defining `int _StarfieldRotationDisabled;` in your shader's HLSL/CG code.
* **No Direct UI Logic:** This DLL does *not* contain the UI for the settings menu. The UI is handled by an external module that binds to the `AccessibilitySettings.StarfieldRotationDisabled` property.
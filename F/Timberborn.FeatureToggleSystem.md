# Timberborn.FeatureToggleSystem

## Overview
The `Timberborn.FeatureToggleSystem` module is a low-level diagnostic and development tool used to enable or disable specific experimental or in-development features of the game. These features can be toggled via command-line arguments in built versions of the game or via Editor preferences when running within the Unity Editor.

---

## Key Components

### 1. `FeatureToggles`
This static class acts as the central registry for all available feature toggles.
* **Definition**: Toggles are defined as `public static readonly bool` fields (e.g., `SteamInEditor`).
* **Initialization**: Its static constructor calls `FeatureToggleService.InitializeToggles()`, ensuring the flags are evaluated and set the very first time any system attempts to read from this class.

### 2. `FeatureToggleService`
The engine that reads external inputs and assigns the boolean values to the fields in `FeatureToggles` using C# Reflection.
* **Field Discovery**: Uses `typeof(FeatureToggles).GetFields()` to find all public boolean fields.
* **State Resolution**: For each field found, it determines the state:
    * **In Editor**: It calls `EditorFeatureToggler.GetToggleState(toggleName)`.
    * **In Build**: It checks the `CommandLineArguments` for a flag matching `feature-[ToggleName]` (e.g., `--feature-SteamInEditor`).
* **Assignment**: It uses `FieldInfo.SetValue(null, toggleState)` to write the result back into the static fields of `FeatureToggles`.
* **Logging**: It outputs a yellow `Debug.LogWarning` to the Unity console listing all currently active feature toggles (e.g., `Active features: SteamInEditor`).

### 3. `EditorFeatureToggler`
A stub class that acts as a bridge for the Unity Editor.
* In the compiled game DLL provided, the methods `GetToggleState` and `SetToggleState` simply throw an `InvalidOperationException`. This indicates that the actual implementation of this class relies on Unity Editor-only assemblies (like `EditorPrefs`) which are stripped or conditionally compiled out of the final player build.

---

## How to Use This in a Mod

### Checking Native Feature Flags
If you are writing a mod and need to know if a specific developer feature is enabled (like `SteamInEditor`), you can simply read the static field directly:

    using Timberborn.FeatureToggleSystem;

    public class MyModSteamIntegration {
        public void ConnectToSteam() {
            if (FeatureToggles.SteamInEditor) {
                // Execute Steam API connection logic
            }
        }
    }

*Note: You do not need to use `FeatureToggleService.IsToggleOn("SteamInEditor")` as the fields are public, static, and read-only.*

---

## Modding Insights & Limitations

* **Closed System**: Modders cannot dynamically inject their own boolean flags into `FeatureToggles` because the `GetToggleFields` method strictly searches `typeof(FeatureToggles)`. If you want to use command-line arguments to toggle features in your mod, you must use the `CommandLineArguments` utility directly rather than relying on this specific service.
* **Reflection Overhead**: The reflection (`GetFields`, `SetValue`) only occurs once during the static constructor initialization of `FeatureToggles`. Reading the flags afterward carries zero performance penalty.
* **Missing Editor Logic**: Modders should not attempt to call `EditorFeatureToggler.GetToggleState` directly at runtime, as it will crash the game by throwing an `InvalidOperationException`.

---

## Related DLLs

* **Timberborn.CommandLine**: Provides the `CommandLineArguments` parsing utility used to detect the `--feature-...` launch flags.
# Timberborn.ExperimentalModeSystem

## Overview
The `Timberborn.ExperimentalModeSystem` module is a lightweight utility that detects if the game was launched with a specific command-line argument to enable experimental features. It provides a globally accessible flag indicating the current experimental state of the game instance.

---

## Key Components

### 1. `ExperimentalMode`
This is the core singleton class responsible for determining the experimental status.
* **Command Line Detection**: During its `Load()` phase, it queries the `ICommandLineArguments` service for the presence of the `experimental` key (e.g., launching the game with `--experimental`).
* **Global Flag**: If the key is found, it sets its public `IsExperimental` property to `true`.

### 2. `ExperimentalModeSystemConfigurator`
The Bindito configurator that sets up the system.
* **Bootstrapper Context**: It runs extremely early in the game's lifecycle within the `Bootstrapper` context.
* **Global Export**: It binds the `ExperimentalMode` class as a singleton and marks it as `.AsExported()`, meaning it can be injected into any other dependency context (like `MainMenu` or `Game`) throughout the application.

---

## How to Use This in a Mod

### Gating Mod Features Behind Experimental Mode
If you are developing a mod and want to hide unstable or testing features from regular users, you can inject `ExperimentalMode` and check the `IsExperimental` flag.

    using Timberborn.ExperimentalModeSystem;

    public class MyModFeatureLauncher {
        private readonly ExperimentalMode _experimentalMode;

        public MyModFeatureLauncher(ExperimentalMode experimentalMode) {
            _experimentalMode = experimentalMode;
        }

        public void StartFeature() {
            if (_experimentalMode.IsExperimental) {
                // Launch beta testing features
            } else {
                // Launch stable features
            }
        }
    }

Players testing your mod would then need to add `--experimental` to their Steam launch options to access the beta features.

---

## Modding Insights & Limitations

* **Read-Only Status**: The `IsExperimental` property has a private setter and is evaluated exactly once during the `Bootstrapper` loading phase. Modders cannot toggle this state on or off at runtime via code; it is strictly dictated by the initial launch arguments.
* **Single Responsibility**: This module solely tracks the boolean state. It does not contain any logic for what "experimental" actually enables in the base game—it merely provides the flag for other systems to read.

---

## Related DLLs

* **Timberborn.CommandLine**: Provides the `ICommandLineArguments` service used to parse the launch arguments.
* **Timberborn.SingletonSystem**: Supplies the `ILoadableSingleton` interface that dictates when the check occurs.
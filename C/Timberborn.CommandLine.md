# Timberborn.CommandLine

## Overview
The `Timberborn.CommandLine` module provides a clean, injectable wrapper around `System.Environment.GetCommandLineArgs()`. This allows various game systems to read launch parameters (arguments passed when executing the game, like `-windowed` or `-customMap path`) without making static calls to the operating system, which greatly improves testability and architectural cleanliness.

---

## Key Components

### 1. `CommandLineArguments`
This class implements the `ICommandLineArguments` interface to parse and retrieve launch arguments.
* **Argument Prefixing**: It strictly expects arguments to be prefixed with a hyphen (`-`). For example, searching for the key `"test"` via `Has("test")` will look for the exact string `"-test"` in the arguments array.
* **Value Retrieval**: Methods like `GetString(string key)` and `GetInt(string key)` assume the value immediately follows the key in the argument array. For example, the command line `-resolution 1920` would be parsed by `GetInt("resolution")`, which finds `"-resolution"` at index 0 and returns the parsed integer from index 1.
* **Error Handling**: If `GetString(key)` is called for a key that does not exist, it throws an `ArgumentException`.

### 2. `CommandLineConfigurator`
A standard Bindito configurator that ensures the command line arguments are available to the rest of the game.
* **Context**: It operates exclusively in the `[Context("Bootstrapper")]`. This is the earliest initialization context in the game, meaning the command line arguments are parsed immediately upon launch.
* **Exporting**: It binds the interface `ICommandLineArguments` to a singleton and flags it with `.AsExported()`. This allows the singleton to be accessed by *all* subsequent child contexts (like `MainMenu`, `Game`, and `MapEditor`), making the launch arguments globally available.

---

## How to Use This in a Mod

If your mod requires custom launch parameters (for example, a `-debugMod` flag to enable excessive logging, or `-modConfig path/to/file` to load a specific external setup), you can easily retrieve them by injecting `ICommandLineArguments`.

### Reading Custom Arguments

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CommandLine;

public class MyModManager : BaseComponent, IAwakableComponent
{
    private ICommandLineArguments _commandLineArgs;

    [Inject]
    public void InjectDependencies(ICommandLineArguments commandLineArgs)
    {
        _commandLineArgs = commandLineArgs;
    }

    public void Awake()
    {
        // Check for a simple flag: e.g., launching with "-enableMyModDebug"
        if (_commandLineArgs.Has("enableMyModDebug"))
        {
            EnableVerboseLogging();
        }

        // Check for a key-value pair: e.g., launching with "-myModDifficulty 3"
        if (_commandLineArgs.Has("myModDifficulty"))
        {
            int difficulty = _commandLineArgs.GetInt("myModDifficulty");
            SetDifficulty(difficulty);
        }
    }
}
```

---

## Modding Insights & Limitations

* **Strict Key-Value Formatting**: The parser is extremely basic. It assumes all values are space-separated from their keys (`-key value`). It does not support equals-sign assignments (`-key=value`). Modders must document their custom launch parameters carefully to ensure users use the correct spacing.
* **Hyphen Prefix Hardcoded**: The `IndexOfKey(string key)` method hardcodes the `"-" + key` lookup. You cannot use this class to look up arguments formatted with double hyphens (e.g., `--test`) unless you pass the key as `"-test"`, which the class would then format as `"---test"`. Stick to single-hyphen arguments.
* **Missing Safe Getters**: There are no `TryGetString` or `TryGetInt` methods. Calling `GetString` or `GetInt` without first checking `Has(key)` will cause the game to throw an exception and potentially crash during initialization. Always wrap retrieval in a `Has()` check.
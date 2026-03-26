# Timberborn.AutomationBuildings

## Overview
The `Timberborn.AutomationBuildings` module contains the concrete implementations for all vanilla automation blocks, including sensors, logic gates, output terminals, and mechanical components. While the core `Timberborn.Automation` module handles the abstract node graph, this DLL provides the actual behaviors for the components the player builds in the game. 

For a modder, this is the ultimate reference library on how to build custom sensors, custom logic gates, and custom automated actions.

---

## Key Components & Architectures

This DLL perfectly illustrates the different types of automation nodes defined by the core system.

### 1. `ISamplingTransmitter` Implementations (Sensors)
These components read the state of the game world and translate it into an On/Off signal.
* **`DepthSensor` / `FlowSensor` / `ContaminationSensor`:** Uses the injected `IThreadSafeWaterMap` to read the water simulation. 
* **`PopulationCounter` / `ResourceCounter`:** Rather than iterating through every beaver or stockpile directly, these use `SamplingPopulationService` and `SamplingResourcesService`. These services cache data globally and per-district every tick, significantly reducing performance overhead. 
* **Mechanism:** Inside their `Sample()` method, they evaluate their threshold using `ComparisonMode.Evaluate(...)` and call `_automator.SetState(...)`.

### 2. `ICombinationalTransmitter` Implementations (Logic Gates)
* **`Relay`:** Evaluates instantaneous logic (AND, OR, XOR, NOT, Passthrough) based on the `InputA` and `InputB` states. It updates via the `Evaluate()` method and immediately pushes the result.

### 3. `ISequentialTransmitter` Implementations (State Machines)
These components maintain internal state and are evaluated in two steps to prevent race conditions during tick updates.
* **`Memory`:** Implements Flip-Flop, Latch, Toggle, and Set/Reset logic. Uses `EvaluateNext()` to determine what the state *will* be, and `CommitTick()` to officially set `_state = _nextState`.
* **`Timer`:** Uses `TimerInterval` to count ticks, hours, or days before toggling states depending on its `TimerMode` (Delay, Pulse, Oscillator, Accumulator).

### 4. `ITerminal` Implementations (Actions)
These components listen for the `ConnectionState.On` signal and perform a physical action in the world.
* **`Detonator`:** Checks if the state is On in `Evaluate()`. If so, it calls `Trigger()` on the underlying `Dynamite` component.
* **`PausableBuildingTerminal`:** Blocks or unblocks a `BlockableObject` (thus pausing the building) based on the automation signal.
* **`Gate`:** Communicates with `GateUpdater` to physically open or close a floodgate, which then updates the `GateNavMeshBlocker` to sever pathfinding routes over the gate.

---

## How and When to Use This in a Mod

While you won't typically inherit directly from these classes, you should use them as blueprints for your own automation mods. 

### Writing a Custom Sensor (Copying the Pattern)
If you wanted to write a sensor that tracks the current wind speed, you would mirror components like `Chronometer` or `ScienceCounter`:

```csharp
using Timberborn.Automation;
using Timberborn.BaseComponentSystem;
using Timberborn.WindSystem; // Assuming you inject this

public class WindSensor : BaseComponent, IAwakableComponent, ISamplingTransmitter
{
    private readonly WindService _windService;
    private Automator _automator;
    
    public float Threshold { get; private set; }

    public WindSensor(WindService windService)
    {
        _windService = windService;
    }

    public void Awake()
    {
        _automator = GetComponent<Automator>();
    }

    // Called by the AutomationRunner periodically
    public void Sample()
    {
        float currentWindSpeed = _windService.WindStrength;
        _automator.SetState(currentWindSpeed > Threshold);
    }
}
```

### Extending Automation (Decorators)
If you want to add an existing vanilla automation behavior to a custom building or a vanilla building that currently doesn't support it, you can add it via the `TemplateModule` in your Configurator. For example, `AutomationBuildingsConfigurator` adds the `PausableBuildingTerminal` to any entity that implements `IFinishedPausable`.

```csharp
// Example of how Timberborn adds pause automation to all pausable buildings
builder.AddDecorator<IFinishedPausable, PausableBuildingTerminal>();
builder.AddDecorator<PausableBuildingTerminal, AutoAutomatableNeeder>();
```

---

## Modding Insights & Limitations

* **Performance Optimization via `ISamplingSingleton`:** If you write a custom sensor that requires heavy calculations (e.g., searching for specific nearby blocks), **do not** do the calculation inside the `Sample()` method of every individual building. Instead, follow the `PopulationCounter` pattern: create an `ISamplingSingleton` (like `SamplingPopulationService`) that calculates the data once per tick for the whole map, and have your individual sensor buildings read from that cached singleton.
* **Saving Enums & References:** This DLL shows exactly how to save enum states (e.g., `component.Set(ModeKey, Mode);`) and how to serialize connections to other automation nodes using `_referenceSerializer.Of<Automator>()`. If your custom gate connects to specific objects, you must use the `ReferenceSerializer` to persist those links across save games.
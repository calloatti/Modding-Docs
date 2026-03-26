# Timberborn.Automation

## Overview
The `Timberborn.Automation` module forms the logical backbone of the game's automation system. This system allows players to wire buildings together so that sensors, timers, and logic gates (Transmitters) can automatically trigger actions on other buildings (Terminals) based on changing game conditions.

This DLL defines the core node graph, parsing connections into isolated "Partitions" to optimize the evaluation loop and prevent infinite recursion or crashing from cyclical logic networks.

---

## Key Concepts & Architecture

The automation system operates on a directed graph where data flows from Transmitters to Terminals. To use the system, a GameObject requires two things:
1. The `Automator` component (which manages connections, states, and graph partitioning).
2. At least one interface defining its role in the network (e.g., `ITerminal`, `ISamplingTransmitter`, `ISequentialTransmitter`, etc.).

### 1. Transmitters (Data Sources & Logic)
A Transmitter generates or processes a boolean state (`On` / `Off` / `Error`). There are three distinct types of Transmitters, which dictate *when* their logic is evaluated by the `AutomationRunner`:

* **`ISamplingTransmitter`:** Measures environmental or game state (e.g., Water Depth, Population, Time of Day). The engine calls `Sample()` periodically.
* **`ICombinationalTransmitter`:** Instantaneous logic gates (e.g., AND, OR, XOR). The engine calls `Evaluate()` whenever the inputs change.
* **`ISequentialTransmitter`:** Stateful logic that evaluates over time (e.g., Timers, Memory Latches). The engine calls `EvaluateNext()` to determine the future state, followed by `CommitTick()` to apply it, ensuring stable logic evaluation across ticks.

### 2. Terminals (Data Sinks / Actions)
A Terminal listens to a Transmitter and performs an action when the state changes.
* **`ITerminal`:** Requires the `Evaluate()` method, which is called by the `AutomationRunner` whenever the incoming `AutomatorConnection` changes state.
* **`Automatable`:** A built-in terminal component that simplifies adding automation to existing buildings (like pausing a Water Pump). It holds the actual `AutomatorConnection` and exposes events like `InputStateChanged`.

### 3. `AutomationRunner` & Partitions
To ensure high performance, Timberborn does not evaluate every node in the game every frame.
* The `AutomationPartitioner` groups interconnected `Automator` nodes into an `AutomatorPartition`.
* The `AutomationRunner` schedules partitions for evaluation only when necessary (e.g., when a sensor samples a new value or a user toggles a switch).
* **Cyclic Protection:** The `AutomationPlan` builds a directed acyclic graph (DAG). If it detects a loop of instantaneous combinational logic (e.g., an OR gate feeding back into itself), it flags the nodes as `IsCyclicOrBlocked` and sets their state to `AutomatorState.Error`.

---

## How to Add Custom Automation

If you want your custom mod building to either control other buildings (be a Transmitter) or be controlled by them (be a Terminal), you must interact with this system.

### Example A: Creating a Custom Sensor (Transmitter)
To create a sensor that triggers when it rains, implement `ISamplingTransmitter`:

```csharp
using Timberborn.Automation;
using Timberborn.BaseComponentSystem;

// 1. Implement ISamplingTransmitter
public class RainSensor : BaseComponent, IAwakableComponent, ISamplingTransmitter
{
    private Automator _automator;
    private MyWeatherSystem _weatherSystem; // Your custom logic

    public void Awake()
    {
        // 2. Grab the Automator component
        _automator = GetComponent<Automator>();
    }
    
    // 3. The AutomationRunner will call Sample() automatically
    public void Sample() 
    {
        bool isRaining = _weatherSystem.IsRaining;
        
        // 4. Push the result to the Automator, which updates the network
        _automator.SetState(isRaining);
    }
}
```

### Example B: Making a Custom Building Automatable (Terminal)
To allow the player to wire a Transmitter to your building to trigger a custom action (like turning on a shield generator):

```csharp
using Timberborn.Automation;
using Timberborn.BaseComponentSystem;

// 1. Implement ITerminal AND IAutomatableNeeder
public class ShieldGeneratorTerminal : BaseComponent, IAwakableComponent, ITerminal, IAutomatableNeeder
{
    private Automatable _automatable;
    private MyShieldGenerator _shieldGen;

    // We only need the "Automate" UI if there are transmitters on the map
    public bool NeedsAutomatable => true; 

    public void Awake()
    {
        // The Automatable component handles the physical connection to the network
        _automatable = GetComponent<Automatable>();
        _shieldGen = GetComponent<MyShieldGenerator>();
    }

    // 2. The AutomationRunner calls Evaluate() when the input state changes
    public void Evaluate()
    {
        if (_automatable.State == ConnectionState.On)
        {
            _shieldGen.ActivateShield();
        }
        else
        {
            _shieldGen.DeactivateShield();
        }
    }
}
```

**JSON Setup:**
For Example B to work, your building's prefab JSON must include the `Automator` and `Automatable` components:
```json
{
  "Components": {
    "Automator": {},
    "Automatable": {},
    "ShieldGeneratorTerminal": {}
  }
}
```

---

## Modding Insights & Limitations

* **`IAutomatorListener`:** If you want a component to react visually to the state of the network (like a glowing light or a moving gear) *without* being a Terminal that affects game logic, implement `IAutomatorListener.OnAutomatorStateChanged()`. This is what `AutomatorIlluminator` uses.
* **Strict Separation:** You cannot have a single `Automator` act as both a Transmitter and a Terminal. The `ValidateAwake()` method explicitly throws an Exception if a GameObject has both `ITransmitter` and `ITerminal` components attached. If you need a building that does both (e.g., a smart battery that receives shutoff signals but also broadcasts its charge level), you must use two separate `BlockObject` entities or attach the components to separate child GameObjects with their own `Automator` components.
* **Saving/Loading:** The `Automator` component automatically saves its `State`. `Automatable` automatically saves its connection to an `Input` using a `ReferenceSerializer`. You do not need to manually save the network wiring in your custom components.
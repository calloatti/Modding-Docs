# Timberborn.BehaviorSystemUI

## Overview
The `Timberborn.BehaviorSystemUI` module is a small presentation layer designed to expose the internal state of the `BehaviorSystem` for debugging and diagnostic purposes. It provides a developer-facing UI fragment that displays exactly what the artificial intelligence of a selected entity is currently doing.

For modders, this module serves as a practical example of how to inject custom debug information into the game's Entity Panel, which is invaluable when building and testing custom AI behaviors.

---

## Key Components

### 1. `BehaviorManagerDebugFragment`
This class implements the `IEntityPanelFragment` interface to render AI diagnostics in the entity selection window.
* **Initialization**: It uses a `DebugFragmentFactory` to create the visual layout for the fragment during `InitializeFragment()`.
* **Targeting**: When an entity is clicked (`ShowFragment`), it attempts to grab the `BehaviorManager` component attached to that entity.
* **Rendering Data**: During `UpdateFragment()`, it uses a `StringBuilder` to format and display real-time data from the `BehaviorManager`. It explicitly shows:
    * The currently active Behavior (`runningBehavior.Name`).
    * The currently active Executor and how long it has been running in seconds (`{runningExecutor.Name} {runningExecutor.ElapsedTime:0.0}s`).
    * The `TimestampedBehaviorLog`, iterating through it in reverse order to show the most recent AI decisions first.

### 2. `BehaviorSystemUIConfigurator`
This class registers the debug fragment with the game's dependency injection system.
* **Context**: It operates exclusively in the `"Game"` context.
* **Module Provider**: It uses a private `EntityPanelModuleProvider` to build an `EntityPanelModule`.
* **Diagnostic Placement**: Notably, it uses `builder.AddDiagnosticFragment(_behaviorManagerDebugFragment)` rather than adding it to the top, middle, or bottom sections of the panel. This ensures the information is categorized correctly as a diagnostic tool rather than core gameplay information.

---

## How to Use This in a Mod

### Creating Your Own Debug Fragments
If you are developing a mod with complex background logic (e.g., a custom water simulation script or a new type of job priority manager), you can follow this pattern to create your own diagnostic windows to aid your development process:

```csharp
using System.Text;
using Timberborn.BaseComponentSystem;
using Timberborn.CoreUI;
using Timberborn.EntityPanelSystem;
using UnityEngine.UIElements;

public class MyCustomDebugFragment : IEntityPanelFragment
{
    private readonly DebugFragmentFactory _debugFragmentFactory;
    private MyCustomLogicComponent _myLogic;
    private Label _text;
    private VisualElement _root;

    public MyCustomDebugFragment(DebugFragmentFactory debugFragmentFactory)
    {
        _debugFragmentFactory = debugFragmentFactory;
    }

    public VisualElement InitializeFragment()
    {
        // DebugFragmentFactory is a handy built-in tool for standardizing debug UI
        _root = _debugFragmentFactory.Create("My Mod Diagnostics");
        _text = _root.Q<Label>("Text");
        return _root;
    }

    public void ShowFragment(BaseComponent entity)
    {
        _myLogic = entity.GetComponent<MyCustomLogicComponent>();
    }

    public void ClearFragment()
    {
        _myLogic = null;
        _root.ToggleDisplayStyle(visible: false);
    }

    public void UpdateFragment()
    {
        if (_myLogic != null && _myLogic.Enabled)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("Current State: " + _myLogic.StateName);
            sb.AppendLine("Internal Value: " + _myLogic.SomeFloatValue);
            
            _text.text = sb.ToString();
            _root.ToggleDisplayStyle(visible: true);
        }
        else
        {
            _root.ToggleDisplayStyle(visible: false);
        }
    }
}
```
You would then bind this using `builder.AddDiagnosticFragment(myCustomDebugFragment)` in your configurator.

---

## Modding Insights & Limitations

* **Debug UI Limitations**: Because this fragment relies on `DebugFragmentFactory`, the resulting UI is strictly functional. It generates a simple text label without advanced formatting, buttons, or interactable elements. If your mod requires players to actively toggle debug settings or click buttons on the entity panel, you must load a custom `.uxml` file via `VisualElementLoader` instead of using the `DebugFragmentFactory`.
* **Update Frequency**: The `UpdateFragment` method is called every frame that the panel is visible. Modders must be mindful not to perform heavy calculations or allocate memory (like creating new objects without pooling) inside this method, as it will impact the game's framerate. The use of `StringBuilder` here is an example of minimizing string allocation overhead.
# Timberborn.BuilderHubSystemUI

## Overview
The `Timberborn.BuilderHubSystemUI` is a highly focused, minimal presentation module. Its sole responsibility is to act as structural "glue," ensuring that buildings designated as Builder Hubs properly integrate with the game's standardized inventory UI panels. 

Because builders often need to temporarily store or hold construction materials, this module guarantees that the player can see those materials in the building's selection panel.

---

## Key Components

### 1. `BuilderHubSystemUIConfigurator`
This is the only functional class within the module, operating specifically within the `Game` context.
* **Template Decoration**: It uses a `TemplateModule.Builder` to apply a single decorator: `builder.AddDecorator<BuilderHubSpec, SimpleOutputInventoryFragmentEnabler>()`.
* **Cross-Module Integration**: By attaching `SimpleOutputInventoryFragmentEnabler` (which originates from the `Timberborn.SimpleOutputBuildingsUI` namespace), it automatically enables the inventory viewing UI fragment on the Builder Hub's entity panel.

---

## How to Use This in a Mod

Because this module is purely structural and relies on dependency injection templates, modders do not need to write any C# code to take advantage of it. 

If you are creating a custom Builder's Hut in your mod, you only need to include the `BuilderHubSpec` in your building's JSON template.

```json
{
  "BuilderHubSpec": {},
  "InventorySpec": {
    "Capacity": 50
  }
}
```

The `BuilderHubSystemUIConfigurator` will automatically detect the `BuilderHubSpec` and attach the necessary UI enabler. When a player clicks your custom building, the inventory panel will seamlessly appear and display any stored goods.

---

## Modding Insights & Limitations

* **Strict Separation of Concerns**: This module is a prime example of Timberborn's strict architectural decoupling. The core logic of a builder hub (`Timberborn.BuilderHubSystem`) has no knowledge of how to display inventories. Likewise, the generic inventory UI (`Timberborn.SimpleOutputBuildingsUI`) doesn't know what a Builder Hub is. This tiny UI configurator module bridges that gap safely without creating hard dependencies between the core systems.
* **Lack of Map Editor Context**: Unlike many other UI configurators, `BuilderHubSystemUIConfigurator` only binds in the `[Context("Game")]`. It completely excludes `[Context("MapEditor")]`. This is an optimization because functional inventories and builder hub states are irrelevant during map creation.
# Timberborn.AttractionsUI

## Overview
The `Timberborn.AttractionsUI` module is responsible for the visual representation of Attraction buildings in the user interface. It provides the specific "fragments" used in the Entity Panel (the menu opened when clicking a building) and the customized components for the Batch Control system.

This DLL focuses on presenting visitor data, usage statistics (load rates), and satisfying need descriptions to the player.

---

## Key Components

### 1. Entity Panel Fragments
These components are injected into the building's info panel to provide attraction-specific information:
* **`AttractionFragment`**: Displays a row of character buttons representing beavers currently inside the building. It allows the player to click on a beaver's portrait to select and follow them.
* **`AttractionLoadRateFragment`**: Renders a 24-hour histogram showing the building's usage (load rate) throughout the day. It uses a "Current Hour Marker" to show where the simulation is relative to the past 24 hours of data.
* **`AttractionDescriber`**: An `IEntityDescriber` that generates the text section for the building's description. It lists the visitor capacity and details the effects (needs satisfied) provided by the building using the `EffectDescriber` service.

### 2. Batch Control Integration
This module provides the factories and UI items required for the Wellbeing tab in the Batch Control panel:
* **`AttractionBatchControlRowItem`**: Displays the "Current Visitors / Total Capacity" text for each building in the list.
* **`AttractionLoadRateBatchControlRowItem`**: Displays a condensed version of the 24-hour usage chart within a single row of the Batch Control table.

### 3. Visual Markers
* **`DepthSensorMarker`**: While logically part of automation, this marker (handled by this UI DLL) provides a 3D blue line in the game world indicating the height threshold of a sensor when the building is selected. *Note: Though appearing in the index, this is typically linked to sensor logic.*

---

## How and When to Use This in a Mod

Modders typically do not need to call these classes directly. If your mod adds a building with an `Attraction` component, the game's dependency injection system automatically attaches these UI elements.

### Automatic UI Attachment
Because the `AttractionsUIConfigurator` uses the `TemplateModule` and `EntityPanelModule` providers, any building tagged as an `Attraction` will automatically receive:
1. The **Load Rate Chart** (at the top of the panel).
2. The **Visitor Portrait Row**.
3. The **Need Satisfaction Descriptions**.

### Customizing Descriptions
If you want to change how your custom attraction is described in the UI, you can implement a custom `IEntityDescriber` and bind it as a decorator to your building.

```csharp
using Timberborn.EntityPanelSystem;
using System.Collections.Generic;

public class MyCustomDescriber : IEntityDescriber {
    public IEnumerable<EntityDescription> DescribeEntity() {
        yield return EntityDescription.CreateTextSection("This building is super fun!", 10);
    }
}
```

---

## Modding Insights & Limitations

* **Fragment Priority**: Both `AttractionLoadRateFragment` and `AttractionFragment` are added using `builder.AddTopFragment()`. This ensures they appear above standard building fragments like inventory or worker lists.
* **Character Portraits**: The `AttractionFragment` uses a `CharacterButtonFactory` to create the small beaver circles. It dynamically recreates these buttons based on the building's `Capacity` whenever a building finishes construction (`EnteredFinishedStateEvent`).
* **Load Rate Visuals**: The height of the bars in the usage chart is set using `StyleLength(Length.Percent(loadRate * 100f))`. This is a useful pattern to study if you want to create custom histograms or progress bars in your own UI Toolkit menus.
* **Dependency on Logical DLL**: These UI components rely on data gathered by `AttractionLoadRate` and `Attraction` components from the `Timberborn.Attractions` module.
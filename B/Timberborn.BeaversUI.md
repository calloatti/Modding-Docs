# Timberborn.BeaversUI

## Overview
The `Timberborn.BeaversUI` module provides the user interface components specifically related to beavers. It acts as the bridge between the logic in `Timberborn.Beavers` (and related systems like housing and employment) and what the player actually sees on their screen.

This module is responsible for rendering information in the Entity Panel (when a beaver is clicked), generating rows in the Batch Control (overview) windows, handling audio feedback when a beaver is selected, and providing developer tools for spawning beavers.

---

## Key Components

### 1. Entity Panel Fragments (The Inspector)
These classes inject UI elements into the menu that appears when you click on a beaver in the game world.
* **`AdulthoodFragment`**: Displays a progress bar showing a child beaver's growth towards adulthood. It binds to the `Child.GrowthProgress` property.
* **`BeaverBuildingsFragment`**: Displays two buttons: one for the beaver's `Dweller` status (Home) and one for their `Worker` status (Workplace).
    * If a home/workplace is assigned, the button shows the building's icon and clicking it focuses the camera on that building.
    * This fragment explicitly checks `Contaminable.IsContaminated`. If a beaver is sick, the workplace UI is hidden entirely.

### 2. Batch Control Items (The Overview Menu)
These classes provide the specific UI widgets used in the `BatchControl` module (e.g., the "Characters" tab).
* **`AdulthoodBatchControlRowItem`**: Similar to the fragment, but renders as a text label (e.g., "45%") inside a list row instead of a progress bar.
* **`BeaverBuildingsBatchControlRowItem`**: Provides miniature versions of the Home and Workplace buttons for the overview list.

### 3. Visual Representation & Audio (`BeaverEntityBadge` & `BeaverSelectionSound`)
These decorators are attached to every beaver via `TemplateModule.Builder`.
* **`BeaverEntityBadge`**: Implements `IEntityBadge` to provide the subtitle (e.g., "Age 15") and the clickable subtitle (e.g., the District name). It also determines which avatar icon to display, switching to the `ContaminatedAdultAvatar` or `ContaminatedChildAvatar` if the beaver is sick.
* **`BeaverSelectionSound`**: Implements `ISelectionListener`. When a beaver is clicked (`OnSelect`), it determines the correct audio clip to play based on four variables:
    1.  **Faction**: Determines the base sound set (e.g., Folktails vs. Iron Teeth).
    2.  **Age**: Adult vs. Child.
    3.  **State**: Determines if the beaver is actively sleeping (`Sleeping`), walking to bed (`Sleepy`), has active negative statuses (`Discontent`), or is fine (`Content`).

### 4. Dev Tools (`BeaverGeneratorTool`)
* **`BeaverGeneratorTool`**: A developer mode tool (`IDevModeTool`) that allows clicking on the terrain to instantly spawn beavers using the `BeaverFactory`. It supports spawning children or adults, and includes modifiers for spawning 10 beavers at a time.

---

## How to Use This in a Mod

### Adding Custom Info to the Beaver Panel
If you create a mod that gives beavers a new attribute (e.g., "Education Level" or "Thirst Status"), you should create a custom `IEntityPanelFragment` and bind it in your own Configurator, exactly as this module does.

```csharp
using Bindito.Core;
using Timberborn.EntityPanelSystem;

[Context("Game")]
internal class MyModBeaverUIConfigurator : Configurator
{
    protected override void Configure()
    {
        Bind<MyCustomBeaverStatFragment>().AsSingleton();
        MultiBind<EntityPanelModule>().ToProvider<MyModPanelProvider>().AsSingleton();
    }

    private class MyModPanelProvider : IProvider<EntityPanelModule>
    {
        private readonly MyCustomBeaverStatFragment _myFragment;

        public MyModPanelProvider(MyCustomBeaverStatFragment myFragment)
        {
            _myFragment = myFragment;
        }

        public EntityPanelModule Get()
        {
            EntityPanelModule.Builder builder = new EntityPanelModule.Builder();
            // AddTopFragment puts it near the top, AddMiddleFragment puts it below standard stats
            builder.AddTopFragment(_myFragment);
            return builder.Build();
        }
    }
}
```

---

## Modding Insights & Limitations

* **Audio Hardcoding**: The logic in `BeaverSelectionSound` constructs audio keys dynamically using strings like `"UI.Beavers." + soundId + ".Selected." + text + stateKey`. If you are adding a custom faction via a mod, you *must* ensure your audio asset bundles strictly adhere to this exact naming convention (e.g., `UI.Beavers.MyFaction.Selected.Adult_Content`), or the game will fail to play selection sounds for your beavers.
* **Contamination Hardcoding**: The `BeaverBuildingsFragment` contains hardcoded logic (`IsWorkplaceVisible`) that explicitly checks the `Contaminable` component. If a beaver is sick, it forcibly hides the workplace UI. If your mod introduces a new disease or status that should *also* hide the workplace, you cannot easily hook into this existing fragment; you would have to replace or patch the `IsWorkplaceVisible` property using Harmony.
* **Status Subject Dependency**: The audio logic uses `_statusSubject.ActiveStatuses.Count > 0` to determine if a beaver is "Discontent". This means *any* active status icon (thirst, hunger, broken teeth, incubation) triggers the unhappy selection sound.
# Timberborn.ConstructionSitesUI

## Overview
The `Timberborn.ConstructionSitesUI` module provides the user interface components necessary for players to interact with and monitor buildings currently under construction. This includes the progress bars, inventory requirements shown in the Entity Panel, build priority toggles, and data formatting for the Batch Control window.

---

## Key Components

### 1. `ConstructionSiteFragment`
This is the primary UI fragment that appears at the top of the Entity Panel when a player selects an unfinished building blueprint.
* **Layout**: It loads `Game/EntityPanel/ConstructionSiteFragment`, which includes a `ProgressBar`, a text description label, and a `PriorityToggleGroup`.
* **Priority Control**: It utilizes the `BuilderPriorityToggleGroupFactory` to inject the 5-tier priority buttons (Very Low to Very High) into the fragment's header.
* **Inventory Delegation**: It delegates the display of required materials (e.g., 50 Logs, 10 Planks) to the `ConstructionSiteFragmentInventory`, which generates a scrollable list of `InformationalRow` elements reflecting the blueprint's current stock vs. required capacity.

### 2. `ConstructionSiteDescriber`
A localized text formatting utility.
* It converts the `BuildTimeProgress` float into a percentage string (e.g., "45%").
* If the construction site is missing materials (`MaterialProgress < 1f`) and has no active deliveries (`!HasMaterialsToResumeBuilding`), it appends a localized warning: "Waiting for materials". This helps players understand *why* their beavers aren't building the structure.

### 3. `ConstructionSitePriorityBatchControlRowItem`
This component is used in the game's Batch Control list view (likely the "Buildings" tab) to show and allow adjustment of a construction site's priority.
* It loads a visual icon representing the current priority tier and colors it accordingly via `PriorityColors`.
* The associated factory provides "Increase" and "Decrease" buttons that leverage `Priority.Next()` and `Priority.Previous()` extension methods to shift the priority up or down directly from the list view.

### 4. `ConstructionSiteDebugFragment`
A developer-only tool injected via `builder.AddDiagnosticFragment()`.
* It adds a simple "Finish now" button to the bottom of the Entity Panel.
* When clicked, it calls `_constructionSite.FinishNow()`, instantly completing the building without requiring materials or builder time.

---

## How to Use This in a Mod

### Adding Custom Text to the Construction UI
Because `ConstructionSiteDescriber` is a `BaseComponent` attached to the `ConstructionSite` via the `ConstructionSitesUIConfigurator`, modders cannot simply inherit from it or override it. 

If your mod introduces a new requirement for construction (like a custom "Soil Quality" check) and you want to display a warning string on the construction panel, you must write your own `IEntityPanelFragment`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.EntityPanelSystem;
using UnityEngine.UIElements;

public class CustomSoilRequirementFragment : IEntityPanelFragment
{
    private MyCustomSoilComponent _soilComponent;
    private Label _warningLabel;
    private VisualElement _root;

    public VisualElement InitializeFragment()
    {
        _root = new VisualElement();
        _warningLabel = new Label("Warning: Soil too dry to build!");
        _warningLabel.style.color = UnityEngine.Color.red;
        _root.Add(_warningLabel);
        return _root;
    }

    public void ShowFragment(BaseComponent entity)
    {
        _soilComponent = entity.GetComponent<MyCustomSoilComponent>();
    }

    public void ClearFragment()
    {
        _soilComponent = null;
    }

    public void UpdateFragment()
    {
        if (_soilComponent != null && !_soilComponent.IsSoilValid)
        {
            _root.ToggleDisplayStyle(visible: true);
        }
        else
        {
            _root.ToggleDisplayStyle(visible: false);
        }
    }
}
```
You would then register this fragment in your own `Configurator` using `builder.AddMiddleFragment(new CustomSoilRequirementFragment())` to inject it into the Entity Panel.

---

## Modding Insights & Limitations

* **Entity Panel Refresh Hack**: The `ConstructionSitePanelDescriptionUpdater` singleton listens for the `EnteredFinishedStateEvent`. When a building finishes construction, its components change drastically. This singleton intercepts the event and forces the `IEntityPanel` to execute a full `ReloadDescription()`, ensuring the UI cleanly swaps from the `ConstructionSiteFragment` to the finished building's UI (like a `WorkplaceFragment` or `WaterPumpFragment`) without the player needing to re-click the building.
* **No Material Progress Bar**: The `ProgressBar` in `ConstructionSiteFragment` is hardcoded to only reflect `_constructionSite.BuildTimeProgress`. There is no unified progress bar for material delivery; materials are only represented in the `ConstructionSiteFragmentInventory` list.
# Timberborn.AttractionsBatchControl

## Overview
The `Timberborn.AttractionsBatchControl` module implements the "Wellbeing" tab (internally associated with Attractions) within the game's Batch Control panel. 

Batch Control allows players to manage groups of buildings simultaneously. This specific DLL handles the grouping, row generation, and data display for buildings that provide leisure and needs fulfillment.

---

## Key Components

### 1. `AttractionsBatchControlTab`
This class defines the "Wellbeing" tab in the Batch Control menu.
* **Properties:** It sets the tab's localized name (`Wellbeing.DisplayName`), the icon (`Attractions`), and the input binding key (`AttractionsTab`).
* **Grouping:** It filters all provided entities for those possessing an `Attraction` component and groups them by their localized display name.
* **Factory Integration:** It iterates through these groups to create `BatchControlRowGroup` objects using the `AttractionsBatchControlRowFactory`.

### 2. `AttractionsBatchControlRowFactory`
A central factory responsible for assembling a single row in the batch control list for an attraction building.
* **Composition:** It aggregates multiple specialized factories to populate various columns of the row:
    * `AttractionBatchControlRowItemFactory`: Shows current visitors vs. capacity.
    * `AttractionLoadRateBatchControlRowItemFactory`: Renders the 24-hour usage bar chart.
    * `GoodConsumingAttractionBatchControlRowItemFactory`: Manages the inventory levels for attractions that consume goods (e.g., Mud Baths).
    * `AutomatableBatchControlRowItemFactory`: Adds automation state controls.
    * `BuildingBatchControlRowItemFactory`: Adds standard building toggles (Pause/Resume).

### 3. `GoodConsumingAttractionBatchControlRowItemFactory`
A helper factory that bridges the attraction system with the inventory batch control system.
* **Logic:** If an attraction is a `GoodConsumingBuilding`, it creates an inventory capacity row item to show how much raw material (like Dirt or Water) is currently stored in the building.

---

## How and When to Use This in a Mod

Modders typically interact with this system when adding a new type of attraction building that they want to appear in the global Batch Control menu.

### Enabling Batch Control for a Custom Attraction
If you have created a custom attraction using the `AttractionSpec` (as detailed in the `Timberborn.Attractions` documentation), your building will **automatically** appear in the Wellbeing tab. 

This is because the `AttractionsBatchControlTab` filters for anything with the `Attraction` component:
```csharp
// Internal logic inside AttractionsBatchControlTab.cs
where entity.GetComponent<Attraction>()
```

### Customizing the Batch Control Row
If your modded building needs a unique column in the batch control row that vanilla attractions don't have, you would need to:
1. Create a custom `IBatchControlRowItem`.
2. Patch `AttractionsBatchControlRowFactory.Create` using Harmony to inject your new row item into the `BatchControlRow` constructor.

---

## Modding Insights & Limitations

* **Tab Order:** The `AttractionsBatchControlConfigurator` assigns the tab an order of `6`. If you are creating your own entirely new Batch Control tab, you can use different integers to control where it appears in the top-row navigation.
* **Complex Dependencies:** This DLL is a heavy "aggregator". It requires references to almost every UI-related assembly in the game (`BuildingsUI`, `ConstructionSitesUI`, `HaulingUI`, `AutomationUI`, etc.) because a single row in batch control summarizes the state of many different building systems simultaneously.
* **Localization Consistency:** Since buildings are grouped by `entity.GetComponent<LabeledEntitySpec>().DisplayNameLocKey`, ensure your modded buildings use consistent localization keys if you want multiple variants (like a Small and Large version) to be grouped together or separately as intended.
# Timberborn.BatchControl

## Overview
The `Timberborn.BatchControl` module provides the underlying framework and user interface components for the game's "Batch Control" window (the global overview menus). This system allows players to view, manage, and interact with groups of entities—such as citizens, housing, workplaces, and migration routes—from a single, unified screen rather than clicking on individual buildings or beavers in the world.

For modders, this module is highly extensible. It provides a robust, interface-driven system to inject custom tabs, rows, and interactive buttons into the global management UI, making it perfect for mods that introduce new classes of manageable entities (like custom vehicles, specialized drones, or unique building networks).

---

## Key Components

### 1. `BatchControlModule` & `BatchControlTab` (The Architecture)
These classes define the structure of the Batch Control window.
* **`BatchControlModule`**: A container built via `BatchControlModule.Builder` that registers all available tabs into the system.
* **`BatchControlTab`**: An abstract base class that represents a single page in the UI (e.g., "Workplaces"). It dictates the tab's icon, localization key, input binding, and is responsible for generating the visual rows based on the current entities in the game.

### 2. The Row System (`BatchControlRowGroup` & `BatchControlRow`)
The UI is built dynamically using a hierarchy of rows to represent game objects.
* **`BatchControlRowGroup`**: A collapsible/sortable category within a tab (e.g., grouping all "Water Pumps" together). It manages the visibility and sorting of its child rows.
* **`BatchControlRow`**: A single horizontal line representing one specific `EntityComponent`. It acts as a container for various UI items (like names, stats, or buttons).

### 3. `IBatchControlRowItem` (Interactive Elements)
This interface is the building block for the actual data and controls shown on a `BatchControlRow`.
* **Usage**: Items can be simple labels, or they can implement specialized interfaces like `IUpdatableBatchControlRowItem` (for values that change every frame) or `IClearableBatchControlRowItem`.
* **`ToggleButtonBatchControlRowItemFactory`**: A provided factory that makes it trivial to add standardized, clickable toggle buttons (e.g., pause/unpause) to a row.

### 4. Integration Controllers
* **`BatchControlBoxDistrictController`**: Manages the dropdown menu at the top of the Batch Control window, allowing players to filter the displayed rows by a specific `DistrictCenter` or view the entire settlement globally.
* **`BatchControlRowHighlighter`**: Listens to the `EntitySelectionService` and automatically highlights the corresponding row in the Batch Control menu if the player clicks on that entity in the 3D world.

---

## How to Use This in a Mod

### Adding a Custom Batch Control Tab
If your mod introduces a new system that players need to manage globally, you can create a custom tab by extending `BatchControlTab` and registering it via `Bindito`.

**1. Create the Tab Logic:**
```csharp
using System.Collections.Generic;
using Timberborn.BatchControl;
using Timberborn.CoreUI;
using Timberborn.EntitySystem;
using Timberborn.SingletonSystem;

public class MyCustomBatchTab : BatchControlTab
{
    private readonly BatchControlRowGroupFactory _rowGroupFactory;

    public MyCustomBatchTab(
        VisualElementLoader visualElementLoader, 
        BatchControlDistrict batchControlDistrict, 
        EventBus eventBus,
        BatchControlRowGroupFactory rowGroupFactory) 
        : base(visualElementLoader, batchControlDistrict, eventBus)
    {
        _rowGroupFactory = rowGroupFactory;
    }

    public override string TabNameLocKey => "MyMod.BatchControl.CustomTab";
    public override string TabImage => "my_custom_tab_icon"; // Located in Sprites/BatchControl/
    public override string BindingKey => "MyMod_ToggleCustomTab";

    protected override IEnumerable<BatchControlRowGroup> GetRowGroups(IEnumerable<EntityComponent> entities)
    {
        BatchControlRowGroup myGroup = _rowGroupFactory.CreateSortedWithTextHeader("MyMod.GroupHeader");

        foreach (EntityComponent entity in entities)
        {
            // Filter entities and add BatchControlRows to myGroup here
        }

        yield return myGroup;
    }
}
```

**2. Register the Tab in your Configurator:**
```csharp
using Bindito.Core;
using Timberborn.BatchControl;

[Context("Game")]
internal class MyBatchControlConfigurator : Configurator
{
    protected override void Configure()
    {
        Bind<MyCustomBatchTab>().AsSingleton();
        MultiBind<BatchControlModule>().ToProvider<BatchControlModuleProvider>().AsSingleton();
    }
}

internal class BatchControlModuleProvider : IProvider<BatchControlModule>
{
    private readonly MyCustomBatchTab _myCustomTab;

    [Inject]
    public BatchControlModuleProvider(MyCustomBatchTab myCustomTab) => _myCustomTab = myCustomTab;

    public BatchControlModule Get()
    {
        BatchControlModule.Builder builder = new BatchControlModule.Builder();
        // The integer determines the tab's order (left to right) in the UI
        builder.AddTab(_myCustomTab, 10); 
        return builder.Build();
    }
}
```

---

## Modding Insights & Limitations

* **Performance Optimization**: The `BatchControlRowGroup` implements highly efficient culling. It calculates the `topBound` and `bottomBound` of the scroll view and only sets `Visibility.Visible` (and updates the data) for rows currently on-screen. Modders do not need to write their own UI pooling/culling logic; it is handled automatically.
* **Sprite Paths**: When defining the `TabImage` string in your custom tab, you only provide the filename (without extension). The system automatically prepends the hardcoded path `"Sprites/BatchControl/"` before loading it via the `IAssetLoader`. Modders must ensure their AssetBundle places the icon in this exact directory structure.
* **Construction States**: The `BatchControlRow` natively listens for `EnteredFinishedStateEvent` and `EnteredUnfinishedStateEvent`. This means rows can automatically update or hide themselves based on whether the building is currently under construction, without you writing custom event listeners for it.
* **District Filtering**: The `BatchControlTab` base class automatically filters rows based on the dropdown selection (Global vs. Specific District). To support this, `BatchControlRowGroup` uses a hardcoded `BelongsToDistrict` check that looks for `Citizen`, `DistrictBuilding`, or `BuildingAccessible` components. If your custom entity does not use these base components, district filtering may not apply to your rows correctly.
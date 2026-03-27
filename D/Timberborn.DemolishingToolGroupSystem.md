# Timberborn.DemolishingToolGroupSystem

## Overview
The `Timberborn.DemolishingToolGroupSystem` module is responsible for organizing and providing the UI components related to demolition and deconstruction tools within the game's bottom bar. It groups various removal tools—such as building deconstruction, resource demolition, and recovered good stack deletion—into a single "Demolishing" tool group for the player.

---

## Key Components

### 1. Demolishing Button (`DemolishingButton`)
This class serves as the provider for the "Demolishing" section on the bottom bar. It implements `IBottomBarElementsProvider` to inject its elements into the main UI.
* **Tool Aggregation**: It gathers several specialized tools into one group:
    * **Building Deconstruction**: Handled by `BuildingDeconstructionTool`.
    * **Recovered Good Deletion**: Handled by `RecoveredGoodStackDeletionTool`.
    * **Resource Demolition**: Handled by `DemolishableSelectionTool`.
    * **Entity Deletion**: Handled by `EntityBlockObjectDeletionTool`.
    * **Cancellation**: Handled by `DemolishableUnselectionTool`.
* **UI Construction**: It uses `ToolGroupButtonFactory` to create a blue-themed group button and populates it with individual tool buttons created via `ToolButtonFactory`.
* **Logical Grouping**: Tools are programmatically assigned to the `"Demolishing"` group ID via the `ToolGroupService`.

### 2. Configuration (`DemolishingToolGroupSystemConfigurator`)
This Bindito configurator manages the injection and lifecycle of the demolishing UI components within the `"Game"` context.
* **Bottom Bar Integration**: It provides a `BottomBarModule` through the `BottomBarModuleProvider` class.
* **Placement**: The demolishing tool group is added to the left section of the bottom bar with an order weight of `50`.

---

## Modding Insights

### Adding Tools to the Demolishing Group
If a modder creates a custom removal tool (e.g., a "Deconstruct Specific Material" tool), they could theoretically inject it into this existing group by accessing the `ToolGroupService` and the `Demolishing` group ID.

### Icon Customization
The module defines several static image keys for the tool icons:
* `DeleteRecoveredGoodStackToolIcon`
* `DeleteObjectIcon`
* `DemolishResourcesTool`
* `CancelToolIcon`

---

## Related dlls
* **Timberborn.ToolSystem**: Handles the base `ITool` interface and `ToolGroupService`.
* **Timberborn.BottomBarSystem**: Manages the injection of UI elements into the game's main taskbar.
* **Timberborn.DeconstructionSystemUI**: Provides the actual tool for building removal.
* **Timberborn.DemolishingUI**: Provides the selection and unselection tools for natural resources.
* **Timberborn.RecoveredGoodSystemUI**: Manages the deletion of goods left behind after demolition.
# Timberborn.EntityPanelSystem

## Overview
The `Timberborn.EntityPanelSystem` module provides the framework and core UI components for the "Entity Panel"—the window that appears in the top-left corner of the screen when a player clicks on a building, beaver, or other selectable object in the world. It is heavily modular, allowing other game systems (and mods) to inject custom UI fragments into various predefined zones of the panel.

---

## Key Components

### 1. `EntityPanel`
This is the master singleton that manages the entire panel.
* **Event Listening**: It listens for `SelectableObjectSelectedEvent` and `SelectableObjectUnselectedEvent` to show or hide the panel.
* **Zoning**: It manages several distinct layout areas where fragments can be injected:
    * `LeftHeaderFragments`, `MiddleHeaderFragments`, `RightHeaderFragments`
    * `SideFragments`
    * `ContentFragments`
    * `DiagnosticFragments`
* **Updating**: It calls `UpdateFragment()` on every active injected fragment during the game's update loop (`UpdateSingleton`), ensuring progress bars and counters remain accurate.

### 2. `EntityPanelModule`
The configuration container used to inject custom UI fragments.
* Modders use `EntityPanelModule.Builder` to assign their custom `IEntityPanelFragment` implementations to specific zones, along with a sorting `order` to determine the vertical/horizontal placement relative to other fragments.

### 3. `IEntityPanelFragment`
The interface that every custom UI element inside the panel must implement.
* `InitializeFragment()`: Called once when the game loads to create the UIElements tree.
* `ShowFragment(BaseComponent entity)`: Called when an entity is clicked. Fragments should inspect the `entity` to see if they apply (e.g., checking if it has a `WaterPump` component), and toggle their visibility accordingly.
* `UpdateFragment()`: Called every frame while the panel is visible.
* `ClearFragment()`: Called when the entity is deselected.

### 4. `EntityDescriptionService`
This service aggregates all the textual information, flavor text, and input/output icons for the selected entity.
* It queries the selected entity for all components implementing `IEntityDescriber`.
* It calls `DescribeEntity()` on each one, sorting the resulting `EntityDescription` blocks by their `Order` value.
* It automatically formats the output, separating flavor text, production recipes, and generic descriptions into appropriate visual containers.

---

## Default Fragments & Services

* **`UnselectObjectFragment`**: The "X" button in the right header that closes the panel and clears the selection.
* **`FollowObjectFragment`**: The crosshairs button in the right header that locks the camera to the selected entity.
* **`DiagnosticFragmentController`**: Manages developer-only diagnostic fragments. It only displays these fragments if the `DevModeManager.Enabled` flag is true.
* **`EntityBadgeService`**: Queries the selected entity for an `IEntityBadge` to determine the avatar image, subtitle, and warnings displayed in the main header (e.g., the beaver's face and job title).

---

## How to Use This in a Mod

### Adding a Custom UI Panel to a Building
If you create a custom building and want to display a special UI panel when it is clicked (e.g., a custom progress bar or a button), you must implement `IEntityPanelFragment` and bind it using an `EntityPanelModuleProvider`.

```csharp
using Bindito.Core;
using Timberborn.EntityPanelSystem;

// In your Configurator class:
[Context("Game")]
public class MyModUIConfigurator : Configurator {
    
    private class MyPanelModuleProvider : IProvider<EntityPanelModule> {
        private readonly MyCustomFragment _myCustomFragment;

        public MyPanelModuleProvider(MyCustomFragment myCustomFragment) {
            _myCustomFragment = myCustomFragment;
        }

        public EntityPanelModule Get() {
            EntityPanelModule.Builder builder = new EntityPanelModule.Builder();
            // Inject into the bottom of the main content area
            builder.AddBottomFragment(_myCustomFragment); 
            return builder.Build();
        }
    }

    protected override void Configure() {
        Bind<MyCustomFragment>().AsSingleton();
        MultiBind<EntityPanelModule>().ToProvider<MyPanelModuleProvider>().AsSingleton();
    }
}
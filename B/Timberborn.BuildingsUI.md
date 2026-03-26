# Timberborn.BuildingsUI

## Overview
The `Timberborn.BuildingsUI` module is responsible for the user interface components related to buildings in Timberborn. It primarily focuses on entity selection panels (the window that appears when you click a building) and batch control rows (the list view of multiple buildings of the same type). It provides the UI elements to pause/resume buildings, delete them, and toggle looping sounds.

---

## Key Components

### 1. Entity Panel Fragments
These classes implement `IEntityPanelFragment` to inject specific UI blocks into the `EntityPanelModule`.

* **`PausableBuildingFragment`**: Displays the play/pause toggle button. 
    * It binds to the `"ToggleBuildingPause"` hotkey. 
    * It queries the selected entity's `PausableBuilding.IsPausable()` method. If false (e.g., a decorative statue, or a building currently under construction that cannot be paused), it hides the toggle.
    * When clicked, it calls `_pausableBuilding.Resume()` or `_pausableBuilding.Pause()`.
* **`DeleteBuildingFragment`**: Displays the trash can/delete button.
    * It binds to the `"DeleteObject"` hotkey.
    * **Confirmation Logic**: When clicked, it checks if the player is holding the `"SkipDeleteConfirmation"` key (usually Shift). If so, it immediately calls `_entityService.Delete()`. If not, it delegates to the `RecoverableGoodDialogBoxShower` to ask the player "Are you sure?".
    * **Validation**: It constantly checks `_selectedBlockObject.CanDelete()` during `UpdateFragment()` to enable or disable the button (preventing deletion of indestructible objects).
* **`BuildingSoundControllerFragment`**: Displays a toggle to enable/disable looping sound effects for that specific building instance. It queries the `BuildingSoundController` component.

### 2. Batch Control (`BuildingBatchControlRowItemFactory`)
Timberborn has a "Batch Control" window where players can view a list of all identical buildings (e.g., all Water Pumps). This factory generates the UI row for each building in that list.
* **Layout**: It loads `"Game/BatchControl/BuildingBatchControlRowItem"`.
* **Content**: Each row contains:
    * A "Select" button that refocuses the camera on the building (`_entitySelectionService.SelectAndFocusOn`).
    * The building's Image and Display Name.
    * A colored `DistanceText` label (using `DistanceToColorConverter` from the Navigation module).
    * The `PausableToggle` (if the building is pausable).
    * A `ConstructionProgressBar` (if the building is currently a `ConstructionSite`).

### 3. Developer Tools
* **`AccessibleDebugger`**: A dev-mode visualizer that draws blue/red spheres and path lines showing exactly where the game thinks a building's `Accessible` node is located, and whether the NavMesh can reach it from the cursor.
* **`BuildingsModelToggler`**: Adds an option to the Dev menu to globally hide/show all building 3D meshes.

---

## How to Use This in a Mod

### Adding Custom UI Fragments to Buildings
If your mod introduces a new component (e.g., an Overclock toggle) and you want a button to appear in the entity panel when the building is clicked, you follow the pattern established in `BuildingsUIConfigurator`.

**1. Create the Fragment:**
```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CoreUI;
using Timberborn.EntityPanelSystem;
using UnityEngine.UIElements;

public class OverclockFragment : IEntityPanelFragment
{
    private readonly VisualElementLoader _loader;
    private VisualElement _root;
    private Toggle _toggle;
    private MyOverclockComponent _overclockComponent;

    public OverclockFragment(VisualElementLoader loader) { _loader = loader; }

    public VisualElement InitializeFragment()
    {
        // Assume you have a UXML file with a Toggle
        _root = _loader.LoadVisualElement("MyMod/UI/OverclockFragment");
        _toggle = _root.Q<Toggle>("OverclockToggle");
        _toggle.RegisterValueChangedCallback(evt => _overclockComponent.SetOverclock(evt.newValue));
        return _root;
    }

    public void ShowFragment(BaseComponent entity)
    {
        _overclockComponent = entity.GetComponent<MyOverclockComponent>();
        if (_overclockComponent)
        {
            _root.ToggleDisplayStyle(visible: true);
            _toggle.SetValueWithoutNotify(_overclockComponent.IsOverclocked);
        }
        else
        {
            _root.ToggleDisplayStyle(visible: false);
        }
    }

    public void ClearFragment() { _root.ToggleDisplayStyle(visible: false); }
    public void UpdateFragment() { }
}
```

**2. Inject the Fragment:**
```csharp
using Bindito.Core;
using Timberborn.EntityPanelSystem;

[Context("Game")]
internal class MyModUIConfigurator : Configurator
{
    private class EntityPanelModuleProvider : IProvider<EntityPanelModule>
    {
        private readonly OverclockFragment _fragment;
        public EntityPanelModuleProvider(OverclockFragment fragment) { _fragment = fragment; }

        public EntityPanelModule Get()
        {
            EntityPanelModule.Builder builder = new EntityPanelModule.Builder();
            // Add it below the standard pause/delete buttons
            builder.AddMiddleFragment(_fragment); 
            return builder.Build();
        }
    }

    protected override void Configure()
    {
        Bind<OverclockFragment>().AsSingleton();
        MultiBind<EntityPanelModule>().ToProvider<EntityPanelModuleProvider>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded UI Layout Dependencies**: The `BuildingBatchControlRowItemFactory` explicitly relies on finding specific elements within the UXML file via `Q<T>("StringName")`, such as `"DistanceText"`, `"PausableWrapper"`, and `"ProgressText"`. If modders attempt to completely replace the batch control UXML to add custom columns, they must maintain these exact string identifiers, or the vanilla factory will throw null reference exceptions when initializing the row.
* **Input Binding Restrictions**: Hotkeys like `"DeleteObject"`, `"SkipDeleteConfirmation"`, and `"ToggleBuildingPause"` are hardcoded string constants. Modders cannot easily remap these default behaviors for their own tools without bypassing the input service or rewriting the fragment logic.
* **Dev Mode Deletion**: The `DeleteBuildingFragment` includes a bypass `_devModeManager.Enabled && (bool)component3`. This means if the player is in Developer Mode, the delete button will appear for *any* `BlockObject`, even if it isn't technically a `Building` or `ConstructionSite` (e.g., natural terrain blocks or indestructible ruins). Modders should be aware that their "indestructible" custom entities can still be deleted by users in dev mode.
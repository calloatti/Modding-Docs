# Timberborn.BuildingStatuses

## Overview
The `Timberborn.BuildingStatuses` module manages the visual positioning and behavior of floating status icons (e.g., "Paused", "No Power", "Unconnected") that appear above buildings. Its primary responsibility is to dynamically calculate the correct vertical offset for these icons so they float neatly above the building's 3D mesh, adapting to whether the building is finished, unfinished, or partially sliced by the camera visibility tool.

---

## Key Components

### 1. `BuildingStatusIconOffsetter`
This is the core component attached to every building that manages its status icon positioning.
* **Mesh Bounding Calculations**: During `PreInitializeEntity()`, it uses the `BoundsCalculator` service to analyze the 3D meshes of both the `FinishedModel` and the `UnfinishedModel`. It calculates the highest Y-coordinate of the renderers to establish the `FinishedTopBound` and `GetUnfinishedTopBound()`.
* **Dynamic Adjustments**: It listens to the `ConstructionSiteProgressVisualizer`'s `StageChanged` event. As a building is constructed and its visual scaffolding grows taller, the `GetUnfinishedTopBound()` dynamically recalculates to ensure the status icon floats higher, preventing it from clipping into the scaffolding.
* **Hardcoded Offsets**: It applies hardcoded float paddings above the mesh bounds: `FinishedOffset = 0.7f` and `UnfinishedOffset = 1f`.
* **Visibility Sync**: It links the icon's visibility directly to the building model's visibility (`SetIconVisibility`). If the `BlockObjectModelController` hides the building (e.g., it is sliced away by the Z-level tool), the floating icon is also hidden so it doesn't float confusingly in mid-air.

### 2. `BuildingStatusIconUpdater`
A global singleton that forces all building icons to recalculate their positions when major game state changes occur.
* **Event Triggers**: It listens to the `EventBus` for `ConstructionModeChangedEvent` and `MaxVisibleLevelChangedEvent` (the slice tool).
* **Deferred Updating**: When an event fires, it sets a `_updateNextFrame` flag. The actual recalculation (`_statusIconOffsetService.RepositionAllIcons()`) happens during the `UpdateSingleton()` loop. This prevents performance spikes if multiple events fire in a single frame.

### 3. `BuildingStatusesConfigurator`
This configurator operates in both the `Game` and `MapEditor` contexts. It binds the `BuildingStatusIconOffsetter` decorator to any entity possessing a `BuildingSpec`. Critically, it also injects the foundational components `StatusSubject` and `StatusIconCycler`, ensuring that every building in the game is capable of displaying and cycling through floating status icons.

---

## How to Use This in a Mod

Because `BuildingStatusesConfigurator` automatically decorates `BuildingSpec` with everything needed for status icons, modders creating custom buildings do not need to write code to get the icon system working.

If you write a custom logic script and want to display a floating status icon over your building (e.g., a "Needs Water" warning for a custom boiler), you simply register it with the `StatusSubject` that was automatically injected.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.StatusSystem;

public class CustomBoiler : BaseComponent, IUpdatableComponent
{
    private StatusSubject _statusSubject;
    private StatusToggle _needsWaterStatus;

    public void Awake()
    {
        // This component was automatically added by the configurator
        _statusSubject = GetComponent<StatusSubject>();
        
        // Create your custom icon
        _needsWaterStatus = StatusToggle.CreateNormalStatusWithFloatingIcon(
            "NeedsWaterIconId", 
            "LocKey.Boiler.NeedsWater.Long", 
            "LocKey.Boiler.NeedsWater.Short"
        );
    }

    public void Start()
    {
        _statusSubject.RegisterStatus(_needsWaterStatus);
    }

    public void Update()
    {
        if (WaterTankIsEmpty())
        {
            // The BuildingStatusIconOffsetter will automatically calculate
            // how high this icon should float above your custom 3D model!
            _needsWaterStatus.Activate();
        }
        else
        {
            _needsWaterStatus.Deactivate();
        }
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Padding Heights**: The padding values added above the calculated mesh bounds are hardcoded as `private static readonly float` variables (`FinishedOffset = 0.7f`, `UnfinishedOffset = 1f`). Modders cannot customize this distance. If you have a custom building where the icon seems to float too high or too close to the roof, you cannot adjust it via JSON specs or public API.
* **Mesh Bound Dependency**: The `BuildingStatusIconOffsetter` relies heavily on `BoundsCalculator.GetRendererYMaxBound`. This means it scans the actual `MeshRenderer` bounds of your Unity prefab. If your modded building includes invisible helper meshes, trigger volumes, or particle system bounds that stretch high into the air and are not explicitly excluded, the game will calculate the bounding box based on those invisible elements, causing your status icons to float bizarrely high in the sky.
# Timberborn.EnterableSystem

## Overview
The `Timberborn.EnterableSystem` module governs the mechanics of entities (such as beavers and bots) physically entering, occupying, and exiting buildings. It manages building capacity, hides character models while they are inside, and synchronizes visual and audio effects—like lights, animations, and particles—with the building's occupancy state.

---

## Key Components

### 1. `Enterable`
This component is attached to buildings that can be occupied.
* **Capacity Tracking**: It uses `EnterableSpec` to determine if the building has a `LimitedCapacity` (e.g., maximum workers or residents) and tracks the `NumberOfEnterersInside` via an internal `HashSet`.
* **State Management**: It checks the `OperatingState` (Finished, Unfinished, FinishedAndUnfinished) to determine if beavers can enter the building while it is still under construction.
* **Reservation System**: It tracks incoming visitors via `ReserveSlot()` and `UnreserveSlot()` to prevent multiple beavers from attempting to claim the same empty spot in a building.
* **Eviction**: If the building is paused, destroyed, or its state changes illegally, `ForceRemoveEveryone()` is called to instantly eject all occupants.

### 2. `Enterer`
This component is attached to the entities (beavers/bots) that enter buildings.
* **Model Hiding**: When `Enter(Enterable)` is executed, the beaver caches the `CurrentBuilding` and calls `_characterModel.Hide()`, removing its 3D model from the game world.
* **Exit Logic**: When `Abandon()` or `Exit()` is called, it restores the beaver's visibility and updates its rotation to match the `ExitWorldSpaceRotation` of the building's entrance door.
* **Persistence**: It saves and loads references to its `ReservedBuilding` and `CurrentBuilding` using a `ReferenceSerializer` to ensure beavers remain inside their designated buildings after a save/load cycle.

### 3. Visual & Audio Feedback
Several components react to the `Enterable.EntererAdded` and `EntererRemoved` events to visually update the building.
* **`EnterableAnimationController`**: Enables the building's animator (e.g., spinning wheels) when occupied, syncing the animation speed to the global game speed via `NonlinearAnimationManager`.
* **`EnterableIlluminator`**: Turns on the building's lights (`Illuminator`) when someone is inside, provided the building is finished.
* **`EnterableParticleController`**: Starts or stops a `ParticlesRunner` (e.g., chimney smoke) based on occupancy.
* **`EnterableSounds`**: Toggles the `BuildingSounds` component to emit noise when the building is occupied.

### 4. `RangeEnterableHighlighter`
Used during construction or selection of area-of-effect buildings (like a Medical Bed or a Monument). 
* It draws a bounding box around all `Enterable` buildings that fall within the `IBuildingWithRange` footprint of the selected object.

---

## How to Use This in a Mod

### Creating a Custom Enterable Building
If you are designing a custom building (such as a new type of house or a workplace) and want beavers to physically walk inside and disappear from the map, you must utilize the `EnterableSpec` component in your prefab's JSON definition.

You do not need to write custom C# code to make a building enterable; the core game will automatically attach the `Enterable` component if the specification exists.

*Example JSON configuration for an enterable building:*
    "Enterable": {
      "CapacityFinished": 4,
      "LimitedCapacityFinished": true,
      "CapacityUnfinished": 0,
      "LimitedCapacityUnfinished": true,
      "OperatingState": "Finished"
    }

### Adding Occupancy Visuals
You can link visual effects to your custom building's occupancy state by adding the corresponding specs to your prefab:
* **Animations**: Add `EnterableAnimationControllerSpec` to make wheels spin or gears turn only when a beaver is inside working.
* **Particles**: Add `EnterableParticleControllerSpec` with specific `AttachmentIds` to trigger smoke or sparks when the building is occupied.
* **Lights**: Add `EnterableIlluminatorSpec` to make the building's windows light up when someone enters.

---

## Modding Insights & Limitations

* **Bounds Scaling (`EntererBoundsScaler`)**: In certain situations, the game manipulates the physical `localBounds` of the meshes attached to an `Enterer` when they enter a building, scaling them down by a factor defined in `EntererBoundsScalerSpec`. Modders should be aware that the `MeshRenderer.localBounds` of a beaver might be altered while inside specific structures.
* **Status Hiding (`EntererStatusIconHider`)**: If a building implements `IStatusHider` (via `StatusHidingEnterableSpec`), any status icons floating above the beaver (like "Thirsty" or "Tired") are hidden while the beaver is inside. This prevents a clutter of negative status icons from floating above a heavily populated building like a large Lodge.

---

## Related DLLs

* **Timberborn.CharacterModelSystem**: Provides the `CharacterModel` used to physically hide and show the beaver.
* **Timberborn.BlockSystem**: Provides `BlockObject` and `PositionedEntrance` to determine where the beaver should appear and face when exiting.
* **Timberborn.Illumination**: Supplies the `IlluminatorToggle` used by the `EnterableIlluminator`.
* **Timberborn.Particles**: Supplies the `ParticlesRunner` used by the `EnterableParticleController`.
* **Timberborn.TimbermeshAnimations**: Supplies the `IAnimator` and `NonlinearAnimationManager`.
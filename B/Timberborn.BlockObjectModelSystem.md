# Timberborn.BlockObjectModelSystem

## Overview
The `Timberborn.BlockObjectModelSystem` module controls the visual representation of buildings and blocks depending on the game's current view mode and the block's physical state. It manages toggling between the standard complete model, an "uncovered" model (often used to see inside buildings or below roofs), and an "underground" model (used for objects like deep water pumps or mines that extend below the surface).

For modders, this module provides a simple, JSON-driven way to add multiple visual states to a custom building, allowing it to dynamically respond to the player's camera slicing and viewing tools.

---

## Key Components

### 1. `BlockObjectModelController` (The Manager)
This component acts as the central coordinator for a block's visual state.
* **State Tracking**: It tracks booleans like `_modelBlocked` (if the object is completely hidden), `ShouldShowUncoveredModel`, and `ShouldShowUndergroundModel`.
* **Model Updaters**: During `Awake()`, it collects all components on the entity that implement `IModelUpdater`. When the model needs to refresh, it calls `UpdateModel()` on all of them, allowing other systems (like construction or contamination) to react to model state changes.
* **Z-Offset**: It handles dynamic vertical offsetting for the underground model (`UndergroundModelZOffset`), allowing the underground portion of a model to dynamically stretch or shift based on terrain depth.

### 2. `BlockObjectModel` & `BlockObjectModelSpec`
This is the standard implementation of `IBlockObjectModel` that does the actual work of turning Unity `GameObjects` on and off.
* **JSON Configuration**: `BlockObjectModelSpec` reads four values from the block's template: `FullModelName`, `UncoveredModelName`, `UndergroundModelName`, and `UndergroundModelDepth`.
* **Visibility Logic (`UpdateModelVisibility`)**: Based on the flags in the `Controller`, it toggles the specific child `GameObject`s.
* **Shadow Management**: Noticeably, if a model is "hidden" but `showShadows` is true, the `GameObjectExtensions` utility doesn't just turn off the Renderer. Instead, it sets `Renderer.shadowCastingMode = ShadowCastingMode.ShadowsOnly`. This ensures that even if the player slices the camera down to see inside a building, the roof still casts a shadow on the floor.

### 3. `GameObjectExtensions.ToggleModelVisibility`
A static utility class that recursively iterates through a `GameObject`'s children.
* **Renderers**: Toggles `Renderer.enabled` and handles `ShadowCastingMode`.
* **Colliders**: Toggles `Collider.enabled` to ensure hidden objects cannot be clicked or interact physically.
* **Lights**: Toggles `Light.enabled` so hidden buildings stop emitting light.

---

## How to Use This in a Mod

### Creating a Building with an Uncovered State
If you are creating a custom building with a large roof (like a warehouse) and want players to be able to "slice" the camera down to see inside it, you need to set up your Unity prefab and JSON template correctly.

**1. Unity Prefab Setup:**
Inside your main building prefab, create two empty child GameObjects. 
* Name one `FullModel` and place all your meshes (including the roof) inside it.
* Name the other `UncoveredModel` and place all your meshes *except* the roof inside it.

**2. JSON Template Setup:**
Add the `BlockObjectModelSpec` to your building's template.

```json
{
  "Components": {
    "BlockObjectModelSpec": {
      "FullModelName": "FullModel",
      "UncoveredModelName": "UncoveredModel"
    }
  }
}
```
*Note: You do not need to provide an `UndergroundModelName` or `UndergroundModelDepth` if your building does not extend below ground.*

### Creating an Infinite Underground Model
If you are creating a deep mine or a pipe that extends all the way to bedrock regardless of how high up it is built, you can attach the `IInfiniteUndergroundModel` interface to one of your components. The `BlockObjectModelController` checks for this interface during `Awake()`. If present, it forces the `UndergroundBaseZ` calculation to `0` (the map's bedrock layer) instead of relying on the standard `UndergroundModelDepth` integer.

---

## Modding Insights & Limitations

* **Model Hierarchy Requirement**: The `BlockObjectModel` uses `GameObject.FindChildIfNameNotEmpty(...)` to locate the models. This means your `FullModel`, `UncoveredModel`, and `UndergroundModel` MUST be direct or indirect children of the root GameObject where the `BlockObjectModel` component sits.
* **Redundant Geometry**: The vanilla implementation requires you to explicitly duplicate your mesh renderers inside the Unity prefab. For example, the walls and floor of a building must exist inside *both* the `FullModel` GameObject and the `UncoveredModel` GameObject. The game simply swaps between the two parent objects; it does not dynamically hide specific sub-meshes within a single model.
* **Contexts**: This module is bound in both `"Game"` and `"MapEditor"`, meaning your custom model slicing logic will work perfectly while designing maps.
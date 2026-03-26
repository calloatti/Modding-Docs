# Timberborn.BlockSystemUI

## Overview
The `Timberborn.BlockSystemUI` module is the presentation and user interface layer for the mechanical Block System. It is responsible for providing visual feedback to the player (such as drawing building footprints and entrance markers), handling camera targeting, and dynamically populating the entity selection panel with relevant building traits and descriptions.


---

## Key Components

### 1. Visual Feedback Rendering
These components translate physical grid data into 3D visual indicators that help players understand placement and orientation.
* **`EntranceMarkerDrawer`**: A component that draws a 3D marker (typically an arrow) at the `DoorstepCoordinates` of a building's entrance. It actively listens to the selection system via `ISelectionListener` and `IPreviewSelectionListener`. It remains disabled to save resources, only enabling and drawing the mesh during `LateUpdate()` when the building or its construction ghost is actively selected by the player.
* **`BlockObjectBoundsDrawer`**: Calculates and draws the boundary meshes (the colored lines on the ground) around the base of a `BlockObject`. It uses a `NeighboredValues4` collection to dynamically evaluate which adjacent grid tiles are empty, selecting the appropriate edge or corner mesh to draw a clean perimeter.
* **`BlockObjectBoundsDrawerFactory`**: Loads the necessary materials and specific edge meshes (e.g., `BlockSideMesh0010`, `BlockSideMesh1111`) defined in the `BlockObjectBoundsDrawerFactorySpec` to instantiate the drawer.

### 2. Entity Panel Describers (`IEntityDescriber`)
These components are responsible for injecting formatted text into the UI panel that appears when a player clicks on a building.
* **`PlaceableBlockObjectDescriber`**: Evaluates the core `BlockObject` component and yields UI text rows denoting structural traits. It checks boolean flags to append localized strings for "Solid", "Ground Only", and "Above Ground". It also appends a "flavor description", but specifically restricts this flavor text to buildings that are fully constructed (`IsFinished`), hiding it during the preview/unfinished states.
* **`UndergroundDepthDescriber`**: Displays how deep a building reaches into the earth. It intelligently checks if the entity possesses an `IInfiniteUndergroundModel` (like deep water pumps); if so, it displays an "Infinite Depth" localization. If not, it falls back to the static integer defined in `UndergroundDepthDescriberSpec`.
* **`BlockObjectDeletionDescriber`**: Explains to the player why a demolition request is invalid. It polls all `IBlockObjectDeletionBlocker` components on the entity. If deletion is blocked, it concatenates their specific `ReasonLocKey` strings (e.g., "Another object is resting on top") into a single warning tooltip.

### 3. Camera Integration
* **`BlockObjectCameraTarget`**: Implements the `ICameraTarget` interface, allowing the game's camera to smoothly pan to and focus on the building. Rather than focusing on the absolute center of a potentially tall building, it specifically targets `BlockObjectCenter.WorldCenterAtBaseZ`, ensuring the camera frames the foundation.

---

## How to Use This in a Mod

Because this system heavily utilizes `TemplateModule.Builder` decorators, modders generally do not need to write C# to gain access to these UI elements. You simply configure the specifications in your building's JSON file.

### Adding Depth UI to a Custom Building
If you create a modded building that interacts with the underground (e.g., a custom mining drill), you can automatically get the "Underground Depth" UI text by adding the spec to your JSON:

```json
{
  "UndergroundDepthDescriberSpec": {
    "Depth": 5
  }
}
```
The `BlockSystemUIConfigurator` automatically attaches the `UndergroundDepthDescriber` component to any entity that possesses this spec.

### Interfacing with the Deletion Blocker UI
If you write a custom C# script that implements `IBlockObjectDeletionBlocker` (e.g., preventing players from deleting a sacred monument if their wellbeing is too low), you only need to return a localization key in the `ReasonLocKey` property. The `BlockObjectDeletionDescriber` will automatically pick it up and display your custom error message in the demolition tooltip.

---

## Modding Insights & Limitations

* **Hardcoded Entrance Height**: The `EntranceMarkerDrawer` uses a `private static readonly float EntranceMarkerYOffset = 0.2f;`. This means the vertical hover height of the entrance arrow is strictly hardcoded. Modders cannot adjust this offset via JSON to accommodate uniquely shaped doorsteps.
* **Automated Component Injection**: The `BlockSystemUIConfigurator` ensures consistency across all buildings by decorating core logic components with their UI counterparts. For example, any entity with a `BlockObject` automatically gets `EntranceMarkerDrawer`, `SelectableObject`, and `BlockObjectDeletionDescriber`. You do not (and should not) manually add these components to your prefab definitions.
* **Bounds Drawing Logic**: The `BlockObjectBoundsDrawer` skips drawing bounds entirely if `BlockObjectModelController.IsAnyModelShown` evaluates to true (assuming the controller exists). Furthermore, it only draws bounds for coordinates located exactly at the `bottomLevel` (`CoordinatesAtBaseZ.z`). Overhanging structures on higher Z-levels will not receive footprint boundaries on the ground.
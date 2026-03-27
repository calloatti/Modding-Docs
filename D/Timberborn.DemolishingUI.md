# Timberborn.DemolishingUI

## Overview
The `Timberborn.DemolishingUI` module provides the user interface components and selection tools for marking natural resources and structures for demolition. It bridges the gap between player input (like clicking or area-dragging) and the underlying `Timberborn.Demolishing` logic, managing visual markers, tooltips, and status warnings for blocked demolitions.

---

## Key Components

### 1. Selection & Unselection Tools
This module provides two primary tools used in the "Demolishing" bottom bar group:
* **`DemolishableSelectionTool`**: Allows players to mark resources/structures for demolition. When used, it performs an area search for entities with a `Demolishable` component. Notably, it also calls `PlantingService.UnsetPlantingCoordinates`, ensuring that if you demolish a tree, any scheduled replanting on that tile is cancelled.
* **`DemolishableUnselectionTool`**: Acts as a "cancel" tool, allowing players to unmark entities that were previously scheduled for demolition.
* **Visual Feedback**: Both tools use the `BlockObjectSelectionDrawerFactory` to highlight targeted objects and the selection area using colors defined in the `DemolishingColorsSpec`.

### 2. Entity Panel Integration (`DemolishableFragment`)
When a player selects an entity that can be demolished, this fragment appears in the side panel.
* **Interaction**: It provides a button to "Mark" or "Cancel" demolition, which is also bound to the `UniqueBuildingActionKey` (allowing for hotkey interaction).
* **Progress Tracking**: If an object is being demolished, the fragment displays a `ProgressBar` and a percentage label showing the current work progress.
* **Rewards**: It utilizes the `DemolishableScienceRewardLabel` to show the player how many science points will be gained upon successful demolition.

### 3. World Markers (`DemolishableMarkerService`)
This singleton manages the visual icons that appear above entities in the 3D world when they are marked for demolition.
* **Dynamic Drawing**: It listens for `DemolishableMarkedEvent` and `DemolishableUnmarkedEvent` to add or remove objects from its internal list.
* **Rendering**: It uses a `MeshDrawer` to render icons that always face the camera (`_cameraService.FacingCamera`) at the position defined by the entity's `MarkerPosition` component.
* **Visibility Logic**: Icons are automatically hidden if the building model is hidden or if an "uncovered" model is shown (likely used for layered structures).

### 4. Dependency Logic (`DemolitionBlockedStatus`)
This component handles the "Blocked" status icon that appears when a demolition cannot proceed.
* **Stacking Rules**: Demolition is blocked if there are objects stacked on top of the target that are *not* also marked for demolition.
* **Physics Check**: It also queries `ITerrainPhysicsService.CanBeDestroyed` to ensure removing the object won't violate physics/stability rules.

---

## How to Use This in a Mod

### Adding Science Rewards to Demolition
If you want your modded building to grant science when the player removes it, you must add the `DemolishableScienceRewardSpec` to your prefab. The UI will automatically detect this and display it in the selection fragment.

```json
{
  "DemolishableScienceRewardSpec": {
    "SciencePoints": 10
  }
}
```

### Scripting with Tools
You can programmatically trigger a "Mark for Demolition" action on an entity.

```csharp
using Timberborn.Demolishing;

public void MarkEntity(GameObject go) {
    var demolishable = go.GetComponent<Demolishable>();
    if (demolishable != null) {
        // This triggers the internal logic, the UI fragment, 
        // and the world markers automatically.
        demolishable.Mark();
    }
}
```

---

## Modding Insights & Limitations

* **Upward Picking**: The tools are created using `_areaBlockObjectPickerFactory.CreatePickingUpwards()`. This implies that the selection logic prioritizes the top-most objects in a stack when the player clicks or drags.
* **Marker Scale**: The demolition world icons are hardcoded to a scale of `(0.3, 0.3, 0.3)`. Modders cannot change this scale per-building via JSON.
* **Status Key**: The warning for a blocked demolition uses the localization key `"Demolish.Blocked"`.

---

## Related dlls
* **Timberborn.Demolishing**: The core logic provider for the `Demolishable` component and related events.
* **Timberborn.AreaSelectionSystem**: Provides the foundation for the area picker tools.
* **Timberborn.Planting**: Used by the selection tool to cancel planting on tiles where demolition is occurring.
* **Timberborn.StatusSystem**: Used to display the "Demolition Blocked" status icon.
* **Timberborn.TerrainPhysics**: Used to validate if an object is physically safe to destroy.

Would you like to examine the **Timberborn.AreaSelectionSystem** next to see how the drag-and-drop selection logic is implemented? Conclude your response with a single next step.
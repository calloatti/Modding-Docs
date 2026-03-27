# Timberborn.DeconstructionSystemUI

## Overview
The `Timberborn.DeconstructionSystemUI` module provides the user interface and player-facing tools for removing buildings and structures from the game world. It includes the specialized area-selection tool for mass demolition, handles audio feedback for deconstruction events, and integrates with the recoverable goods system to show players what resources they will regain.

---

## Key Components

### 1. Building Deconstruction Tool (`BuildingDeconstructionTool`)
This class is the primary implementation of the building removal tool found in the game's bottom bar.
* **Tool Functionality**: It inherits from `BlockObjectDeletionTool`, allowing for both single-click and area-drag selection of buildings for demolition.
* **Recoverable Goods Integration**: 
    * While hovering or selecting, it enables a specialized tooltip (`RecoverableGoodTooltip`) that dynamically lists the resources the player will receive back.
    * It uses `RecoverableGoodElementFactory` to inject a resource breakdown directly into the confirmation dialog box.
* **Validation**: It checks `IBlockObjectDeletionBlocker` components on target buildings. If a building is part of a stack where deletion is blocked (e.g., a critical foundation), the tool will prevent selection.
* **Additional Recovery**: It supports the `IRecoverableObjectAdder` interface, which allows a building to mark additional hidden objects for recovery when it is deconstructed.

### 2. Audio Feedback (`DeconstructionSoundPlayer`)
This singleton manages the sound effects associated with removing buildings.
* **Event-Driven**: It listens for the `BuildingDeconstructedEvent` from the core deconstruction system.
* **Optimized Playback**: Instead of playing a sound for every single building in a mass-deletion (which would be deafening), it sets a `_shouldPlaySound` flag. During `UpdateSingleton`, it plays the `"UI.Buildings.Deconstruction"` sound exactly once per frame if the flag is set, regardless of how many buildings were actually removed.

### 3. Debugging Tools (`BuildingDeconstructionToolPreviewDisabler`)
This is a developer module (`IDevModule`) that adds a toggle to the Dev Menu.
* It allows developers to disable the visual preview of the deconstruction tool, likely for performance testing or capturing clean screenshots.

---

## How to Use This in a Mod

### Creating Indestructible Buildings
If you are modding a building and want to prevent the player from accidentally deleting it using the deconstruction tool, you should implement `IBlockObjectDeletionBlocker`.

```csharp
public class MyModIndestructibleBlocker : MonoBehaviour, IBlockObjectDeletionBlocker {
    // If this is true, the BuildingDeconstructionTool will treat the object as invalid
    public bool IsStackedDeletionBlocked => true;
}
```

### Adding Extra Recovery Items
If your building should drop a specific unique item when destroyed that isn't part of its standard building cost, you can implement `IRecoverableObjectAdder`.

```csharp
public class MyModScrapGenerator : MonoBehaviour, IRecoverableObjectAdder {
    public BlockObject GetAdditionalObjectToRecover() {
        // Return a reference to another object/component to be recovered
        return myExtraScrapReference;
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Sound Key**: The deconstruction sound is hardcoded to `"UI.Buildings.Deconstruction"`. Modders cannot change this sound per-building; it is a global UI effect.
* **Preview Filtering**: The `PreviewCallback` explicitly clears the `_objectsToDeconstruct` hashset every time it runs to ensure the visual highlights don't "stick" to tiles the mouse has already left.
* **Undo System Integration**: This tool is fully integrated with the `IUndoRegistry`, meaning players can revert accidental mass-deletions performed with this tool.

---

## Related dlls
* **Timberborn.DeconstructionSystem**: Provides the core logic and events for building removal.
* **Timberborn.RecoverableGoodSystemUI**: Used to generate the resource recovery tooltips and dialog content.
* **Timberborn.AreaSelectionSystem / UI**: Provides the foundational logic for dragging a selection box across the map.
* **Timberborn.UndoSystem**: Handles the ability to reverse the demolition action.

Would you like to examine the **Timberborn.RecoverableGoodSystemUI** next to see how resource return values are calculated and displayed? Conclude your response with a single next step.
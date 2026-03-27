# Timberborn.CursorToolSystem

## Overview
The `Timberborn.CursorToolSystem` module manages the primary mouse interaction layer of the game. It defines the "default" state of the game cursor (when not building or using specialized tools), handles entity selection via raycasting, translates 2D screen mouse positions into 3D grid coordinates, and provides debugging overlays for coordinate tracking.

---

## Key Components

### 1. `CursorTool` (The Default State)
This is the core implementation of the standard selection tool.
* **Selection Logic**: It implements `IInputProcessor`. When the player clicks (`MainMouseButtonDown`) and the mouse is not over a UI element, it uses the `SelectableObjectRaycaster` to identify objects.
* **Selection Handling**: If an object (like a beaver or building) is hit, it calls `_entitySelectionService.Select(hitObject)`; otherwise, it clears the current selection.
* **System Integration**: It is registered as the `IDefaultToolProvider`, meaning the game automatically reverts to this tool whenever another tool (like the path-building tool) is closed or cancelled.

### 2. `CursorCoordinatesPicker`
A critical utility class that translates screen points into actionable 3D data.
* **Coordinate Translation**: It uses the `CameraService` to project a ray from the mouse position into grid space.
* **Height-Aware Picking**: It calculates the exact 3D intersection point and the corresponding `Vector3Int` tile coordinates.
* **Layer Logic**: It differentiates between hitting raw terrain and hitting specific building layers, such as "Floor" occupations or "Stackable" blocks (e.g., platforms). For stackable objects, it intelligently finds the top-most valid Z-level (`num + 1`) so that tools like paths can be placed on top of structures.

### 3. Debugging Tools (`CursorDebugger` & `CursorDebuggingPanel`)
These components provide real-time spatial data to developers and modders when `DebugMode` is enabled.
* **Visual Markers**: The `CursorDebugger` instantiates two 3D prefabs: a `Crosshair` (at the exact mouse intersection point) and a `Tile` marker (snapped to the center of the current grid cell).
* **Data Readout**: The `CursorDebuggingPanel` adds a "Cursor" section to the debug UI, displaying raw block coordinates, the world-space intersection position, and the flat map index (Cell-to-Index conversion).

### 4. `CursorVisibilityToggler`
A utility singleton that allows for manual control over the OS cursor.
* It listens for the `ToggleCursorVisibilityKey`.
* It interacts with the `MouseController` to force the hardware cursor to show or hide, which is likely used for cinematic mode or specific input-heavy gameplay states.

---

## How to Use This in a Mod

### Retrieving the Current Tile Under the Mouse
If you are building a custom tool or a modded interface that needs to know what tile the player is hovering over, you should inject the `CursorCoordinatesPicker`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CursorToolSystem;
using UnityEngine;

public class MyModdedTool : BaseComponent
{
    private CursorCoordinatesPicker _picker;

    [Inject]
    public void InjectDependencies(CursorCoordinatesPicker picker)
    {
        _picker = picker;
    }

    public void Update()
    {
        // Pick() returns the coordinates of what the mouse is hovering over
        CursorCoordinates? mouseData = _picker.Pick();
        
        if (mouseData.HasValue)
        {
            Vector3Int tile = mouseData.Value.TileCoordinates;
            Debug.Log($"Mouse is over tile: {tile}");
        }
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Selection Behavior**: The `CursorTool` includes a `DisableNextExitUnselect()` method. This is an internal state-management hack used to prevent the beaver/building you just clicked from being unselected if the system forces a tool swap immediately after selection.
* **Stackable Cache**: `CursorCoordinatesPicker` uses a private `_stackableCoordinatesCache` list to find the top of buildings. If a building has an extremely high number of blocks, this calculation is performed via `_stackableCoordinatesCache.Max()` which could have minor performance implications if called multiple times per frame across many buildings.
* **Raycasting Order**: The picker always prioritizes `BlockObject` (buildings) before falling back to `TerrainPicker`. This means if a modder creates a building that is technically invisible or very small, the cursor might still "snag" on the building's logical bounds rather than hitting the ground behind it.
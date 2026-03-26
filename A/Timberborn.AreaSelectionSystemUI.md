# Timberborn.AreaSelectionSystemUI

## Overview
The `Timberborn.AreaSelectionSystemUI` module bridges the gap between the logic of selecting an area (handled in `Timberborn.AreaSelectionSystem.dll`) and the visual feedback the player receives on-screen. 

It provides two main visual elements: 
1. **In-world rendering:** Highlighting objects and drawing a colored box on the terrain.
2. **UI panel rendering:** Displaying a small overlay that tells the player the dimensions (e.g., "5 × 4") of the area they are currently dragging.

---

## Key Components

### 1. `BlockObjectSelectionDrawer` & `BlockObjectSelectionDrawerFactory`
This class handles the in-world visual representation of an area selection.
* **Highlighter:** It uses a `RollingHighlighter` to tint the `BlockObject` entities currently within the selection bounds.
* **Terrain Drawing:** It uses `RectangleBoundsDrawer` (from the logical DLL) to draw a grid/border on the ground.
* **Integration:** It passes the selection coordinates to the `MeasurableAreaDrawer` so the UI knows how big the box is.
* **Usage:** Modders should use the `BlockObjectSelectionDrawerFactory` to instantiate this drawer with custom colors.

### 2. `MeasurableAreaDrawer`
This is an `IToolFragment` and an `ILateUpdatableSingleton` that displays the "X × Y" text box on the screen while the player is dragging a tool.
* **Lifecycle:** Because it is an `IToolFragment`, it is automatically injected into the `ToolPanelModule`. This means it will appear alongside the active tool's UI (like the bottom-center toolbar).
* **Logic:** Every frame, other scripts call `AddMeasurableCoordinates()` with the grid coordinates they are selecting. In `LateUpdateSingleton()` (which runs after all normal updates), it calculates the minimum and maximum X/Y bounds of those coordinates, updates the text label, and then clears the list for the next frame.

---

## How and When to Use This in a Mod

If your mod includes a custom tool that allows the player to click and drag (like a mass-harvest tool, a terraforming tool, or a zoning tool), you should use this UI module to give the player standard visual feedback.

### Example: Adding UI to a Custom Area Tool
Combine this with the `AreaBlockObjectPicker` from the previous DLL.

```csharp
using System.Collections.Generic;
using Timberborn.AreaSelectionSystem;
using Timberborn.AreaSelectionSystemUI;
using Timberborn.BlockSystem;
using UnityEngine;

public class MyCustomZoningTool
{
    private readonly AreaBlockObjectPicker _picker;
    private readonly BlockObjectSelectionDrawer _drawer;

    // Inject the picker factory and the drawer factory
    public MyCustomZoningTool(
        AreaBlockObjectPickerFactory pickerFactory, 
        BlockObjectSelectionDrawerFactory drawerFactory)
    {
        _picker = pickerFactory.CreatePickingUpwards();
        
        // Create the drawer with your custom colors
        Color highlightColor = new Color(0f, 1f, 0f, 0.5f); // Semi-transparent green
        Color tileColor = new Color(0f, 1f, 0f, 0.2f);
        Color sideColor = new Color(0f, 1f, 0f, 0.8f);
        _drawer = drawerFactory.Create(highlightColor, tileColor, sideColor);
    }

    public void ProcessInput()
    {
        _picker.PickBlockObjects<MyCustomComponent>(OnPreview, OnAction, OnShowNone);
    }

    // Called every frame while dragging
    private void OnPreview(IEnumerable<BlockObject> blockObjects, Vector3Int start, Vector3Int end, bool selectionStarted, bool selectingArea)
    {
        // This will highlight the objects, draw the green box on the ground,
        // AND automatically tell the MeasurableAreaDrawer to show the "X × Y" UI panel!
        _drawer.Draw(blockObjects, start, end, selectingArea);
    }

    // Called when the mouse is released
    private void OnAction(IEnumerable<BlockObject> blockObjects, Vector3Int start, Vector3Int end, bool selectionStarted, bool selectingArea)
    {
        _drawer.StopDrawing();
        // Do your tool's actual logic here...
    }

    // Called when hovering over UI elements
    private void OnShowNone()
    {
        _drawer.StopDrawing();
    }
}
```

---

## Modding Insights & Limitations

* **Automatic Tool Panel Integration:** Notice how `AreaSelectionSystemUIConfigurator` adds `MeasurableAreaDrawer` to the `ToolPanelModule`. You do not need to manage the visibility of the "Dimensions" UI yourself. If you simply call `_measurableAreaDrawer.AddMeasurableCoordinates()` (or use `BlockObjectSelectionDrawer` which calls it for you), the UI will magically appear and disappear as needed.
* **LateUpdate:** The `MeasurableAreaDrawer` uses `ILateUpdatableSingleton`. This is a Unity-specific architectural requirement: it guarantees that all your tools and pickers have finished their normal `Update()` calculations for the frame before the UI tries to measure the bounds and draw the text.
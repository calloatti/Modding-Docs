# Timberborn.ConstructionGuidelines

## Overview
The `Timberborn.ConstructionGuidelines` module is responsible for rendering the visual grid overlays that appear when the player is placing a building or holding a specific hotkey. These guidelines help the player understand exactly where a building will snap to the 3D grid, highlighting the footprint of the ghost building and drawing alignment crosses along the X and Y axes across the terrain.

---

## Key Components

### 1. `ConstructionGuidelinesRenderingService`
This singleton manages the logic for calculating and drawing the guideline tiles.
* **Visibility Triggers**: The guidelines are drawn if the `ShowGuidelinesKey` (usually 'G' or 'Alt') is held, or if a specific tool forces them via `ConstructionGuidelinesToggle`.
* **Cross Calculation**: When active and no building is being previewed, it projects an alignment cross from the mouse cursor outward across the map up to a specified `_radius`.
* **Height Awareness**: It categorizes and draws the guideline tiles into three distinct groups based on the camera's Z-level slice (`_levelVisibilityService.MaxVisibleLevel`):
    * `_tilesAtSameLevelDrawer`
    * `_tilesBelowDrawer`
    * `_tilesAboveDrawer`
* **Mesh Instancing**: To maintain performance while drawing hundreds of grid squares, it uses `MeshDrawer.DrawMultipleInstanced()` by passing lists of `Matrix4x4` transform matrices.

### 2. `BlockObjectGridFootprint`
This component is automatically attached to every `BlockObject` (building) via the `ConstructionGuidelinesConfigurator`.
* **Footprint Calculation**: When the player is dragging a "ghost" building (preview mode), `OnPostPlacementChanged()` maps out the exact 2D perimeter (`_min` and `_max`) of the building based on its occupied blocks.
* **Z-Level Logic**: Because buildings can have complex 3D shapes (e.g., stairs or multi-level factories), `UpdateLowestCoordinatePerCell` ensures that the grid footprint is drawn at the lowest occupied Z-level for each given X/Y coordinate.
* **Rendering Request**: During `OnPreviewSelect()`, it passes this calculated footprint to the `ConstructionGuidelinesRenderingService` to be drawn on screen.

### 3. `TileDrawerFactory`
A utility class that loads the necessary Unity assets (Meshes and Materials) to draw the grid lines.
* It reads the `TileDrawerFactorySpec` to find the exact file paths for the visual assets (e.g., `TilesOnSameLevelMaterialResourcePath`).
* It returns dedicated `MeshDrawer` instances for each type of guideline (Same Level, Below, Above, and Footprint).

---

## How to Use This in a Mod

### Forcing Guidelines to Appear for Custom Tools
If you are writing a custom modded tool (e.g., a measuring tape tool or an area-of-effect zoning tool) and you want the grid guidelines to automatically appear when the player equips your tool, you should use the `ConstructionGuidelinesToggle`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.ConstructionGuidelines;
using Timberborn.ToolSystem;

public class MyCustomZoneTool : Tool
{
    private ConstructionGuidelinesRenderingService _guidelinesService;
    private ConstructionGuidelinesToggle _guidelinesToggle;

    [Inject]
    public void InjectDependencies(ConstructionGuidelinesRenderingService guidelinesService)
    {
        _guidelinesService = guidelinesService;
        
        // Request a toggle token from the service
        _guidelinesToggle = _guidelinesService.GetConstructionGuidelinesToggle();
    }

    public override void Enter()
    {
        base.Enter();
        // Force the grid to appear while this tool is active
        _guidelinesToggle.ShowGuidelines();
    }

    public override void Exit()
    {
        base.Exit();
        // Hide the grid when the tool is unequipped
        _guidelinesToggle.HideGuidelines();
    }
}
```

### Disabling the Cross Guidelines
If your custom tool *is* a building placement tool, but you want to suppress the cross-shaped guidelines that follow the mouse, you must implement the empty `IBlockObjectGridTool` marker interface on your tool class. The `ConstructionGuidelinesRenderingService` explicitly checks `!(_toolService.ActiveTool is IBlockObjectGridTool)` to disable the mouse-following cross.

---

## Modding Insights & Limitations

* **Hardcoded Cross Dimensions**: The `ConstructionGuidelinesRenderingService.GetGuidelinesCoordinates` method generates the X/Y cross around the cursor. The length of the arms is strictly defined by the `Radius` found in `ConstructionGuidelinesSpec`. Modders cannot dynamically change this radius on the fly (e.g., to make the cross expand or shrink based on the selected tool).
* **Hardcoded Vertical Offset**: The tiles are drawn with a strict `private static readonly float MarkerYOffset = 0.022f;` to prevent Z-fighting with the ground mesh. If a modder introduces custom terrain blocks with extreme vertical curvature, the guidelines might clip through the geometry.
* **Global Shader Property**: The service uses `Shader.SetGlobalVector("_GuidelinesCenterCoordinates", ...)` to communicate the center of the cross to the GPU. Modders writing custom shaders must be aware that this global property exists and is updated every frame the guidelines are visible.
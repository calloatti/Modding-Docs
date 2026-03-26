# Timberborn.BuildingsNavigation

## Overview
The `Timberborn.BuildingsNavigation` module manages the intersection between buildings and the pathfinding/navigation systems. Its primary purpose is calculating and rendering the visual area-of-effect ranges for buildings (like the green/yellow/red path lines radiating from a District Center, or the bounding box of a Builder's Hut), as well as integrating buildings into the underlying NavMesh so beavers can walk on or through them.

---

## Key Components

### 1. `BuildingNavMesh`
This component physically connects a building to the walking grid.
* **Integration**: During `OnEnterFinishedState`, it calls `NavMeshObject.EnqueueAddToRegularNavMesh()`. This officially updates the global NavMesh, allowing beavers to path over the building (if the building's model supports it, like stairs or platforms).
* **Preview Support**: It also supports `OnEnterUnfinishedState`, where it adds the building to the *preview* NavMesh (`EnqueueAddToPreviewNavMesh()`). This allows the game to calculate if a planned (ghost) building will successfully connect a path before it is even built.
* **Blocking**: It provides explicit methods (`BlockAndRemoveFromNavMesh()`, `UnblockAndAddToNavMesh()`) to dynamically cut the building out of the pathing network, which is used when buildings are paused or flooded.

### 2. `DistrictPathNavRangeDrawer` & `PathMeshDrawer`
These classes are responsible for drawing the colored lines (the "path range") extending from a District Center or along roads.
* **Distance to Color**: The `DistanceToColorConverter` singleton takes the walking distance from the center and maps it to a gradient defined in JSON (`DistanceToColorConverterSpec`), transitioning the path color from green to yellow to red as the distance increases.
* **Mesh Construction**: The `DistrictPathNavRangeDrawer` queries the `INavigationRangeService` to get all valid road nodes within range. It then uses `PathMeshDrawer` instances to stitch together small 3D mesh variants (straight lines, corners, T-junctions, stairs) into a single optimized visual overlay representing the district's reach.
* **Invalidation**: The `PathNavRangeDrawerInvalidator` listens for NavMesh updates and slice-tool changes (`MaxVisibleLevelChangedEvent`) and marks the drawers as dirty, forcing them to redraw the lines if a new path is built or the camera view changes.

### 3. `BoundsNavRangeCalculator` & `BoundsNavRangeDrawer`
These classes draw the solid, flat area-of-effect highlighting (e.g., the square area of a Gatherer Flag or Builder's Hut) rather than the path-following lines.
* **Calculation**: The calculator takes a collection of `Vector3Int` coordinates and determines the perimeter. It specifically uses `IsVisibleSide` to check all 8 neighboring tiles. If a neighbor is not part of the area, that edge is considered an outer boundary, and an edge mesh is appended to that specific coordinate.
* **Optimization**: Like the path drawer, it stitches these edge meshes together using a `MeshBuilder` into a single `BoundsMesh` to minimize draw calls.

### 4. `BuildingCachingFlowField`
A performance optimization component. 
* **Caching**: When a building finishes construction, this component tells the `INavigationCachingService` to start generating and caching a "Flow Field" (a pre-calculated directional map pointing back to the building).
* **Usage**: This is heavily utilized by buildings that have dedicated workers who constantly leave and return (like lumberjacks or gatherers). Instead of pathfinding from scratch every time they want to return home, they just follow the pre-calculated flow field, saving significant CPU cycles.

---

## How to Use This in a Mod

### Forcing a Custom Range Draw
If your mod includes a custom building that should display a range overlay when selected, the vanilla system handles most of this automatically if you set up the dependencies correctly.

Make sure your building's JSON includes one of the marker specs from `Timberborn.BuildingRange`:
```json
{
  "BuildingWithRoadSpillRange": {}, 
  // OR
  "BuildingWithTerrainRange": {}
}
```

The `BuildingsNavigationConfigurator` automatically attaches the `BuildingRangeDrawer` to any `DistrictBuilding`. When the player clicks your building (`OnSelect()`), the `BuildingRangeDrawer` will ask the `BoundsNavRangeDrawingService` to calculate and draw the mesh overlay based on your building's access point.

---

## Modding Insights & Limitations

* **Hardcoded UI Layers**: The `BoundsMeshLayer` and `PathMeshDrawer` use `Graphics.DrawMesh` and hardcode the rendering layer to `Layers.UILayer`. Modders cannot easily change this to render range overlays on different camera layers or post-processing stacks.
* **Vertical Offset**: The `PathMeshDrawer` hardcodes a vertical floating offset of `0.03f` (`+ new Vector3(0f, VerticalOffset, 0f)`) to prevent the path lines from Z-fighting with the terrain.
* **Stairs Logic**: The `DistrictPathNavRangeDrawer` has explicit, hardcoded logic for stairs (`StairsConnectionKey`). It checks `coordinates.Above()` and maps it to specific "AlternativeKey" meshes. If a modder introduces a new type of vertical traversal (like an elevator or a teleporter), the path-drawing system will not natively know how to draw colored path lines connecting the upper and lower nodes without extensive patching of `IsConnectedToPath`.
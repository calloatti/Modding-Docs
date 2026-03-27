# Timberborn.CameraWorldState

## Overview
The `Timberborn.CameraWorldState` module contains specific implementations for how the camera interacts physically with the 3D game world. While the core `CameraSystem` handles the abstract math of zooming and angles, this module uses the `TerrainQueryingSystem` to determine where the camera is actually "looking" on the map and provides tools for resetting that view.

---

## Key Components

### 1. `CameraAnchorPicker`
This class implements the `ICameraAnchorPicker` interface (defined in `Timberborn.CameraSystem`) to handle the middle-mouse terrain grabbing mechanic.
* **Terrain Querying**: It takes a 3D `Ray` (usually cast from the mouse cursor) and uses the `TerrainPicker.PickTerrainCoordinates` method to find exactly where that ray intersects with the terrain mesh.
* **Water Handling**: Notably, it passes a specific predicate `IsWaterVoxel` to the `TerrainPicker`. This predicate queries the `IThreadSafeWaterMap`. This ensures that if the player middle-clicks on a river to drag the camera, the system correctly calculates the height of the *water surface* as the anchor point, rather than ignoring the water and anchoring to the riverbed far below.

### 2. `CameraWorldStateResetter`
This is a developer module (`IDevModule`) and input processor (`IInputProcessor`) that allows the player to instantly snap the camera back to a "default" viewing state.
* **Hotkeys**: It binds to the `"ResetCamera"` hotkey.
* **Reset Logic**: 
    1. It stops the camera from following any currently selected beaver or building (`_cameraTargeter.StopFollowing()`).
    2. It hardcodes the `VerticalAngle` back to `60f` degrees.
    3. It calculates the exact center of the screen (`new Vector2(Screen.width, Screen.height) * 0.5f`) and casts a ray down to the terrain.
    4. It reads the Z-height (elevation) of the terrain at the center of the screen, and dynamically adjusts the `_cameraService.ZoomLevel` based on that height (`num * DefaultZoomPerLevel`). This ensures that resetting the camera while looking at a tall mountain won't result in the camera clipping through the ground.

---

## How to Use This in a Mod

### Programmatically Resetting the Camera
If you are building a custom UI or cinematic tool and want to force the camera back to its default state without relying on the player pressing the hotkey, you can simply inject and call the `CameraWorldStateResetter`.

*(Note: Because the `ResetCamera()` method is private, you would technically need to simulate the key press or use reflection, but since it implements `IInputProcessor`, you can rely on the system handling the hotkey naturally).*

However, you can replicate its core logic easily if you want to build your own custom camera snap feature:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CameraSystem;
using Timberborn.TerrainQueryingSystem;
using Timberborn.GridTraversing;
using UnityEngine;

public class MyCustomCameraSnapper : BaseComponent
{
    private CameraService _cameraService;
    private TerrainPicker _terrainPicker;

    [Inject]
    public void InjectDependencies(CameraService cameraService, TerrainPicker terrainPicker)
    {
        _cameraService = cameraService;
        _terrainPicker = terrainPicker;
    }

    public void SnapToDefault()
    {
        // 1. Reset angles
        _cameraService.VerticalAngle = 60f;
        _cameraService.HorizontalAngle = 45f;
        
        // 2. Adjust zoom based on ground height at screen center
        Vector2 screenCenter = new Vector2(Screen.width, Screen.height) * 0.5f;
        Ray ray = _cameraService.ScreenPointToRayInGridSpace(screenCenter);
        TraversedCoordinates? hit = _terrainPicker.PickTerrainCoordinates(ray);
        
        int height = hit.HasValue ? hit.Value.Coordinates.z : 0;
        _cameraService.ZoomLevel = height * 0.1f; // 0.1f is DefaultZoomPerLevel
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Reset Values**: The `CameraWorldStateResetter` uses `private static readonly float` variables for its reset values (`DefaultZoomPerLevel = 0.1f`, `DefaultVerticalCameraAngle = 60f`). These are not read from JSON configurations or user settings. If a modder wanted the "Reset Camera" button to return to a 45-degree angle instead of a 60-degree angle, they would have to completely rewrite or bypass this class.
* **`IThreadSafeWaterMap` Dependency**: The `CameraAnchorPicker` explicitly relies on the thread-safe version of the water map. This is crucial for performance, as the camera is often being dragged and calculating raycasts concurrently while the main water physics simulation thread is running. Modders doing their own complex raycasting against water should follow this pattern to avoid thread contention.
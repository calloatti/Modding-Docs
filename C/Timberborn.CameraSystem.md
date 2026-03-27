# Timberborn.CameraSystem

## Overview
The `Timberborn.CameraSystem` is the core module responsible for the player's view of the game world. It manages the instantiation of the main Unity Camera, coordinates camera movement and rotation via keyboard and mouse inputs, handles visual optimizations like shadow distance scaling, and provides services for saving/restoring camera states. It acts as the bridge between the player's raw input and the rendering engine.

---

## Key Components

### 1. `CameraService`
This singleton is the central authority on the camera's state.
* **State Management**: It tracks `Target` (the point the camera is looking at), `VerticalAngle`, `HorizontalAngle`, and `ZoomLevel`.
* **Constraints**: It clamps target movement to the `_mapSize.TerrainSize` plus a `MapMargin` to prevent the camera from wandering infinitely into the void. It also clamps zoom levels based on current game states (e.g., standard play, Map Editor, or if `CameraSettings.UnlockZoom` is enabled).
* **Math/World Translation**: It provides essential utility methods like `ScreenPointToRayInGridSpace()` to convert a 2D mouse click on the screen into a 3D ray hitting the game grid.
* **Persistence**: It implements `ISaveableSingleton`, serializing its `CameraState` to the save file so the camera is precisely where the player left it upon reloading.

### 2. Input Controllers
The system separates input parsing into dedicated singletons:
* **`CameraMovementInput`**: Translates raw `InputService` bindings into directional vectors (`Vector2`) and screen-edge states for panning.
* **`KeyboardCameraController`**: Processes keyboard panning (WASD/Arrows), smooth rotation (Q/E), jump rotation (90-degree snaps), and zoom (+/-). It multiplies movement by `_cameraService.ZoomSpeedScale` so the camera pans faster when zoomed out.
* **`MouseCameraController`**: Manages mouse-driven navigation. It coordinates three different target pickers depending on player settings:
    * `DraggingCameraTargetPicker`: Middle-mouse drag panning.
    * `GrabbingCameraTargetPicker`: Middle-mouse terrain grabbing (moves the world relative to the mouse).
    * `EdgePanningCameraTargetPicker`: Moves the camera when the mouse hits the edge of the screen.
    * It also handles Right-Mouse-Button rotation, locking and hiding the cursor while the player rotates the view.

### 3. Rendering & Optimization
* **`ShadowDistanceUpdater`**: A critical performance optimization. Every frame (`LateUpdateSingleton`), it shoots four rays from the corners of the screen to the ground plane to calculate the maximum visible distance. It dynamically updates Unity's `QualitySettings.shadowDistance` (up to a hardcoded `MaxDistance` of 150) to match the camera's view. This ensures high-resolution shadows when zoomed in, without wasting processing power rendering shadows behind the camera.
* **`CameraAntiAliasing`**: Reads the player's graphics settings and updates the `UniversalAdditionalCameraData.antialiasing` property (FXAA, SMAA, MSAA).

### 4. `CameraStateRestorer`
A utility (often used by developers or power users) to save and load specific camera angles.
* **Memory State**: Allows saving (`SaveCameraKey`) and restoring (`RestoreCameraKey`) the camera position in RAM.
* **Clipboard State**: Allows serializing the `CameraState` to JSON and saving it to the OS clipboard (`GUIUtility.systemCopyBuffer`), so a player can share an exact camera angle with another player.

---

## How to Use This in a Mod

### Moving the Camera via Code
If you are creating a mod that needs to snap the camera to a specific location (e.g., an alert system that focuses on a disaster, or a cinematic tour mod), you should inject and use `CameraService`.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CameraSystem;
using UnityEngine;

public class CinematicController : BaseComponent
{
    private CameraService _cameraService;

    [Inject]
    public void InjectDependencies(CameraService cameraService)
    {
        _cameraService = cameraService;
    }

    public void FocusOnMonument(Vector3 monumentPosition)
    {
        // Smoothly move the camera target
        _cameraService.MoveTargetTo(monumentPosition);
        
        // Force a specific angle and zoom
        _cameraService.HorizontalAngle = 45f;
        _cameraService.VerticalAngle = 30f;
        _cameraService.ZoomLevel = -5f; // Zoom in
    }
}
```

### Forcing Billboard/UI Facing
If you create a 3D UI element (like a floating health bar) that must always look at the player, you can attach the `FacingCamera` component.

```csharp
// In your custom building/entity setup
public void SetupFloatingHealthBar()
{
    FacingCamera facingCam = GetComponent<FacingCamera>();
    // Pass the transform of the health bar mesh
    facingCam.Enable(myHealthBarMesh.transform); 
}
```

---

## Modding Insights & Limitations

* **Hardcoded Input Strings**: The `CameraMovementInput` class hardcodes all input bindings as `private static readonly string` fields (e.g., `"RotateCameraRight"`, `"MoveCameraFast"`). Modders cannot easily intercept or change the core camera control layout without bypassing this singleton and implementing their own `IInputProcessor`.
* **Universal Render Pipeline (URP)**: Timberborn explicitly relies on Unity's URP. The `CameraAntiAliasing` and `ShadowDistanceUpdater` explicitly cast `QualitySettings.renderPipeline` to `UniversalRenderPipelineAsset`. If a modder attempts to use standard pipeline shaders or tries to implement an alternative rendering pipeline, these core singletons will throw casting exceptions and crash the game.
* **Orthographic vs Perspective**: The `CameraService` calculates movement and distance based on `_cameraServiceSpec.BaseDistance` and angles (`OffsetFromTarget = Rotation * Vector3.back * DistanceFromTarget`). This math assumes a standard Perspective camera setup. Modders attempting to force the Unity Camera into Orthographic mode will find that standard zoom controls and edge panning break completely, as `CameraService` does not modify `Camera.orthographicSize`.
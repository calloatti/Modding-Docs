# Timberborn.CoreSound

## Overview
The `Timberborn.CoreSound` module serves as the central manager for how the player perceives the game's audio environment. Rather than simply attaching an audio listener directly to the camera, this module dynamically calculates where the player's "ears" should be based on screen-center intersections with the 3D world. It also handles dynamic audio mixing, such as fading out factory machinery noises when the camera is zoomed high into the sky.

---

## Key Components

### 1. The Dynamic Listener (`SoundListener`)
Timberborn uses a sophisticated approach to ensure the soundscape matches the player's focus on the map.
* **Screen Raycasting**: During `LateUpdateSingleton`, the system casts a ray from the center of the screen into grid space to determine the focus point. 
* **Target Prioritization**: The listener logic checks for intersections with both the `Terrain` and `BlockObject` (buildings). If the player is looking at a building that is closer than the ground, the building becomes the focus for the listener.
* **Listener Positioning**: The `_soundSystem.ListenerPosition` is set to that focal point, adjusted vertically based on the camera's zoom level via `_maxVerticalListenerPositionAboveGround`.
* **Smoothing**: To prevent audio from snapping jarringly when scrolling across cliffs, the listener position is interpolated using `Vector3.Lerp` with a `0.1f` factor.

### 2. Distance-Based Mixing (`CameraHeightVolumeUpdater`)
This singleton modifies the master volumes of specific audio mixers based on the player's zoom level to provide a more immersive experience.
* **Building Fade**: It calculates the distance between the listener and the camera, then fades the `Building` mixer (machinery and beaver activity) based on `MinBuildingFadeDistance` and `MaxBuildingFadeDistance`.
* **Ambient & Wind Fade**: Using the `NormalizedDefaultZoomLevel`, it increases the volume of the `Wind` mixer and decreases the `Ambient` ground mixer as the camera moves higher. 
* **Volume Smoothing**: Changes to mixer volumes are clamped to a maximum of `0.05f` per frame to ensure transitions feel natural and not abrupt.

### 3. Entity Selection Sounds (`BasicSelectionSound`)
This component is attached to selectable objects to provide immediate audio feedback.
* **Standard Audio**: When an entity is selected, it triggers a 2D UI sound formatted as `"UI.BasicSelection." + SoundName`.
* **Alternative Audio**: If a `BasicSelectionSoundSpec` includes an `AlternativeSoundName`, there is a hardcoded 10% chance to play a special `".AltSound"` variation instead.

### 4. Mixer Identification (`MixerNames`)
This static utility defines the core mixer keys used throughout the sound module.
* **`Building`**: Used for structures and machinery.
* **`Ambient`**: General environment background noise.
* **`Wind`**: High-altitude atmospheric noise.
* **`Environment`**: Specific terrain or nature effects.
* **`UI`**: Menu and selection sound effects.

---

## How to Use This in a Mod

### Custom Building Selection Sounds
If you create a custom building, you can easily add specific click sounds by attaching the `BasicSelectionSoundSpec` in your JSON file.

```json
{
  "BasicSelectionSoundSpec": {
    "SoundName": "MyMod_CrateClick",
    "AlternativeSoundName": "MyMod_CrateSqueak"
  }
}
```
*Note: The actual audio clip must be registered in an asset bundle using the corresponding string keys.*

---

## Modding Insights & Limitations

* **Hardcoded Mixer Dependencies**: `MixerNames` defines a fixed set of mixer strings. If a modder creates a entirely new audio mixer category (e.g., `"Radio"`), the `CameraHeightVolumeUpdater` will not automatically manage its volume based on zoom levels.
* **Hardcoded Variation Chance**: The 10% probability for the "AltSound" is hardcoded in `BasicSelectionSound.GetSoundName()`. Modders cannot adjust the rarity of alternative sounds through the spec file alone; it requires a Harmony patch to change the probability.
* **Vertical Listener Limits**: The `SoundListener` calculates the vertical offset using `NormalizedDefaultZoomLevel`. If a mod radically increases the maximum camera height, the listener may move too far above the ground, causing building sound effects to fade out sooner than intended.
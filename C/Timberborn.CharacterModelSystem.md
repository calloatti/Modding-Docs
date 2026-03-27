# Timberborn.CharacterModelSystem

## Overview
The `Timberborn.CharacterModelSystem` manages the physical and visual representation of characters (beavers and bots) in the 3D world. While other systems handle the AI logic of *where* a character should go and *what* they should do, this module ensures the 3D model accurately reflects that state by handling mesh visibility, texture randomization, status icon positioning, and animation execution.

---

## Key Components

### 1. `CharacterModel`
This is the core component that wraps the actual Unity `Transform` and `GameObject` of the character's 3D mesh.
* **Movement Interpolation**: Characters in Timberborn don't instantly snap to grid coordinates. The `CharacterModel` uses `LateUpdate()` to continuously lerp its `Position` and `Rotation` to follow a designated `_target` transform (which is usually controlled by the `WalkingSystem`).
* **Visibility States**: It exposes `Show()`, `Hide()`, `BlockModel()`, and `UnblockModel()`. If the model is blocked or hidden, it disables the mesh `GameObject` and its associated `StatusVisibilityToggle` so floating status icons don't appear in empty space.
* **Blockade Overrides**: It uses a counting semaphore pattern (`_modelBlockadeIgnoringToggles`). If a system requests that the model ignore blockades (e.g., when the player clicks the character), the model will remain visible even if it technically should be hidden by the slice tool.

### 2. `CharacterModelHider` & Visibility Overrides
* **`CharacterModelHider`**: This singleton listens to the `ILevelVisibilityService` (the slice tool). If a character walks onto a grid coordinate that is currently hidden by the slice tool, the `CharacterModelHider` calls `BlockModel()` on the character, making them turn invisible so they don't clip through the sliced terrain view.
* **`VisibleSelectedCharacterModel`**: This component ensures that if a player manually selects a character, that character becomes visible regardless of the slice tool settings. It uses the `CharacterModelBlockadeIgnoringToggle` during `OnSelect()` and releases it during `OnUnselect()`.

### 3. Textures & Animations
* **`CharacterTextureSetter`**: During `PostInitializeEntity()`, this component randomly selects a `CharacterTexturePack` from the `CharacterTextureSetterSpec` array. It loads the Diffuse, Emission, Normal, and Displacement textures from the asset bundle and applies them via the `CharacterMaterialModifier`, giving individual beavers visual variety (fur colors, markings).
* **`CharacterAnimator`**: A simple wrapper around `IAnimatorController` that provides safe access to set animator parameters (`SetBool`, `SetFloat`).
* **`AnimateExecutor`**: An `IExecutor` node used by the AI behavior tree to force a character to stand still and play a specific animation for a set duration of in-game hours. It tracks the animation state via `_dayNightCycle.PartialDayNumber` and serializes the state so the animation resumes upon loading a save file.

### 4. Status Icons
* **`CharacterStatusInitializer`**: During `Awake()`, it initializes the `StatusIconCycler`, attaching the floating icons to the character's model transform.
* **`CharacterStatusIconCyclerPositioner`**: Characters move constantly, so their status icons must follow them smoothly. In `LateUpdate()`, this component calculates the raw `_characterModel.Position`, adds the predefined `_iconOffset`, and sets the `_statusIconCyclerTransform.position` directly.

---

## How to Use This in a Mod

### Adding Custom Texture Packs to Modded Characters
If you are creating a custom faction or a specialized bot character and want to give them randomized appearances, you can leverage the `CharacterTextureSetterSpec` in your entity's JSON file. 

You do not need to write custom C# code for this; just define the paths to your texture assets:

```json
{
  "CharacterTextureSetterSpec": {
    "TexturePacks": [
      {
        "DiffuseTexture": "MyMod/Textures/Bot_Red_Albedo",
        "EmissionTexture": "MyMod/Textures/Bot_Red_Emission",
        "NormalTexture": "MyMod/Textures/Bot_Normal"
      },
      {
        "DiffuseTexture": "MyMod/Textures/Bot_Blue_Albedo",
        "EmissionTexture": "MyMod/Textures/Bot_Blue_Emission",
        "NormalTexture": "MyMod/Textures/Bot_Normal"
      }
    ]
  }
}
```
The `CharacterTextureSetter` will automatically pick one of these packs at random when the character is spawned.

---

## Modding Insights & Limitations

* **Hardcoded Shader Properties**: The `CharacterTextureSetter` maps textures using hardcoded string identifiers corresponding to Unity's standard and URP shader properties (e.g., `_BaseMap`, `_EmissionMap`, `_BumpMap`). It also explicitly scales the displacement map via `_characterMaterialModifier.SetFloat(DisplacementScaleId, 3f)`. If a modder attempts to use a completely custom shader with different property names, this component will fail to apply the textures.
* **Childhood Inheritance**: The `CharacterModel` explicitly implements `IChildhoodInfluenced`. When a kit grows into an adult beaver, the system calls `InfluenceByChildhood(Character child)`, which perfectly copies the child's `Rotation` to the new adult model so there is no visual "snap" or pop when the mesh swaps.
* **No Continuous Ticking for Hidden Models**: Because `CharacterModel` uses `LateUpdate()`, if a developer attempts to pause the Unity `Time.timeScale` or heavily modifies the tick rate, the visual interpolation of the models might desync from the logical grid position.
# Timberborn.DecalSystem

## Overview
The `Timberborn.DecalSystem` module manages the visual overlay of textures (decals) onto game entities, specifically focusing on building icons and customizable character features. It supports faction-specific decals, flippable orientations, and a robust user-facing system that allows players to load their own custom textures from the local file system into the game.

---

## Key Components

### 1. The Decal Registry (`DecalService`)
This central singleton organizes all available decals into logical categories.
* **Filtering**: Upon loading, it filters `DecalSpec` objects based on the player's active faction.
* **Validation**: It ensures that requested decals exist within their specified categories; if a requested decal is missing, it reverts to the first available decal in that category as a fallback.
* **Dynamic Updates**: It manages the integration of custom user decals and handles the `ReloadCustomDecals` logic to refresh textures without restarting the game.

### 2. User-Generated Content (`UserDecalTextureRepository`)
This system allows players to inject personal images into the game world.
* **File Support**: It monitors specific subfolders within the user's data directory for `.png`, `.jpg`, and `.jpeg` files.
* **Memory Management**: It implements `IUnloadableSingleton` to ensure that custom textures are properly destroyed via `Object.Destroy` when no longer needed, preventing memory leaks from large image files.
* **Texture Creation**: It utilizes a `TextureFactory` to convert raw byte data from disk into `Texture2D` assets with `FilterMode.Bilinear` settings.

### 3. Entity Application (`DecalSupplier` & `DecalSupplierBuildingIcon`)
These components bridge the data system with the visual rendering of buildings.
* **`DecalSupplier`**: A persistent component attached to entities that tracks which decal is currently "active". It supports duplication (copy-pasting building settings) and handles state saving/loading.
* **`DecalSupplierBuildingIcon`**: The actual visual handler. It targets a specific `MeshRenderer` on the building (defined by `IconRendererName` in the spec) and applies the decal texture to the shader property `_DetailAlbedoMap3`.

### 4. Orientation Control (`FlippableDecal`)
A utility component that allows decals to be mirrored.
* It finds a child transform by name and toggles the `localScale.x` between positive and negative values to flip the texture orientation.

---

## How to Use This in a Mod

### Adding Faction-Locked Decals
Modders can define new decal sets in JSON that only appear when playing a specific faction.

```json
{
  "DecalSpec": {
    "FactionId": "IronTeeth",
    "Category": "BuildingIcons",
    "Texture": {
      "Asset": "MyMod/CustomIndustrialIcon"
    }
  }
}
```

### Creating a Building with a Customizable Icon
To create a building where the player can select a decal (like a signpost), attach the `DecalSupplier` and `DecalSupplierBuildingIcon` specs.

```json
{
  "DecalSupplierSpec": {
    "Category": "PlayerSigns"
  },
  "DecalSupplierBuildingIconSpec": {
    "IconRendererName": "SignMesh"
  }
}
```

---

## Modding Insights & Limitations

* **Shader Dependency**: The system specifically hardcodes the shader property `_DetailAlbedoMap3`. Custom modded shaders must use this exact property name if they wish to utilize the `DecalSupplierBuildingIcon` logic.
* **Legacy Support**: The `DecalSupplier` contains backward compatibility code to transition data from an older component named `TailDecalSupplier`, suggesting the system was originally rooted in character (tail) customization.
* **Validation Fallback**: If a modder or player deletes a decal that a building was previously using, the `DecalService` will automatically force the building to display the first decal in that category rather than leaving it blank or pink-textured.

---

## Related dlls
Based on the namespaces and dependencies, these assemblies are closely linked to the Decal System:
* **Timberborn.BlueprintSystem**: Handles the `DecalSpec` and `AssetRef` serialization.
* **Timberborn.Persistence / Timberborn.WorldPersistence**: Manages saving and loading the active decal state.
* **Timberborn.TextureOperations**: Provides the `TextureFactory` and `TextureSettings` for user image loading.
* **Timberborn.Rendering**: Required for the `EntityMaterials` decorator integration.
* **Timberborn.FileSystem**: Facilitates directory creation for custom user categories.

---
Would you like to examine the **Timberborn.TextureOperations** module next to see how the raw image processing is handled? Conclude your response with a single next step.
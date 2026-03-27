# Timberborn.DecalSystemUI

## Overview
The `Timberborn.DecalSystemUI` module provides the user interface components that allow players to interact with the decal system. It primary responsibility is to populate the entity selection panel with fragments that allow for selecting, flipping, and managing textures (decals) applied to buildings or characters.

---

## Key Components

### 1. The Decal Selection UI (`DecalSupplierFragment`)
This is the main fragment visible in the Entity Panel when an object with a `DecalSupplier` is selected.
* **Decal Browsing**: It manages a collection of `DecalButton` elements within a `DecalButtonContainer`, allowing players to click to select a specific texture from the category specified by the entity.
* **User Content Integration**: It provides "Browse" and "Refresh" buttons. 
    * The **Browse** button uses `IExplorerOpener` to open the local operating system's file directory where custom user decals are stored.
    * The **Refresh** button triggers `ReloadCustomDecals` in the core service, allowing new images added to that folder to appear in-game immediately.
* **Dynamic Updates**: It listens for `DecalsReloadedEvent` to automatically rebuild the button list when custom textures are updated.

### 2. Interaction Feedback (`DecalButton`)
This component represents an individual selectable decal in the UI list.
* **Visual State**: It displays the decal's texture as the button's background.
* **Selection Highlighting**: It manages a "Frame" element that becomes visible when the decal is either hovered over by the mouse or is currently active on the selected entity. It uses the `FrameFadeClass` to provide a distinct visual look for hover states that are not currently selected.

### 3. Orientation UI (`FlippableDecalFragment`)
A smaller fragment specifically for entities with the `FlippableDecal` component.
* **Flip Toggle**: It provides a UI `Toggle` that allows the player to flip the decal orientation.
* **Two-Way Binding**: When the toggle is clicked, it calls `_flippableDecal.SetFlip()`. During `UpdateFragment()`, it ensures the toggle state accurately reflects the current state of the entity using `SetValueWithoutNotify`.

### 4. Configuration (`DecalSystemUIConfigurator`)
This module uses a standard Bindito configurator to register the UI fragments within the "Game" context.
* **Panel Injection**: It uses an `EntityPanelModuleProvider` to add both the `DecalSupplierFragment` and the `FlippableDecalFragment` to the "Middle" section of the Entity Panel.

---

## How to Use This in a Mod

Modders don't typically need to write new code for this module unless they are building a completely custom UI. Instead, adding the correct components to a building's prefab will automatically trigger these UI fragments to appear in the Entity Panel.

### Making a Modded Building's Decal Flippable
If you want your custom sign or logo building to allow the player to flip the texture horizontally:
1. Ensure the prefab has a `DecalSupplier`.
2. Attach the `FlippableDecal` component.
3. The `FlippableDecalFragment` will automatically detect the component and show the "Flip" toggle in the UI.

---

## Modding Insights & Limitations

* **UI Virtualization**: The `DecalButtonContainer` removes and recreates all buttons every time the fragment is shown or the decals are reloaded. If a category has hundreds of decals, there might be a slight stutter when selecting the building while the UI generates numerous `VisualElement` objects.
* **Fixed Placement**: Both decal fragments are injected into the **MiddleFragment** section of the Entity Panel. This means they will generally appear below the building's name and basic stats, but above diagnostic/debug fragments.
* **UXML Dependencies**: The fragments rely on specific visual tree assets like `Game/EntityPanel/DecalSupplierFragment` and `Game/EntityPanel/DecalButton`. Modders attempting to reskin the UI must ensure these specific path structures remain intact.

---
## Related dlls
* **Timberborn.DecalSystem**: The core logic provider for texture data and custom decal management.
* **Timberborn.EntityPanelSystem**: The framework into which these fragments are injected.
* **Timberborn.CoreUI**: Provides the `VisualElementLoader` and layout utilities.
* **Timberborn.PlatformUtilities**: Supplies the `IExplorerOpener` for the "Browse" functionality.

Would you like to examine the **Timberborn.EntityPanelSystem** next to see how the game organizes these various fragments into the building selection window? Conclude your response with a single next step.
# Timberborn.BlockingSystem

## Overview
The `Timberborn.BlockingSystem` module manages the visual and interactive state of specific objects when another block is built directly above them. A common example of this in the game is a water source or a mechanical power shaft. When a player builds a platform or another building on top of it, the game needs a way to hide the original object's visuals (like the water spring particles or the spinning cog) and disable access to it without actually deleting the object.

For modders, this module provides a simple, tag-based system to dynamically disable animations, particles, visibility, and pathfinding access for your custom buildings when they are "covered up" by the player.

---

## Key Components

### 1. The Target: `BlockableObject`
This is the core component attached to any entity that *can* be blocked. 
* **State Management**: It maintains a `HashSet<object> _blockers`. As long as the set is empty, `IsUnblocked` is true. When any other object calls `Block(this)`, the blocking object is added to the set.
* **Events**: It fires `ObjectBlocked` and `ObjectUnblocked` events precisely when the set goes from 0 to 1, or 1 to 0.
* **Pathfinding Integration**: Crucially, it implements `IAccessibleValidator`. If `ValidAccessible` returns false (because the object is blocked), beavers will not be able to pathfind to the building's entrance.

### 2. The Triggers: `BlockObjectBelowBlocker` & `FinishedBlockObjectBelowBlocker`
These components are attached to the buildings doing the blocking (e.g., a wooden platform).
* **`BlockObjectBelowBlocker`**: When commanded, it queries the `IBlockService` to find all `BlockableObject` components sitting exactly one tile below its own foundation coordinates (`foundationCoordinate.Below()`). It then calls `Block()` on them.
* **`FinishedBlockObjectBelowBlocker`**: A listener that automates this process. When the building finishes construction (`OnEnterFinishedState`), it tells the `BlockObjectBelowBlocker` to apply the block. If the building is deleted or deconstructed (`OnExitFinishedState`), it unblocks the objects below.

### 3. The Visual Responders
These are specialized controllers you can attach to your `BlockableObject` to define what actually happens when it gets covered.
* **`BlockableObjectAnimationController`**: Listens to the block state. If the object is blocked, it sets the entity's `IAnimator.Enabled` to false, pausing all animations.
* **`BlockableObjectParticleController`**: Uses `BlockableObjectParticleControllerSpec` to find specific particle attachment IDs. It plays them when unblocked and stops them when blocked.
* **`BlockableObjectVisualizer`**: Uses `BlockableObjectVisualizerSpec` to find a specific child `GameObject` by name (`HideableObjectName`). It completely deactivates (`SetActive(false)`) this child object when blocked, hiding the geometry.

---

## How to Use This in a Mod

### Making a Custom Building "Blockable"
If you are creating a custom building (like a ground-level vent or a specialized crop) that should visually disappear or become inactive when a player builds a platform over it, you need to add the `BlockableObject` component and configure its responders.

**JSON Configuration (Your building's template):**
To use this system without writing any C#, you simply add the relevant specs to your building's JSON template file.

```json
{
  "Components": {
    "BlockableObjectVisualizerSpec": {
      "HideableObjectName": "MyVentsModel"
    },
    "BlockableObjectParticleControllerSpec": {
      "AttachmentIds": ["SmokeParticleAttachment"]
    }
  }
}
```
*Note: Because of `BlockingSystemConfigurator`, adding these specs automatically injects the necessary `BlockableObject` logic components into your entity.*

### Making a Custom Building a "Blocker"
If you are creating a new type of solid foundation or platform and want it to smother the objects below it, add this to its JSON template:

```json
{
  "Components": {
    "FinishedBlockObjectBelowBlockerSpec": {}
  }
}
```

---

## Modding Insights & Limitations

* **Directionality**: The vanilla `BlockObjectBelowBlocker` is hardcoded to exclusively check the tiles directly beneath its foundation (`foundationCoordinate.Below()`). You cannot use this system out-of-the-box to block objects above, beside, or inside your custom building; you would need to write a custom blocker script to check different coordinates.
* **Validation**: The system is designed to trigger when the blocking building finishes construction. If a player builds a platform over a water source, the water source will remain visible and active while the platform is still a transparent blueprint/construction site. It only disappears once the platform is 100% built.
# Timberborn.CharacterControlSystem

## Overview
The `Timberborn.CharacterControlSystem` is a specialized module designed to give external systems (or developer/cinematic tools) direct, manual control over a character's movement and animation states. It allows bypassing the standard AI behavior tree to force a character to walk to a specific grid coordinate and play a specific animation.

---

## Key Components

### 1. `ControllableCharacter`
This component is attached to `Character` entities via the `CharacterControlSystemConfigurator` and acts as the manual override switch.
* **State Hijacking**: Calling `TakeControlAndMoveTo(Vector3)` sets `UnderControl = true` and stores the target destination.
* **Animation Control**: It provides `ChangeAnimation(string)` and `PlayAnimation()` methods. It manages the `ToggleAnimationControl` method, which explicitly calls `_animatorController.Disable()` to stop standard game logic from overriding the forced animation.
* **Walking Enforcement**: Exposes `EnableForcedWalking()` and `DisableForcedWalking()`, interacting with the `WalkingEnforcer` to make the character appear to be carrying a heavy load even if their hands are empty.
* **Persistence**: Implements `IPersistentEntity`. If the character is `UnderControl` when the game saves, it serializes the `Destination`, `WaitAnimation`, and `ForcedWalking` states so the forced path resumes upon loading.

### 2. `CharacterControlRootBehavior`
This is a standard AI `RootBehavior` node that acts upon the data stored in `ControllableCharacter`.
* **Execution Flow**: Every AI tick, it checks if `_controllableCharacter.UnderControl` is true.
* **Movement Phase**: If true, it uses the `WalkToPositionExecutor` to pathfind and walk the character to the assigned `Destination`. If currently walking, it returns `Decision.ReturnWhenFinished`.
* **Animation Phase**: Once `ExecutorStatus.Success` is reached (meaning the character arrived), it triggers `_controllableCharacter.PlayAnimation()` and holds the character there by returning `Decision.ReturnNextTick()`.

---

## How to Use This in a Mod

Modders can use this system to easily script "cutscenes" or force specific behaviors without writing complex custom AI nodes.

### Forcing a Beaver to Perform an Action
If you want to hijack a specific beaver and make them walk to a town square and play a specific animation, you can retrieve the component and issue commands:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CharacterControlSystem;
using UnityEngine;

public class MyCinematicScript : BaseComponent
{
    public void StartCinematic(GameObject targetBeaver, Vector3 townSquareGridCoordinate)
    {
        ControllableCharacter controller = targetBeaver.GetComponent<ControllableCharacter>();
        
        if (controller != null)
        {
            // 1. Tell the beaver to walk to the coordinate
            controller.TakeControlAndMoveTo(townSquareGridCoordinate);
            
            // 2. Tell the beaver to play an animation when they arrive
            controller.ChangeAnimation("Idle");
            
            // Optional: Force them to walk as if carrying a heavy load
            controller.EnableForcedWalking();
        }
    }

    public void EndCinematic(GameObject targetBeaver)
    {
        ControllableCharacter controller = targetBeaver.GetComponent<ControllableCharacter>();
        
        // 3. Release control so the normal AI takes over again
        controller?.ReleaseControl();
        controller?.DisableForcedWalking();
    }
}
```

---

## Modding Insights & Limitations

* **Behavior Priority**: For this system to work, `CharacterControlRootBehavior` must be registered with a higher priority in the `BehaviorAgent` than the character's normal routines. If placed too low, the beaver will ignore the `UnderControl` flag.
* **String-Based Animations**: The `ChangeAnimation` method relies entirely on exact string matching for animation states (`WaitAnimation`). Modders must ensure they pass the correct string name as defined in the character's `IAnimatorController`.
* **No Pathfinding Fallback**: If `_walkToPositionExecutor.Launch` returns `ExecutorStatus.Failure` (e.g., the destination is unreachable), the behavior returns `Decision.ReleaseNow()`. It does not attempt to walk to the closest available node; the beaver will simply fall back to their normal AI routines until the destination becomes reachable.

---
Would you like me to process the next file?
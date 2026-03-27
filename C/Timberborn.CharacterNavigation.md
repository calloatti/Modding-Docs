# Timberborn.CharacterNavigation

## Overview
The `Timberborn.CharacterNavigation` module is a micro-module containing a single, highly focused utility component: the `Navigator`. This component is attached to every `Character` entity and provides a standardized way for the game's AI systems to determine where a character *actually is* from a pathfinding perspective.

---

## Key Components

### 1. `Navigator`
This component solves a specific architectural problem in Timberborn's grid system. Characters move continuously in 3D space (`transform.position`), but the NavMesh is a discrete grid of logical access points. 

* **`OccupiedAccessible()`**: When a character is standing inside a building (like a Lodge or a Workplace), their physical 3D transform might be anywhere inside the building's bounding box. This method queries the `IBlockService` using the character's rounded grid coordinates. If it finds a `BlockObject` with a valid, enabled `Accessible` component (meaning the character is inside a building with a designated entrance), it returns that `Accessible` node.
* **`CurrentAccessOrPosition()`**: This is the primary method used by other systems (like `Timberborn.Carrying` and `Timberborn.WalkingSystem`). 
    * It first calls `OccupiedAccessible()`.
    * If the character is inside a building, it returns the building's `UnblockedSingleAccess` point (the exact 3D coordinate of the door).
    * If the character is standing outside on a normal path or terrain, it simply returns their current `Transform.position`.

### 2. `CharacterNavigationConfigurator`
A standard configurator that automatically attaches the `Navigator` component to any entity possessing the base `Character` component.

---

## Architectural Insight: Why is this important?

Imagine a beaver working inside a massive 3x3 Factory. If the AI needs to calculate the distance from the beaver to a nearby warehouse to fetch logs, using the beaver's raw `transform.position` would result in a path calculation starting from the center of the Factory. The pathfinder might fail or generate strange paths because the center of the Factory is technically blocked/unwalkable geometry. 

By using `Navigator.CurrentAccessOrPosition()`, the AI forces the pathfinding calculation to originate from the Factory's front door, ensuring mathematically valid path generation.

---

## How to Use This in a Mod

If you are writing a custom AI behavior or a modded script that requires calculating distance to a target or initiating a new walk action, you should always use the `Navigator` rather than the character's raw transform.

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.CharacterNavigation;
using UnityEngine;

public class MyCustomAILogic : BaseComponent
{
    private Navigator _navigator;

    public void Awake()
    {
        // This is guaranteed to exist on any Character
        _navigator = GetComponent<Navigator>();
    }

    public float DistanceToTarget(Vector3 targetCoordinate)
    {
        // Correct: Starts measuring from the building's door if the beaver is inside
        Vector3 trueStartingPoint = _navigator.CurrentAccessOrPosition();
        
        // Incorrect: Vector3 trueStartingPoint = this.Transform.position;
        
        return Vector3.Distance(trueStartingPoint, targetCoordinate);
    }
}
```

---

## Modding Insights & Limitations

* **Single Access Assumption**: The `OccupiedAccessible()` method explicitly checks if `enabledComponent.HasSingleAccess` is true. If a modder creates a massive custom building with multiple discrete access points (e.g., a train station with North and South entrances), the `Navigator` will fail this check and return `null`. This forces `CurrentAccessOrPosition` to fall back to the character's raw `transform.position`, potentially breaking pathfinding logic. Modded buildings intended for workers must currently restrict themselves to a single logical entrance point if they want standard AI logic to function perfectly.
# Timberborn.Cutting

## Overview
The `Timberborn.Cutting` module manages the lifecycle and logic for natural resources that can be harvested by cutting, such as trees. It coordinates between growth states, yield production, and the physical transformation of a resource into a harvestable stack of goods.

---

## Key Components

### 1. `Cuttable`
This is the central component that defines an object as harvestable via cutting.
* **Harvest Coordination**: It monitors the `Yielder` component. When a beaver reduces the yield (by chopping), `Cuttable` triggers the resource's death and transformation.
* **Good Stack Transition**: Upon being cut, it enables a `GoodStack` (a physical pile of items like logs) using the resource's current yield and then removes the remaining yield from the original object.
* **Growth Integration**: It ensures the `Yielder` is only enabled once the associated `Growable` component confirms the resource `HasGrown`.
* **Visual Logic**: It manages an optional "leftover model" (like a tree stump), allowing it to be shown or hidden during different states.

### 2. Death and Deletion Logic
`Cuttable` handles what happens after a resource is fully harvested based on its `CuttableSpec`:
* **Remove on Cut**: If `RemoveOnCut` is true, the entity is deleted via `EntityService` as soon as the resulting `GoodStack` is empty.
* **Overridable State**: If the resource is not removed on cut, it marks the `BlockObject` as "overridable". This allows the player or game logic to place new buildings or plants on that tile once the goods have been hauled away.

### 3. `EmptyDeadNaturalResourceOverrider`
This component acts as a safety guard for the physical grid space.
* It listens for the `Died` event from `LivingNaturalResource`.
* **Space Management**: When a resource dies (e.g., a tree withers or is cut), this component checks if the entity still has meaningful yield or goods in its stack. If it is completely empty, it marks the `BlockObject` as "overridable" so the space can be reused immediately.
* **Recovery**: If the resource's death is reversed (e.g., through modding or specific game events), it restores the "non-overridable" status to protect the object's space.

---

## Data Structures

### `CuttableSpec`
A record used to define the harvest properties in prefab templates:
* **`RemoveOnCut`**: Determines if the entity disappears after harvesting.
* **`LeftoverModelName`**: The name of the child GameObject to use as a visual "stump".
* **`Yielder`**: Configuration for the specific goods and amounts produced.

---

## How to Use This in a Mod

### Creating a Custom Cuttable Tree
To create a new type of harvestable plant, you must define a `CuttableSpec` in your prefab.

```json
{
  "CuttableSpec": {
    "RemoveOnCut": false,
    "LeftoverModelName": "StumpMesh",
    "Yielder": {
      "YielderComponentName": "TreeYielder",
      "Yield": {
        "Id": "Log",
        "Amount": 1
      }
    }
  }
}
```

### Scripting with `Cuttable`
You can subscribe to harvesting events to trigger custom logic, such as spawning particles or playing a specific sound.

```csharp
public class MyModBehavior : BaseComponent, IAwakableComponent {
    private Cuttable _cuttable;

    public void Awake() {
        _cuttable = GetComponent<Cuttable>();
        _cuttable.WasCut += (sender, args) => {
            UnityEngine.Debug.Log($"{base.Name} was cut down!");
        };
    }
}
```

---

## Modding Insights & Limitations

* **Fixed Component Names**: The `Cuttable` component looks for its `Yielder` using a specific string name defined in the spec (`YielderSpec.YielderComponentName`). If your prefab has multiple `Yielder` components, ensure the name in the `CuttableSpec` matches the intended one exactly.
* **Inventory Dependency**: `Cuttable` relies heavily on the `GoodStack` component to handle the physical items left on the ground. You cannot harvest a resource into a beaver's inventory directly through this module; it *must* go through a stack in the world first.
* **Automatic Gridding**: The "Overridable" status management is handled automatically by this module. Modders do not need to manually manage `BlockObject` permissions for harvested trees, as the `EmptyDeadNaturalResourceOverrider` handles it.

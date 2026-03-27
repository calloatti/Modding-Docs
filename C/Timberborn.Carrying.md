# Timberborn.Carrying

## Overview
The `Timberborn.Carrying` module dictates how agents (beavers and bots) physically transport resources across the map. It bridges the gap between the `InventorySystem` (where goods are stored) and the `WalkingSystem` (how agents move), managing the logic for capacity limits, visual model swapping, and the AI behavior tree for fulfilling delivery jobs.

---

## Key Components

### 1. Carrier State & Capacity
The physical limitations of a carrier are defined by `GoodCarrier` and calculated dynamically.
* **`GoodCarrier`**: The core state component that stores the currently `CarriedGoods` (a `GoodAmount` struct) and tracks if the agent `IsCarrying`.
* **`LiftingCapacity`**: Calculates the maximum weight the carrier can hold by multiplying the `GoodCarrierSpec.BaseLiftingCapacity` by any active `BonusManager` multipliers tied to the `"CarryingCapacity"` ID.
* **`CarryAmountCalculator`**: Determines exactly how many items an agent will pick up by dividing the `liftingCapacity` by the specific good's `Weight`.
* **Clamping**: The calculator clamps the resulting amount between `1`, the available stock in the source inventory, and the free capacity in the destination inventory.

### 2. The Overburden Mechanic
Timberborn allows carriers to pick up an item even if it exceeds their lifting capacity, but penalizes them for it.
* **Forced Minimums**: The `CarryAmountCalculator` uses `Math.Max` to guarantee an agent will always be able to carry at least 1 unit of a good, even if the good's weight exceeds their total lifting capacity.
* **`Overburdenable`**: Monitors the carrier's hands, and if an item is picked up where the total weight exceeds the `LiftingCapacity`, it triggers the "overburdened" state.
* **Penalties**: When overburdened, the system applies a set of `OverburdenedBonuses` (defined in `OverburdenableSpec`) via the `BonusManager`, which typically includes severe movement speed reductions.

### 3. AI Execution (`CarryRootBehavior`)
This is the root behavior node that drives the carrier's actions when a job is assigned.
* **Delivery Priority**: In its `Decide()` loop, it checks `TryToDeliver` first.
* **Walking Execution**: If the agent has goods in hand, it attempts to pathfind to the destination inventory using the `WalkToAccessibleExecutor`.
* **Retrieval Fallback**: If hands are empty, it checks `TryToRetrieve`, ensuring the agent has reserved stock at the source and reserved capacity at the destination before walking to the source.
* **Dynamic Recalculation**: If an agent arrives at the source inventory, `CompleteRetrieval()` calls `RecalculateAmountToRetrieve()` to double-check that the destination inventory still has space before actually pulling the items out of the source.

### 4. Visual Representation
How a beaver physically looks while carrying items is dynamically managed.
* **`GoodCarrierModel`**: Queries the `GoodSpec` to find its `VisibleContainer` type when an item is picked up.
* **Mesh Unhiding**: Iterates through pre-instantiated 3D meshes attached to the character's hands or backpack and unhides the specific mesh that matches the container type.
* **`GoodCarrierAnimator`**: Reads the `CarryingAnimation` string from the `GoodSpec` and updates the character's animation controller.
* **`BackpackCarrier`**: If `IsBackpackEnabled` is true, the `GoodCarrierModel` hides the hand-carried meshes and shows the backpack meshes instead, while the animator forces a walking animation.

---

## How to Use This in a Mod

### Creating a Custom Carrier
If you are creating a new type of character that can carry goods (like a modded hauler bot), you need to set up the carrier specifications in your character's JSON template.

```json
{
  "GoodCarrierSpec": {
    "BaseLiftingCapacity": 20
  },
  "OverburdenableSpec": {
    "OverburdenedBonuses": [
      {
        "BonusId": "MovementSpeed",
        "Value": 0.5,
        "IsMultiplier": true
      }
    ]
  },
  "GoodCarrierModelSpec": {
    "CarriedInHandsAttachmentName": "HandsAttachment",
    "BackpackAttachmentName": "BackpackAttachment"
  }
}
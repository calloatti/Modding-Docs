# Timberborn.EntityUndoSystem

## Overview
The `Timberborn.EntityUndoSystem` module provides the framework for recording and reverting actions taken on game entities. It integrates with the broader `UndoSystem` to handle the specific complexities of creating, modifying, and deleting `EntityComponent` objects in the world.

---

## Key Components

### 1. `UndoableEntity`
A wrapper class that represents a snapshot of an entity at a specific point in time.
* **State Serialization**: It utilizes the game's persistence framework (`IPersistentEntity`, `EntitySaver`) to serialize the entity into a `SerializedEntity` object. 
* **State Snapshot**: This acts as the memory of what the entity looked like.
* **Lifecycle Methods**: It exposes methods to `Delete()`, `Create()`, and `Reload()` the entity. 
* **Create Method**: `Create()` instantiates a new entity using the saved template.
* **Reload Method**: `Reload()` overwrites the data of an existing entity with the serialized snapshot.

### 2. The Undoables
These classes implement the core `IUndoable` interface, representing discrete actions that can be reversed or re-applied.
* **`CreatedEntityUndoable`**: Represents an entity being spawned. 
* **Created Reversion**: `Undo()` deletes the entity, and `Redo()` recreates it.
* **`DeletedEntityUndoable`**: Represents an entity being removed. 
* **Deleted Reversion**: `Undo()` recreates the entity, and `Redo()` deletes it.
* **`ChangedEntityUndoable`**: Represents a modification to an existing entity's state (e.g., changing its inventory limits or pausing it). 
* **Change Snapshots**: It holds two snapshots: a `_preChangeUndoableEntity` and a `_postChangeUndoableEntity`. 
* **Change Reversion**: `Undo()` and `Redo()` trigger a `Reload()` on the respective snapshot and fire an `UndoableEntityChangedEvent`.

### 3. Change Tracking
* **`EntityLifecycleUndoableRegistrar`**: Automatically listens for `EntityCreatedEvent` and `EntityDeletedEvent` on the event bus. 
* **Automatic Registration**: If the undo system is currently allowing records (and not currently processing an undo stack), it automatically registers a `CreatedEntityUndoable` or `DeletedEntityUndoable`.
* **`EntityChangeRecorder`**: An `IDisposable` utility class used to capture state changes.
* **Before Snapshot**: When instantiated, it takes a "before" snapshot (`_preChangeUndoableEntity`).
* **After Snapshot**: When `Dispose()` is called (typically at the end of a `using` block), it takes an "after" snapshot.
* **Comparison**: It compares the two snapshots. 
* **Registration**: If they are different (`!_preChangeUndoableEntity.Equals(undoableEntity)`), it registers a `ChangedEntityUndoable` to the registry.

### 4. `UndoableEntitiesLoader`
Because undoing an action might require recreating or reloading multiple entities at once, this class acts as a batch processor.
* **Postprocessor Interface**: It implements `IUndoPostprocessor`, meaning its `PostprocessUndoables()` method is called at the end of an undo/redo cycle.
* **Batch Collection**: Instead of fully initializing entities one by one during the undo step, the undoables add their target entities to a `_entitiesToLoad` list. 
* **Batch Execution**: The postprocessor then loads and initializes them in a single optimized batch via the `EntitiesLoader`.

---

## How to Use This in a Mod

### Recording Custom State Changes
If your mod provides a UI button that changes the settings of a building, you should wrap that logic in an `EntityChangeRecorder` so the player can undo their click. You can get the recorder factory via dependency injection.

    using Timberborn.EntitySystem;
    using Timberborn.EntityUndoSystem;

    public class MyCustomBuildingConfigurator {
        private readonly EntityChangeRecorderFactory _recorderFactory;

        public MyCustomBuildingConfigurator(EntityChangeRecorderFactory recorderFactory) {
            _recorderFactory = recorderFactory;
        }

        public void ChangeBuildingSetting(EntityComponent targetBuilding, int newSettingValue) {
            // The 'using' block automatically calls Dispose() when it closes, 
            // which triggers the snapshot comparison and undo registration.
            using (_recorderFactory.CreateChangeRecorder(targetBuilding)) {
                
                // Apply your changes here
                var myComponent = targetBuilding.GetComponent<MyCustomComponent>();
                myComponent.SetSetting(newSettingValue);
                
            } // End of using block. If the state actually changed, the undo system logs it.
        }
    }

*(Note: Your custom component MUST implement `IPersistentEntity` and properly save/load the custom setting for the undo system to detect the change and revert it).*

---

## Modding Insights & Limitations

* **Event Bus Silence During Undo**: When `UndoableEntity.Reload()` or `Create()` is called during an undo cycle, it uses the core persistence loading logic. Modders should not assume standard gameplay events (like `BlockObject` placement events) fire identically during an undo operation.
* **Equality Checks**: The `ChangedEntityUndoable` determines if a change actually occurred by calling `Equals` on the `SerializedEntity` snapshots. If your component saves data that changes every frame (like a timer), wrapping it in a change recorder might result in massive, unintended undo spam.

---

## Related DLLs
* **Timberborn.UndoSystem**: Provides the `IUndoable`, `IUndoRegistry`, and `IUndoPostprocessor` interfaces that this module implements.
* **Timberborn.EntitySystem**: Provides the `EntityComponent`, `EntityService`, and lifecycle events monitored by the registrar.
* **Timberborn.WorldPersistence**: Provides the `EntitiesLoader`, `InstantiatedSerializedEntity`, and `IPersistentEntity` tools necessary to serialize and deserialize the entity snapshots.
# Timberborn.EntitySystem

## Overview
The `Timberborn.EntitySystem` module is the backbone of object management in Timberborn. It defines how game entities are instantiated, initialized, registered for quick retrieval, and ultimately deleted. It acts as a custom lifecycle wrapper around Unity's `GameObject` and `MonoBehaviour` architecture, allowing the game to control precisely when setup logic fires via dependency injection and template instantiation.

---

## Core Lifecycle Components

### 1. `EntityComponent`
This is the master component attached to every single instantiable entity in the game (buildings, beavers, trees, etc.). It dictates the strict lifecycle of all other components attached to that entity.
* **Lifecycle Interfaces**: It searches for and executes methods on any attached component that implements specific lifecycle interfaces:
    * `IPreInitializableEntity.PreInitializeEntity()`
    * `IInitializableEntity.InitializeEntity()`
    * `IPostInitializableEntity.PostInitializeEntity()`
    * `IPostLoadableEntity.PostLoadEntity()`
* **Registration**: During the `Initialize` phase, it registers itself with the global `EntityComponentRegistry` and broadcasts an `EntityInitializedEvent` over the `EventBus`.
* **Deletion**: It handles safe deletion logic (`IDeletableEntity.DeleteEntity()`), ensuring components are unregistered before calling `UnityEngine.Object.Destroy`.

### 2. `EntityService`
A global singleton used to spawn new entities into the world.
* It uses the `TemplateInstantiator` to create an `EntityComponent` based on a JSON `Blueprint`.
* It assigns a unique `Guid` to the entity.
* It registers the new entity with the `EntityRegistry` and fires the `EntityCreatedEvent`.

---

## Registry Systems

### 1. `EntityRegistry`
A simple tracker that holds every instantiated `EntityComponent` in the game.
* It provides lookup by `Guid` via the `_entities` dictionary.
* It maintains an ordered list of creation (`_entitiesInInstantiationOrder`) and tracks which templates have been spawned via `_instantiatedEntityTemplates`.

### 2. `EntityComponentRegistry`
A highly optimized lookup system for finding specific components across all entities in the game.
* **`IRegisteredComponent`**: Any component that implements this marker interface will automatically be added to this registry during the `EntityComponent` initialization phase.
* **Fast Queries**: Systems can call `GetAll<T>()` or `GetEnabled<T>()` to instantly retrieve a list of all active components of type `T` without needing to execute slow Unity `FindObjectsOfType` queries.
* **`RegisteredComponentService`**: This helper service uses reflection to determine all base types of a registered component, allowing the registry to correctly categorize derived classes.

---

## Entity Labeling

### `LabeledEntity` & `LabeledEntitySpec`
A standardized way to attach human-readable names and icons to an entity.
* **JSON Definition**: Modders define the `DisplayNameLocKey`, `DescriptionLocKey`, and `Icon` inside the `LabeledEntitySpec` block of an object's JSON file.
* **Runtime Retrieval**: The `LabeledEntity` component uses the `ILoc` service to translate the `DisplayNameLocKey` on demand, exposing the localized string via the `DisplayName` property.

---

## Modding Insights & Limitations

* **Do Not Use Unity `Start()` for Logic**: Because Timberborn manages its own complex initialization order via `EntityComponent`, modders should avoid putting critical setup logic in Unity's standard `Awake()` or `Start()` methods. Instead, implement `IInitializableEntity` and use `InitializeEntity()` to guarantee all dependencies (like templates and block objects) are fully injected before your code runs.
* **Registry Optimization**: If your custom mod component needs to be found by a global manager (e.g., a custom "PowerNode" that a global "PowerManager" needs to iterate over), simply make your component implement `IRegisteredComponent`. Your manager can then instantly fetch all instances using `EntityComponentRegistry.GetAll<PowerNode>()`.
* **Strict Deletion**: Modders should *never* call `UnityEngine.Object.Destroy()` directly on a Timberborn entity. Instead, call `EntityService.Delete(BaseComponent)`, which ensures the entity is properly unregistered from all systems and prevents memory leaks or null reference exceptions.

---

## Related DLLs

* **Timberborn.TemplateInstantiation**: Provides the `TemplateInstantiator` used by the `EntityService` to map JSON data onto Unity GameObjects.
* **Timberborn.SingletonSystem**: Provides the `EventBus` used to announce entity creation, initialization, and deletion.
* **Timberborn.BaseComponentSystem**: Provides the `BaseComponent` base class that `EntityComponent` inherits from.
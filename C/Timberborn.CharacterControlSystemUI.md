# Timberborn.CharacterControlSystemUI

## Overview
The `Timberborn.CharacterControlSystemUI` module provides the developer-facing user interface for the `Timberborn.CharacterControlSystem`. It injects a diagnostic panel into the entity selection window that allows developers (or players in dev mode) to explicitly command a beaver or bot to walk to a specific location, play a specific animation, and toggle forced walking states.

---

## Key Components

### 1. `CharacterControlFragment`
This class implements `IEntityPanelFragment` and `IInputProcessor`. It builds the UI panel that appears when a character is selected.
* **UI Elements**: It loads `"Game/EntityPanel/CharacterControlFragment"`, which includes a "Move To" button, a "Release" button, a "Forced Walking" toggle, and an Animation dropdown menu.
* **Coordinate Picking**: When the "Move To" button is clicked, it enters `_pickingCoordinates = true`, changes the cursor, and waits for a mouse click. 
* **Input Processing**: While picking coordinates, if the player clicks the terrain (and not the UI), it calls `_characterControlDestinationPicker.PickDestination()`, extracts the `Vector3`, and passes it to the character's `TakeControlAndMoveTo()` method.
* **Status Updates**: During `UpdateFragment()`, it checks the `BehaviorManager` to see if the character is actively walking to the destination or if they have arrived and are waiting, updating the UI text accordingly.

### 2. `CharacterControlDestinationPicker`
This utility class translates a mouse click on the screen into a valid 3D grid destination for the character to walk to.
* **Entity Hit**: It first tries to raycast against `SelectableObject` entities. If the player clicks a building, it checks if the building has an `Entrance`. If so, it returns the `DoorstepCoordinates` (routing the character to stand perfectly in front of the door).
* **Stackable Hit**: If the clicked building doesn't have an entrance but is stackable (like platforms), it calculates the highest Z-coordinate of the stack and returns the position immediately on top of it (`num + 1`).
* **Terrain Hit**: If no entities were hit, it falls back to the standard `TerrainPicker` to return the ground coordinate.

### 3. Animation Dropdown Handlers
* **`ControllableCharacterAnimations`**: A caching utility that retrieves all possible animation state names from the character's `IAnimatorController`. It sorts them alphabetically and ensures `"CharacterControlAnimation"` is always at the top of the list (index 0).
* **`ControllableCharacterDropdownProvider`**: Implements `IDropdownProvider`. It connects the UI dropdown element to the `ControllableCharacter`'s underlying `ChangeAnimation()` and `WaitAnimation` properties.

---

## How to Use This in a Mod

Because this UI is explicitly registered as a *Diagnostic Fragment* (`builder.AddDiagnosticFragment`), it is only visible when the game is running in Developer Mode. Modders generally do not need to interact with this module unless they are building their own developer tools.

However, if you wanted to repurpose the `CharacterControlDestinationPicker` to build a "RTS-style" unit movement mod, you could inject it into your own custom input processor:

```csharp
using Timberborn.BaseComponentSystem;
using Timberborn.InputSystem;
using Timberborn.CharacterControlSystemUI;
using UnityEngine;

public class RTSMovementController : BaseComponent, IInputProcessor
{
    private InputService _inputService;
    private CharacterControlDestinationPicker _destinationPicker;
    
    // Assume you track the currently selected beaver
    private ControllableCharacter _selectedBeaver;

    [Inject]
    public void InjectDependencies(InputService input, CharacterControlDestinationPicker picker)
    {
        _inputService = input;
        _destinationPicker = picker;
    }

    public bool ProcessInput()
    {
        // If the player right-clicks
        if (_inputService.IsKeyDown("SecondaryAction"))
        {
            if (_selectedBeaver != null)
            {
                // Find where they clicked
                Vector3? destination = _destinationPicker.PickDestination();
                if (destination.HasValue)
                {
                    // Order the beaver to move there
                    _selectedBeaver.TakeControlAndMoveTo(destination.Value);
                    return true; // Consume the input
                }
            }
        }
        return false;
    }
}
```

---

## Modding Insights & Limitations

* **Diagnostic Only**: As mentioned, the `CharacterControlSystemUIConfigurator` uses `builder.AddDiagnosticFragment(_characterControlFragment)`. This means the entire panel is hidden from standard players. It cannot be used as a gameplay feature without rewriting the configurator.
* **Cursor Hardcoding**: The fragment hardcodes `CursorKey = "PickDestinationCursor"`. If a modder creates a new cursor and wants to use it for character movement, they cannot easily inject it here.
* **Binding Describer Limitation**: The UI button appends the keyboard shortcut text using `_inputBindingDescriber.GetInputBindingText(CharacterControlPickCoordinatesKey)`. This requires the input key to be explicitly defined in the game's input settings config file, or the string will return a blank/error value.
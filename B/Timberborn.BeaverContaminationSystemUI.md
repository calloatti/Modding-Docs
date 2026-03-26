# Timberborn.BeaverContaminationSystemUI

## Overview
The `Timberborn.BeaverContaminationSystemUI` module acts as the presentation layer for the `Timberborn.BeaverContaminationSystem`. Its sole responsibility is to translate the internal state of a beaver's Badwater contamination incubation process into player-facing UI elements, specifically by utilizing the game's Status System to display floating icons and text above the affected character.

---

## Key Components

### 1. `BeaverContaminationSystemUIConfigurator`
This configurator uses `TemplateModule.Builder` to attach the `ContaminationIncubatorStatus` decorator to any entity that possesses a `ContaminationIncubator` component.

### 2. `ContaminationIncubatorStatus`
This is a small but critical component that bridges the logic simulation and the UI.
* **Status Registration**: During the `Start()` phase, it creates a `StatusToggle` and registers it with the entity's `StatusSubject`. This tells the game engine that this entity *can* display an incubation warning.
* **Event Listening**: It listens to the `IncubationStateChanged` event fired by the `ContaminationIncubator`.
* **Activation Logic**: If the beaver is currently incubating the disease (`IsIncubating`) or if the incubation period has just finished but the actual sickness hasn't fully applied yet (`IncubationFinished`), it calls `_statusToggle.Activate()`. This prompts the UI to show the "Incubating" icon and tooltip over the beaver's head. If neither condition is met, it deactivates the status.

---

## How to Use This in a Mod

### Creating Custom Statuses for Custom Conditions
If your mod introduces a new disease, buff, or state that requires a warning icon over a beaver's head, you should follow this exact pattern:

1.  **Create your Logic Component**: (e.g., `MyCustomDiseaseIncubator`) which fires an event when the state changes.
2.  **Create your UI Component**:
    ```csharp
    using Timberborn.BaseComponentSystem;
    using Timberborn.Localization;
    using Timberborn.StatusSystem;

    public class MyDiseaseStatus : BaseComponent, IAwakableComponent, IStartableComponent
    {
        private readonly ILoc _loc;
        private StatusToggle _statusToggle;
        private MyCustomDiseaseIncubator _diseaseLogic;

        public MyDiseaseStatus(ILoc loc) { _loc = loc; }

        public void Awake()
        {
            // Create the UI payload. You need a localization key for the full text and a short text (icon label).
            _statusToggle = StatusToggle.CreateNormalStatusWithAlert("MyDiseaseId", _loc.T("Status.MyDisease"), _loc.T("Status.MyDisease.Short"));
            
            _diseaseLogic = GetComponent<MyCustomDiseaseIncubator>();
            _diseaseLogic.StateChanged += OnStateChanged;
        }

        public void Start()
        {
            GetComponent<StatusSubject>().RegisterStatus(_statusToggle);
        }

        private void OnStateChanged(object sender, EventArgs e)
        {
            if (_diseaseLogic.IsSick) _statusToggle.Activate();
            else _statusToggle.Deactivate();
        }
    }
    ```
3.  **Decorate it**: Use a UI-specific configurator to attach `MyDiseaseStatus` to `MyCustomDiseaseIncubator` via a `TemplateModule.Builder`.

---

## Modding Insights & Limitations

* **Hardcoded UI Keys**: The localization keys used for the status tooltip (`"Status.BadwaterContamination.Incubation"`) and the short alert (`"Status.BadwaterContamination.Incubation.Short"`) are hardcoded as `private static readonly string`. Modders cannot change these keys without patching the code, though they can easily change the *text* those keys refer to by editing the localization `.csv` files.
* **Icon Resolution**: Notice that `StatusToggle.CreateNormalStatusWithAlert` does *not* explicitly ask for an image path. The string `"Incubation"` passed as the first argument is the Status ID. The `Timberborn.StatusSystem` automatically looks for a sprite asset in the `Sprites/Statuses/` folder that matches this ID (e.g., `Sprites/Statuses/Incubation`). Keep this naming convention in mind when creating custom statuses.
* **Separation of Concerns**: This module strictly separates logic (the actual timing of the incubation) from representation (drawing the icon). This is why it resides in a `...UI` namespace and is likely only bound in specific contexts (like the `Game` context), preventing headless servers or unit tests from accidentally trying to load UI sprites.
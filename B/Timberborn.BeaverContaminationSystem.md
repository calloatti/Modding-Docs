# Timberborn.BeaverContaminationSystem

## Overview
The `Timberborn.BeaverContaminationSystem` module implements the logic for Badwater contamination affecting beavers. It handles the exposure risk when beavers traverse polluted water, the "incubation" period before symptoms show, the actual transition into a contaminated state (which alters their needs and animations), and the tracking of infected populations for UI statistics.

For modders, this module illustrates how to inject state-altering conditions into characters, dynamically modify their active needs, and track specific demographic statistics across the settlement.

---

## Key Components

### 1. The Core State (`Contaminable` & `ContaminableAnimator`)
* **`Contaminable`**: This is the central component that determines if a beaver is currently sick. It does this by checking if the specific need `"BadwaterContamination"` is active. It fires a `ContaminationChanged` event whenever this state flips.
* **`ContaminableAnimator`**: Listens to the `Contaminable` state and toggles the `"Contaminated"` boolean parameter on the character's `CharacterAnimator`. This handles the visual change (e.g., the beaver turning green or walking differently).

### 2. Exposure & Timing (`ContaminationApplier` & `ContaminationIncubator`)
* **`ContaminationApplier`**: A tickable component that continuously checks if the beaver is swimming in contaminated water. If the `MinimumWaterContamination` (0.05f) is met, there is a probability (base 0.01f, scaled by pollution level) that the beaver will catch the illness. It respects `IWaterResistor` (like protective hazmat suits), ignoring exposure if the beaver is protected.
* **`ContaminationIncubator`**: Manages the delay between catching the illness and showing symptoms. By default, the `IncubationTimeInDays` is set to 3 days. It uses an `ITimeTrigger` to track progress and saves this progress to the save file. It also implements `IChildhoodInfluenced`, meaning if a child beaver grows up while incubating the disease, the adult beaver will inherit the exact incubation progress.

### 3. State Enforcement (`ContaminateRootBehavior` & `ContaminationNeedEnabler`)
* **`ContaminateRootBehavior`**: A behavior node that checks if the `ContaminationIncubator` has finished. If it has, it calls `Contaminable.Contaminate()`, applying the `"BadwaterContamination"` need effect (value `float.MinValue`) and resetting the incubator.
* **`ContaminationNeedEnabler`**: This is a critical component that dynamically rewires the beaver's needs when they get sick. When contaminated, it disables almost all non-critical needs (like socializing or fun) except for `"Shelter"`. Conversely, it enables the `"Antidote"` need exclusively when the beaver is contaminated.

### 4. Tracking and Statistics (`BeaverContaminationRegistry`)
* **`BeaverContaminationRegistry`**: An internal list manager that categorizes contaminated beavers into Adults and Children.
* **`DistrictBeaverContaminationStatisticsProvider`**: Attaches to a `DistrictCenter` to provide localized statistics of contaminated beavers assigned to that specific district.
* **`GlobalBeaverContaminationStatisticsProvider`**: A singleton that tracks contaminated beavers globally across the entire map, listening to `CharacterCreatedEvent` and `CharacterKilledEvent`.

---

## How to Use This in a Mod

### Creating Protective Gear or Traits
If you want to create a custom effect, building, or trait that makes a beaver immune to Badwater, you do not need to rewrite the contamination logic. You simply need to add a component to the beaver that implements `IWaterResistor` and returns `IsWaterResistant == true`. The `ContaminationApplier` will automatically ignore them.

### Forcing Contamination
If you are writing a mod that features a toxic gas trap or a spoiled food item, you can forcefully bypass the incubation period and immediately infect a beaver by accessing their `Contaminable` component:

```csharp
public void ForceInfectBeaver(BaseComponent beaver)
{
    var contaminable = beaver.GetComponent<Contaminable>();
    if (contaminable != null && !contaminable.IsContaminated)
    {
        contaminable.Contaminate();
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded Need IDs**: The system relies heavily on hardcoded string IDs for the Need System. `"BadwaterContamination"`, `"Shelter"`, and `"Antidote"` are explicitly named in the code. Modders cannot easily rename these specific needs in XML specs without breaking this C# logic.
* **Hardcoded Probabilities**: The `MinimumWaterContamination` (5%), `ContaminationProbability` (1%), and `IncubationTimeInDays` (3) are private static readonly fields. They cannot be altered via JSON configuration files; a modder would need to use Harmony transpilers to change the likelihood or speed of infection.
* **Need Disabling Logic**: The `ContaminationNeedEnabler` assumes that *any* need that does not have a `CriticalNeedSpec` (and is not Shelter) should be disabled when the beaver is sick. If you add a custom non-critical need to your mod that you want sick beavers to still care about, you will have to patch `IsDisabledWhenContaminated` to prevent it from being shut off.
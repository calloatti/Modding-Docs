# Timberborn.BonusSystemUI

## Overview
The `Timberborn.BonusSystemUI` module handles the user interface representation of the game's bonus and penalty mechanics. It serves two primary purposes: providing a developer-facing diagnostic panel to monitor active bonus multipliers, and injecting dynamically formatted text into player-facing tooltips to explain the penalties of unsatisfied needs.


---

## Key Components

### 1. `NeedPenaltyEffectDescriber`
This class implements the `INeedEffectDescriber` interface to dynamically generate the text shown in UI tooltips when a beaver is suffering from an unsatisfied need.
* **Penalty Extraction**: It extracts the `PunitiveNeedSpec` from the provided `NeedSpec`. If the `NeedManager` indicates the need is currently unfavorable (i.e., the penalty is active), it iterates through the `Penalties` array (`BonusSpec`).
* **Age-Specific Filtering**: It contains hardcoded logic to prevent confusing tooltips based on the character's age. It checks for the presence of the `Child` component on the entity. 
    * If the penalty applies to `"WorkingSpeed"`, it will only describe this penalty to the player if the entity is an Adult (lacks the `Child` component).
    * If the penalty applies to `"GrowthSpeed"`, it will only describe it if the entity is a `Child`.
* **Formatting**: It utilizes `BonusDescriber.DescribeColored()` to generate the final HTML-colored string, appending a `SpecialStrings.RowStarter` before adding it to the `StringBuilder`.

### 2. `BonusManagerDebugFragment`
A diagnostic UI tool that implements `IEntityPanelFragment`.
* **Data Visualization**: When active, it retrieves the `BonusManager` from the currently selected entity. It queries the `BonusTypeSpecService` for every registered `bonusId` in the game and fetches the current `Multiplier()` value for each, displaying them in a raw text list.

### 3. `BonusSystemUIConfigurator`
This configurator operates in the `Game` context.
* **Debug Binding**: It binds the `BonusManagerDebugFragment` as a singleton and injects it into the `EntityPanelModule` specifically as a diagnostic fragment using `builder.AddDiagnosticFragment()`.
* **Describer Binding**: It binds `NeedPenaltyEffectDescriber` and adds it to the game's collection of `INeedEffectDescriber` instances using `MultiBind`.

---

## How to Use This in a Mod

### Adding Custom Tooltip Describers
If your mod introduces a completely new way that needs affect beavers (e.g., a need that alters a beaver's physical size or changes their color), you can create your own describer to add custom text to the need tooltip.

1.  **Create the Describer**: Implement the `INeedEffectDescriber` interface.
```csharp
using System.Text;
using Timberborn.BaseComponentSystem;
using Timberborn.BonusSystemUI;
using Timberborn.NeedSpecs;
using Timberborn.NeedSystem;
using Timberborn.WellbeingUI;

public class MyCustomSizeEffectDescriber : INeedEffectDescriber
{
    public void DescribeNeedEffects(StringBuilder content, NeedManager needManager, NeedSpec needSpec)
    {
        // Only add text if this specific need is satisfied
        if (needManager.NeedIsFavorable(needSpec.Id) && needSpec.Id == "MyMod.GiantNeed")
        {
            content.AppendLine(" " + SpecialStrings.RowStarter + "<color=#00FF00>Makes the beaver 20% larger!</color>");
        }
    }
}
```

2.  **Bind the Describer**: Use `MultiBind` in your UI configurator so the game's tooltip system picks it up.
```csharp
using Bindito.Core;
using Timberborn.WellbeingUI;

[Context("Game")]
internal class MyCustomUIConfigurator : Configurator
{
    protected override void Configure()
    {
        MultiBind<INeedEffectDescriber>().To<MyCustomSizeEffectDescriber>().AsSingleton();
    }
}
```

---

## Modding Insights & Limitations

* **Hardcoded ID Filtering**: The `NeedPenaltyEffectDescriber` explicitly hardcodes `"WorkingSpeed"` and `"GrowthSpeed"` as `private static readonly string` fields to filter descriptions by age. If a modder creates a new custom penalty that should *only* apply to adults (e.g., `"CarryCapacity"`), this class will not filter it out automatically for children. The child beaver's tooltip will display the penalty, even if children cannot carry goods. Modders would need to write a custom `INeedEffectDescriber` to hide age-inappropriate custom penalties.
* **Strict Penalty Focus**: `NeedPenaltyEffectDescriber` explicitly returns early if `needManager.NeedIsFavorable(needSpec.Id)` evaluates to true. It is strictly designed to format *punitive* effects, leaving favorable need bonuses to be handled by a different describer class elsewhere in the game's codebase.
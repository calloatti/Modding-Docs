# Timberborn.DeteriorationSystemUI

## Overview
The `Timberborn.DeteriorationSystemUI` module provides the visual interface for monitoring the "durability" or "condition" of mechanical entities (such as Bots). It includes components for the main entity selection panel, the batch control list (to monitor multiple bots at once), and developer-only debug tools to force breakdown states.

---

## Key Components

### 1. Entity Panel Fragment (`DeteriorableFragment`)
This is the primary UI element displayed when a player selects a mechanical unit like a Golem.
* **Visual Progress**: It features a standard `ProgressBar` and a text label displaying the unit's remaining durability.
* **Formatting**: It retrieves the `DeteriorationProgress` float from the entity and converts it into a localized percentage (e.g., "Durability: 85%") using the `NumberFormatter`.
* **Placement**: It is injected as a **TopFragment**, ensuring it appears near the top of the selection panel for high visibility.

### 2. Batch Control Integration (`DeteriorableBatchControlRowItem`)
Used in the multi-unit list views (Batch Control), this component allows players to scan the condition of many units simultaneously.
* **Dynamic Row**: The `DeteriorableBatchControlRowItemFactory` creates a small row element containing only the percentage label for efficiency.
* **Tooltips**: It registers a localized tooltip (`Bot.Durability`) on the row so players can see the exact context of the number when hovering over it.

### 3. Debugging Tools (`DeteriorableDebugFragment`)
A specialized fragment used by developers and modders to test breakdown logic.
* **Instant Expiration**: Adds a diagnostic button labeled "Set durability to zero" to the entity panel.
* **Functionality**: Clicking this button immediately calls `SetDeteriorationToZero()` on the underlying `Deteriorable` component, triggering the mechanical death/breakdown sequence instantly.

---

## How to Use This in a Mod

### Customizing Durability Display
While the logic for deterioration resides in the core `DeteriorationSystem`, you can utilize the `DeteriorableFragment` logic if your mod adds a new mechanical faction.

If you want to add a custom status label to the fragment, you would need to implement a separate `IEntityPanelFragment`. However, if your modded entity simply uses the vanilla `DeteriorableSpec`, the percentage bar will appear automatically in the UI.

---

## Modding Insights & Limitations

* **Hardcoded Loc Key**: The system hardcodes the `DurabilityLocKey` as `"Bot.Durability"`. If a modder wanted to change this text for a specific building or unit (e.g., calling it "Structural Integrity"), they would need to create a custom fragment rather than reusing this one.
* **Diagnostic Availability**: The `DeteriorableDebugFragment` is registered as a **DiagnosticFragment**, meaning it will typically only be visible if the game's developer mode/debug mode is enabled.
* **Visual Dependencies**: The fragments rely on the standard `Game/EntityPanel/DeteriorableFragment` and `Game/BatchControl/DeteriorableBatchControlRowItem` UXML assets. Customizing the icon or layout requires overriding these visual tree paths.

---

## Related dlls
* **Timberborn.DeteriorationSystem**: The logic provider that supplies the `Deteriorable` component and current progress values.
* **Timberborn.EntityPanelSystem**: The framework into which the `DeteriorableFragment` is injected.
* **Timberborn.BatchControl**: The system that manages the multi-unit list view UI.
* **Timberborn.CoreUI**: Provides the `ProgressBar` and `VisualElementLoader` utilities.

Would you like to examine the **Timberborn.BatchControl** module next to see how these row items are organized into a large list?
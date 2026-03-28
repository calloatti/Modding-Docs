# Timberborn.Explosions

## Overview
The `Timberborn.Explosions` module handles the logic, visuals, and physics of destroying terrain and buildings using explosives. It supports simple shaped explosions (like basic Dynamite removing a column of terrain) and complex radial explosions (like the Badwater Rig "Unstable Core" destroying terrain and objects in a sphere). 

---

## Key Components

### 1. `Dynamite`
A basic explosive component that destroys terrain directly below it.
* **State & Triggering**: It can be triggered manually or delayed via `TriggerDelayed(int delayInTicks)`. It waits for `_ticksToDetonate` to pass before exploding.
* **Depth Calculation**: It calculates how deep it should blow up using `CalculateEffectiveDepth`. It stops early if it hits another object (like a building) rather than terrain.
* **Chain Reactions**: When it detonates, it calls `TriggerNeighbors()`, which looks at the 4 adjacent tiles and triggers any finished Dynamite or Unstable Cores found there.
* **Effects**: It lowers the terrain, deletes itself, deletes any path/road on its tile, kills characters on the tile, and instantiates its `ExplosionPrefabPath` visual effect.

### 2. `UnstableCore`
A complex explosive with a configurable radial blast area.
* **Adjustable Radius**: Its blast radius can be configured between `MinExplosionRadius` and `MaxExplosionRadius`.
* **Service Registration**: Instead of detonating itself instantly, it registers with the global `ExplosionService`.
* **Chain Reactions**: Like Dynamite, it listens to the global `TilesExplosion` event. If an adjacent tile explodes, the Core also explodes.

### 3. `ExplosionService`
A global `MapEditorTickable` singleton that processes radial explosions over time to prevent massive lag spikes.
* **Radius Processing**: When an `UnstableCore` explodes, it adds an `ExplosionData` object to the `_explosions` list. Every tick, it processes *one radius step* outward from the center.
* **Execution**: It gathers affected tiles, deletes the terrain, deletes all block objects (buildings/trees) on those tiles, kills characters, and spawns deconstruction particles.

### 4. `ExplosionOutcomeGatherer`
The math and physics engine behind radial explosions.
* **Volume Calculation**: Uses `GetCoordinatesInRadiusWithDistance` to find all `Vector3Int` grid tiles within the 3D sphere of the explosion.
* **Gravity & Collapse**: After destroying tiles, it calls `_terrainPhysicsService.GetTerrainAndBlockObjectStack` to find all terrain and buildings that were *above* the destroyed area and flags them for destruction as well, simulating a collapse.

### 5. `CharacterExploder` & `ExplosionVulnerable`
* **Vulnerability**: Characters (beavers/bots) decorated with `ExplosionVulnerable` will die instantly if caught in a blast, firing a `MortalDiedFromExplosionEvent`.
* **Gravity Adjustment**: If a character survives (e.g., they are invulnerable or falling), the `CharacterExploder` forcibly updates their `Transform.position.y` to the new `terrainHeightBelow`.

---

## How to Use This in a Mod

### Creating Custom Dynamite
To create a new explosive block (like a deeper excavator or a weaker bomb), you only need to create a prefab and attach a `DynamiteSpec`.

*Example JSON configuration:*
```json
"Dynamite": {
  "Depth": 2,
  "ExplosionPrefabPath": "Particles/DynamiteExplosion"
}
```

### Safely Deleting Terrain in Code
If you are writing a C# mod that destroys terrain, do not just call the terrain service directly if you want it to behave like an explosion (triggering neighbors and killing beavers). Instead, try to interface with the `ExplosionService` or replicate the steps found in `Dynamite.Detonate()`.

---

## Modding Insights & Limitations

* **Explosion Radius Performance**: `ExplosionService` processes radial blasts outward step-by-step per tick to maintain frame rate. However, excessively large radii (e.g., modifying `UnstableCoreSpec` to allow a radius of 50) will still cause significant lag due to the sheer volume of `BlockObject` deletion events firing simultaneously.
* **Map Editor Restrictions**: `UnstableCoreExplosionBlocker` prevents the Unstable Core from detonating while in the Map Editor. `Dynamite` does not have this restriction built into the component itself.
* **Tunnel Support**: The `Tunnel` component acts as an explosive that destroys itself and the terrain block *above* it when finished building. It requires a `TunnelSupportTemplateName` (the wooden frame left behind). To prevent illegal placements, `NoGroundOnlyBlockAboveValidator` ensures players can only place tunnels under terrain, not under floating buildings.

---

## Related DLLs
* **Timberborn.TerrainSystem**: Provides the `ITerrainService` to actually lower the ground heights.
* **Timberborn.TerrainPhysics**: Supplies `ITerrainPhysicsService` to calculate collapses when the ground is removed.
* **Timberborn.DeconstructionSystem**: Supplies `DeconstructionParticleFactory` to spawn the rubble visual effects when a radial explosion deletes objects.
* **Timberborn.MortalSystem**: Used by `ExplosionVulnerable` to instantly kill characters caught in the blast.
# Rivals Visuals Hub

Modern visuals client for RIVALS (Roblox) featuring customizable Aura ESP and game-hooked spiral bullet tracers.

---

## Loadstring

Run this in your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/18tibyrobin-arch/bvuzyfazaeaeaze/main/main.luau"))()
```

Or using the modular loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/18tibyrobin-arch/bvuzyfazaeaeaze/main/init.luau"))()
```

---

## Features

### ESP (Aura V5)
* **Aura** — Toggle aura effects on characters (Local, Allies, Enemies).
* **Through Walls** — Toggle highlight visibility through geometry (`AlwaysOnTop` vs `Occluded`).
* **Local Color** — Color picker for local player visuals (Default: Pure White `#FFFFFF`).
* **Ally Color** — Color picker for team members (Default: Emerald `#00FF78`).
* **Enemy Color** — Color picker for hostile players (Default: Purple `#AA28FF`).
* **Orb Orbit** — World-space continuous orbit with velocity-compensated trail smoothing.
* **Dual Torso Flames** — Outer and inner flame emitter layers with neon fist accents.
* **Angel Wings** — Dynamic geometry wings on local player with harmonic flapping.

### Bullet Tracers
* **Tracers** — Native hook directly to `TracerEffect.Play` for all real weapons fired in-game.
* **Duration** — Adjustable slider for beam lifetime and fadeout (0.1s – 2.0s).
* **Friendly Color** — Color picker for self and teammate bullet beams (Default: `#9628FF`).
* **Enemy Color** — Color picker for enemy shots (Default: `#FF3C3C`).
* **Spiral Trajectory** — Dynamic revolving neon orb and trail outlining projectile paths.

---

## Directory Structure

```text
├── Core/
│   ├── Config.luau        # Central configuration table
│   └── GameHook.luau      # FighterController and TracerEffect hooking
├── UI/
│   └── Interface.luau     # Rayfield GUI setup and reactive binds
├── Visuals/
│   ├── Aura.luau          # V5 Aura engine with world-space orbs & wings
│   └── Tracers.luau       # Game-hooked spiral tracer engine
├── init.luau              # Modular entry point
├── main.luau              # Self-contained release bundle
└── README.md
```

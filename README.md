# Rivals Visuals Hub

Ultra-lightweight visuals client for RIVALS (Roblox) featuring customizable Aura ESP and game-hooked spiral bullet tracers, powered by the high-performance **LinoriaLib** UI engine (zero blur, zero canvasgroup lag, pure FPS).

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

## Navigation & Controls

* **Toggle Menu**: Press `RightShift` or `RightControl`
* **Unload**: Click `Unload Hub` under the **Settings** tab to cleanly disconnect all hooks and remove visuals

---

## Features

### Aura ESP Tab
* **Aura** — Toggle aura effects on characters (Local, Allies, Enemies).
* **Through Walls** — Toggle highlight visibility through geometry (`AlwaysOnTop` vs `Occluded`).
* **Include Local Player** — Render aura on your own character.
* **Color Palette** — Instant in-place color pickers for Local, Ally, and Enemy players without lag.
* **Angel Wings** — Dynamic geometry wings on local player with harmonic flapping.
* **Customization** — Sliders for Orb Count (1-5) and Intensity multiplier (0.5x-2.5x).

### Bullet Tracers Tab
* **Bullet Tracers** — Native hook directly to `TracerEffect.Play` for real weapons fired in-game.
* **Duration** — Adjustable slider for beam lifetime and fadeout (0.1s – 2.0s).
* **Friendly Color** — Color picker for self and teammate bullet beams.
* **Enemy Color** — Separately configurable color picker for enemy shots.
* **Spiral Physics** — Sliders for Spiral Speed (200-800 studs/s) and Spiral Radius (0.1-0.8 studs).
* **Click Fallback Raycast** — Optional mouse click raycast fallback.

### Settings Tab
* **Menu Settings** — Unload Hub and diagnostics.

---

## Directory Structure

```text
├── Core/
│   ├── Config.luau        # Central configuration table
│   └── GameHook.luau      # FighterController and TracerEffect hooking
├── UI/
│   └── Interface.luau     # LinoriaLib high-performance UI
├── Visuals/
│   ├── Aura.luau          # V5 Aura engine with world-space orbs & wings
│   └── Tracers.luau       # Game-hooked spiral tracer engine
├── init.luau              # Modular entry point
├── main.luau              # Self-contained release bundle
└── README.md
```

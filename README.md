# Rivals Visuals Hub

Ultra-lightweight visuals client for RIVALS (Roblox) featuring complete 2D/3D ESP and game-hooked spiral bullet tracers, powered by **LinoriaLib** (zero blur, zero canvasgroup lag, pure FPS).

---

## Loadstring

Run this in your executor (menu is hidden by default, press `RightShift` to open):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/18tibyrobin-arch/bvuzyfazaeaeaze/main/main.luau"))()
```

Or using the modular loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/18tibyrobin-arch/bvuzyfazaeaeaze/main/init.luau"))()
```

---

## Navigation & Controls

* **Toggle Menu**: Press `RightShift` or `RightControl` (Menu is hidden upon initialization)
* **Custom Themes**: Select between 5 built-in themes under the **Settings** tab:
  * `Default Dark` (Classic blue accent on charcoal)
  * `Blood Crimson` (Vivid red accent)
  * `Toxic Emerald` (Neon green accent)
  * `Cyberpunk Violet` (Vibrant purple accent)
  * `Midnight Sapphire` (Electric cyan accent)
* **Watermark**: Toggle watermark visibility under the **Settings** tab

---

## Features

### ESP Tab
* **2D Overlay ESP (Left Column)**:
  * **Box ESP** — 2D bounding boxes with attached color picker.
  * **Skeleton ESP** — Real-time bone lines connecting joints with attached color picker.
  * **Name ESP** — Display player name with attached color picker.
  * **Health Bar** — Dynamic health-colored bar on box side.
  * **Distance ESP** — Distance readout in studs with attached color picker.
  * **Weapon & Ammo** — Current equipped tool/weapon and ammo counter with attached color picker.
* **3D World ESP (Right Column)**:
  * **Chams** — Body highlight chams with attached color picker.
  * **Chams Through Walls** — Toggle chams visibility through geometry.
  * **Aura** — Orbital orbs and dual flames aura with enemy color picker.
  * **Aura Through Walls** — Toggle aura highlight through walls.
  * **Include Local Player** — Render visuals on self.
  * **Ally Color** — Color picker for teammates.
  * **Local Color** — Color picker for local player.

### Bullet Tracers Tab
* **Bullet Tracers (Left Column)**:
  * **Tracers** — Hook real weapon gunshots via client `TracerEffect`.
  * **Duration** — Adjustable slider for beam lifetime (0.1s – 2.0s).
* **Tracer Colors (Right Column)**:
  * **Friendly Color** — Color picker for local and teammate shots.
  * **Enemy Color** — Separately configurable color picker for enemy shots.

### Settings Tab
* **Menu Keybind** — Configure keybind to open/close menu.
* **UI Theme** — Dropdown of 5 custom themes with real-time palette updates.
* **Show Watermark** — Toggle screen watermark display.

---

## Directory Structure

```text
├── Core/
│   ├── Config.luau        # Central configuration table
│   └── GameHook.luau      # FighterController and TracerEffect hooking
├── UI/
│   └── Interface.luau     # LinoriaLib UI setup with 5 themes
├── Visuals/
│   ├── Aura.luau          # V5 Aura engine with world-space orbs & dual flames
│   ├── Chams.luau         # Body highlight chams engine
│   ├── ESP2D.luau         # 2D Box, Skeleton, Name, Health, Distance, Weapon
│   └── Tracers.luau       # Game-hooked spiral tracer engine
├── init.luau              # Modular entry point
├── main.luau              # Self-contained release bundle
└── README.md
```

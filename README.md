# Rivals Visuals Hub

Ultra-lightweight visuals and customization client for RIVALS (Roblox) featuring complete 2D/3D ESP, game-hooked spiral bullet tracers, and client-side **Skin Changer** (Weapons, Skins, Wraps, Finishers), powered by **LinoriaLib** (zero blur, zero canvasgroup lag, pure FPS).

---

## Loadstring

Run this in your executor (menu is hidden by default, press `RightShift` or `Insert` to open):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/18tibyrobin-arch/bvuzyfazaeaeaze/main/main.luau?t=" .. os.time()))()
```

Or using the modular loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/18tibyrobin-arch/bvuzyfazaeaeaze/main/init.luau?t=" .. os.time()))()
```

---

## Navigation & Controls

* **Toggle Menu**: Press `RightShift`, `RightControl`, or `Insert` (Menu is hidden upon initialization)
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
  * **Skeleton ESP** — Real-time bone lines connecting joints (R15 & R6) with attached color picker.
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

### Skin Changer Tab
* **Weapon & Skin (Left Column)**:
  * **Select Weapon** — Choose from 54 supported weapons (Assault Rifle, Sniper, Shotgun, Handgun, Flare Gun, Knife, Katana, RPG, etc.).
  * **Select Skin** — Dynamically lists all catalog skins for the chosen weapon (AK-47, 10B Visits, Chancla, Compound Bow, etc.).
  * **Apply Skin** — Instantly applies the selected skin model.
  * **Apply All (Skin, Wrap & Finisher)** — One-click full loadout customization.
  * **Auto-Apply on Weapon Equip** — Automatically applies chosen cosmetics when switching weapons.
* **Wrap & Finisher (Right Column)**:
  * **Select Wrap** — Select from 388 weapon wraps (1B Visits, Brimstone, Glacier, Danger, Pine, Sensite, etc.).
  * **Select Finisher** — Select from 125 unique death finishers (Orbital Strike, Disintegrate, BONK!, Electrocute, Ascend, etc.).
  * **Apply Wrap & Finisher** — Applies the wrap texture to viewmodel and sets the elimination finisher.

### Settings Tab
* **Menu Keybind** — Configure keybind to open/close menu.
* **UI Theme** — Dropdown of 5 custom themes with real-time palette updates.
* **Show Watermark** — Toggle screen watermark display.

---

## Directory Structure

```text
├── Core/
│   ├── Config.luau        # Central configuration table
│   ├── GameHook.luau      # FighterController and TracerEffect hooking
│   └── SkinData.luau      # Catalog database for weapons, skins, wraps, finishers
├── UI/
│   └── Interface.luau     # LinoriaLib UI setup with 4 tabs & 5 themes
├── Visuals/
│   ├── Aura.luau          # V5 Aura engine with world-space orbs & dual flames
│   ├── Chams.luau         # Body highlight chams engine
│   ├── ESP2D.luau         # 2D Box, Skeleton, Name, Health, Distance, Weapon
│   ├── SkinChanger.luau   # Real-time client skin, wrap, and finisher engine
│   └── Tracers.luau       # Game-hooked spiral tracer engine
├── init.luau              # Modular entry point
├── main.luau              # Self-contained release bundle
└── README.md
```

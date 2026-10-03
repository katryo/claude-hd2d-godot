# Lumen Hollow — an HD-2D RPG in Godot 4

A small, complete RPG in the **HD-2D** style (as in *Octopath Traveler* and *Triangle Strategy*):
pixel-art sprites live in a lit, low-poly 3D diorama, with real-time shadows, bloom,
SSAO, fog and tilt-shift depth of field.

Every texture and sprite is **generated procedurally at runtime** (see `scripts/gfx/`),
so the repository contains no binary art assets.

| Exploration | Village | Break & Boost battle |
|---|---|---|
| ![field](docs/screenshots/field.png) | ![village](docs/screenshots/village.png) | ![battle](docs/screenshots/battle.png) |

## Running

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build; no C#/.NET needed).
2. Open `project.godot` in the editor and press **F5**, or run `godot --path .`.

The project uses the **Forward+** renderer for depth of field, SSAO and glow.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD / Arrow keys | D-pad / left stick |
| Run | Shift | X |
| Talk / Confirm | Z / Enter / Space | A |
| Cancel | X / Esc / Backspace | B |
| Status menu | Tab / C | Start |
| Boost + / − (battle) | E / Q (PageUp / PageDown) | RB / LB |

## Gameplay

- **Explore Lumen Hollow:** a village, a river with a bridge, the Whispering Meadow and the
  Old Shrine. Talk to villagers, open chests, rest at the inn and buy curatives.
- **Random encounters** happen in the tall grass. Stick to the paths to avoid them.
- **Turn-based battles** with a party of three (Aren the swordsman, Lyra the mage and Kit the hunter):
  - **Break:** every enemy has a shield. Hitting a weakness (sword, bow, staff, fire, ice,
    thunder or light) removes one point and reveals that weakness. At zero the enemy **BREAKS**:
    it loses its next turn and takes double damage.
  - **Boost:** each party member banks a Boost Point (BP) per round, up to 5. Spend up to 3 on an
    action for extra attack hits or much stronger skills.
- **Goal:** defeat the King Slime in the Old Shrine to the north. It acts twice per turn below half HP.

## How the HD-2D look is built

| Ingredient | Where |
|---|---|
| Tilted, narrow-FOV follow camera | `scripts/world/follow_camera.gd` |
| Near/far depth of field (tilt-shift), bloom, SSAO, fog, color grading | `scripts/gfx/visuals.gd` |
| Y-axis billboard sprites that cast shadows, with wind sway | `shaders/billboard_sway.gdshader` |
| Block terrain with textured cliff faces, timber houses, props | `scripts/world/world_builder.gd` |
| Pixel-art water with sparkles that catch the bloom | `shaders/water.gdshader` |
| Flickering lamps, glowing windows, chimney smoke, floating motes | `world_builder.gd`, `visuals.gd` |
| Procedural pixel art (characters, monsters, trees, tiles) | `scripts/gfx/sprite_factory.gd`, `texture_factory.gd` |

## Project layout

```
scenes/main.tscn            Entry scene (game flow lives in scripts/main.gd)
scripts/
  main.gd                   Title screen, field <-> battle transitions, dev flags
  autoload/game.gd          Party, inventory, gold, story flags, input map ("Game" autoload)
  world/                    Map data (ASCII), world builder, field, player, NPCs, camera
  battle/                   Combatant stats, game data, battle logic, battle HUD
  gfx/                      Pixel canvas, sprite and texture generators, lighting presets
  ui/                       Theme, dialogue box, list menus, banners
shaders/                    Billboard, water, vignette and transition shaders
tests/                      Headless smoke test and screenshot capture scripts
```

The overworld is authored as ASCII in `scripts/world/map_data.gd`. Edit the grid to reshape
the world: rectangles of `h` become houses, `d` puts a door on the house above it, and so on
(the legend is at the top of the file).

## Developer flags and tests

Pass these after `--`:

```sh
godot --path . -- --skip-title            # start exploring immediately
godot --path . -- --battle                # jump into a random battle
godot --path . -- --boss --autobattle     # watch the party fight the boss on its own
godot --path . -- --at=20,8               # start on a given map cell (x, row)
godot --path . -- --skip-title --shot=out.png --shot-delay=4   # save a screenshot, then quit
```

Headless smoke test. It drives exploration, dialogue, the shop, the inn, chests, the status menu,
encounters and a boss fight through real input events:

```sh
godot --headless --path . --fixed-fps 30 -s tests/smoke_test.gd
```

`tests/capture.gd` renders showcase screenshots. It needs a GPU, or `xvfb-run` with Mesa's lavapipe.

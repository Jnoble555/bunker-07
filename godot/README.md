# Bunker 07 — Godot campaign preview

**Three-mission campaign implementation is in progress on the migration branch.** Start Campaign now begins Breach, continues through Control Room, and ends with Blackout. See the [current checkpoint and outstanding validation](../docs/godot/campaign-checkpoint.md) before merging. The browser reference remains at [the hosted game](https://jnoble555.github.io/bunker-07/) and at `../index.html` locally. No browser game source or tests were replaced.

Import `project.godot`, press F5, then choose **Start Campaign** and **Deploy**. J opens the journal; settings are available at title and pause. CSV exports to the native user-data folder and displays its saved path. The remaining sections below document the historical M1 launch conventions; feature-availability statements from that milestone are superseded by the current checkpoint.

Tested with **Godot 4.7.2 stable** and GDScript, using the Compatibility renderer. No plugins, downloaded assets or .NET runtime are needed. All native meshes, materials, textures and lighting are original procedural project source; Godot's built-in UI font is used.

## Launch

In Godot's Project Manager choose **Import**, select this folder's `project.godot`, open it and press **F6** for the main scene or **F5** for the project. Choose **Deploy to Control Room**. Importing may create an ignored `.godot/` cache.

From the repository root in PowerShell, using the installation found on this computer:

```powershell
$godotBin = 'C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotBin --version
& $godotBin --path .\godot
```

On another machine, substitute the path to its stable Godot executable. To open the editor, add `--editor`.

## Controls and included behavior

| Input | Action |
| --- | --- |
| WASD / Up, Down | Move at the browser's speed, with normalized diagonal movement |
| Mouse / Left, Right | Yaw-only aiming, matching the reference |
| Click / Space | Fire (8 rounds, .24-second cooldown) |
| R | Reload over .8 seconds; cannot fire while reloading |
| E | Disable/silence the alarm panel within .85 tile (1.7m) |
| Esc / P | Pause/resume; timed actions freeze |
| F5 | Retry the section (also available from the menu) |

Take the maintenance route to the panel, or risk the direct hall's armored patrol. The guard detects visible players in its forward cone, then chases after the alarm. It takes three hits, staggers briefly on impact, and winds up before dealing damage; move away or break sight to cancel the attack. Acquire the core after panel shutdown or alarm activation, then follow the opened gate to extraction. Surviving enemies do not block extraction.

The alarm is represented, but **no camera or reinforcement is implemented yet**. Results summarize this section only. There are no campaign consequence commits, ranks, optional finds, journal, settings, onboarding or CSV export in M1. The complete remaining scope is in the [parity checklist](../docs/godot/parity.md).

## Validation

From the repository root:

```powershell
& $godotBin --headless --path .\godot --editor --import --quit
& $godotBin --headless --path .\godot --script res://tests/milestone_test.gd
& $godotBin --path .\godot --script res://tests/visual_smoke.gd
```

The first command validates project imports; inspect its output for script errors as well as its exit code. The second runs deterministic native physics checks and writes `tests/milestone-results.json`. The third opens a short graphical run, dispatches a real Godot Space-key event, captures native screenshots into `../docs/godot/screenshots/`, and exits. It needs a working graphical renderer.

`npm test` at the repository root still runs the independent browser reference suite. Its results do not prove native parity. See the [verification record](../docs/godot/verification.md) and [independent review](../docs/godot/review.md) for actual executed checks and limitations.

## Layout and conventions

- `scenes/control_room.tscn`: main scene; runtime children are built by scripts.
- `scripts/main.gd`: session, input actions, weapon queries, objectives and UI.
- `scripts/player.gd`: CharacterBody3D movement, Camera3D and viewmodel.
- `scripts/armored_guard.gd`: representative enemy behavior and original mesh model.
- `scripts/room.gd`: map, world collision, gate, panel, materials and lights.
- `tests/`: native physics tests and graphical smoke capture.

One browser tile is two meters; browser `(x,y)` becomes Godot `(2x,0,2y)`. Collision bits are world 1, player 2, enemy 4, interaction reserved 8. The shared interfaces and ownership decisions were documented before independent implementation in [parity.md](../docs/godot/parity.md).

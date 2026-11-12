# Bunker 07 — native campaign preview

The Godot version now includes **Breach → Control Room → Blackout**, with reactive security, tactical devices, optional objectives, campaign consequences and results. It remains a native preview rather than a claim of identical audiovisual output or cross-platform certification. The unchanged [browser game](https://jnoble555.github.io/bunker-07/) is the behavioral reference.

## Launch

Tested with **Godot 4.7.2 stable**, GDScript and the Compatibility renderer. In Godot Project Manager, choose **Import**, select `project.godot`, open it, press **F5**, then choose **Start Campaign** and **Deploy**. The project retains its original internal application name so existing local preference/user-data paths stay stable.

From the repository root in PowerShell:

```powershell
$godotBin = 'C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotBin --path .\godot
```

Replace the executable path on another machine; add `--editor` to open the editor. No plugins, .NET runtime or downloaded art/audio are needed.

| Input | Action |
| --- | --- |
| WASD / Up, Down | Move |
| Mouse / Left, Right | Full mouse look / keyboard yaw |
| Ctrl (hold) | Crouch; standing requires headroom |
| Shift (hold) | Sprint |
| Q / C (hold) | Lean left / right, constrained by obstacles |
| Right mouse (hold) | Aim with reduced FOV and speed |
| Click / Space | Fire |
| R | Reload from finite reserve |
| 1 / 2 | Owned pistol / SMG |
| E | Use nearby panel/device or collect weapon/ammo |
| J | Open paused field journal |
| P / Esc | Pause/resume; return from submenus |
| F5 | Retry current mission |

Settings at title/pause save volume, mute and sensitivity locally. First-time Breach prompts teach movement, aim, fire and reload. Pause freezes timed actions, AI, tracking and effects. Returning to title during a run requires confirmation.

## Campaign

- **Breach:** disable the fast scout and reach Control Sector.
- **Control Room:** avoid or confront the armored patrol and camera, disable the alarm panel or risk detection, collect the core and extract. Shootable fixtures, service-power isolation, the bulkhead, a one-use overload and a hidden medical cache are available. Optional archive intel risks an alarm unless the panel is disabled.
- **Blackout:** restore southwest backup power, then reach extraction. A successful quiet Control Room shutdown disables its turret; a successful alarm route adds an armored pursuer. Failed attempts do not commit provisional decisions or rewards.

Results show active time, accuracy, rank and retries; the final summary lists all three missions. Journal entries from successful missions carry forward. New Campaign resets campaign decisions/results while retaining session analytics. Closing the game ends that session; only preferences/onboarding persist.

**Export session CSV** writes `user://bunker-07-session.csv` and displays the full local path. It uses the browser schema, including mission IDs and target/detail columns. Native file export replaces the browser download UI.

## Source layout

- `scripts/campaign_main.gd`: campaign integration and menus; extends the retained `main.gd` M1 shell.
- `scripts/mission_data.gd`: reference maps, spawns and objective positions.
- `scripts/campaign_state.gd`: successful commits, ranks, journal, preferences and CSV.
- `scripts/encounter_systems.gd`: camera, devices, optional rewards and investigation state.
- `scripts/armored_guard.gd`: scout/armored/turret roles, windup/stagger and investigation navigation.
- `scripts/room.gd`, `player.gd`, `native_audio.gd`: original 3D world, player/weapon and finite synthesized spatial sounds. `scenes/industrial_console.tscn` and its script provide the visual-only Control Room alarm console; its procedural mesh and material source is original project code, with no external assets or license dependencies.

One browser tile is two meters: `(x,y)` becomes native `(2x,0,2y)`. Physics bits are world 1, player 2, enemy 4 and shootable devices 8. All assets are original procedural geometry/materials/audio, with Godot's built-in font.

## Validation

```powershell
& $godotBin --headless --path .\godot --editor --import --quit
& $godotBin --headless --path .\godot --script res://tests/milestone_test.gd
& $godotBin --headless --path .\godot --script res://tests/campaign_test.gd
& $godotBin --headless --path .\godot --verbose --script res://tests/close_smoke.gd
& $godotBin --path .\godot --script res://tests/campaign_visual.gd
```

The last command opens a short graphical run and captures all mission/settings/journal/summary views. Tests run real physics and scripted input; they do not replace a full human campaign playthrough. `npm test` still runs the browser regression suite separately.

See [current parity](../docs/godot/parity.md), [release verification and screenshots](../docs/godot/campaign-release.md), and [independent review](../docs/godot/campaign-review.md). Earlier M1 verification/checkpoint documents are historical records.

## Tactical movement lab

The native movement milestone deliberately expands the browser reference with grounded ramps/stairs, vertical look, crouch, sprint, lean and aiming. Open scenes/movement_lab.tscn in Godot and press F6, or run:
```powershell
& $godotBin --path .\godot res://scenes/movement_lab.tscn
```
The separate lab has low cover ahead, a headroom bay on the left, and a ramp/stairs on the right. F5 resets it. It cannot commit campaign extraction progress. Campaign launch remains F5 from the main project (Start Campaign, Deploy).
See [movement verification](../docs/godot/tactical-movement.md).

## Two-weapon inventory

Each mission and retry starts with the pistol (8 loaded, 40 reserve) and restores its optional SMG and one ammunition supply. Inventory does not carry between missions. E collects; 1/2 selects owned weapons. Switching cancels a reload without transferring ammunition; only a completed reload moves missing rounds from reserve into the magazine. The SMG is automatic; the pistol fires once per press.

See [weapon inventory rules, assets and verification](../docs/godot/weapon-inventory.md).

## Deep Signal tactical operation

Press F5, choose **Deep Signal / Tactical Operation**, then Deploy. The original **Start Campaign** remains available. Restore security access, recover the elevated archive and extract. Slot 3 equips the optional armory shotgun. No checkpoint saving is included. See [playtest handoff, actual tests, screenshots and remaining work](../docs/godot/tactical-pve-expansion.md).

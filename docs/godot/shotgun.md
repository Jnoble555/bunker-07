# Security shotgun component

Original shotgun source/export and independently testable pellet queries for the tactical PvE operation. Main integration owns slot 3, weapon state, pickups, reserve transfer, audio dispatch, damage application, events and HUD.

## Definition and tradeoffs

shotgun_definition.gd exposes DATA:
- 4-round detachable magazine, 12 initial reserve.
- Semi-automatic, 0.85 s cadence, 1.7 s magazine reload.
- 8 pellets, nominal damage 1 per damaging pellet.
- 26 m ray range, spread 0.10 directional offset.
- Full damaging pellet count through 8 m; damaging pellet count decreases between 8 and 18 m; zero damage at or beyond 18 m.
- Stronger recoil value 2.0, original low PCM firing sound.
- Optional supply grant 8 shells.

The wide disk pattern causes fewer pellets to strike small distant targets. Integer enemy HP is retained: deterministic pellet-index attenuation sheds damaging pellets with distance instead of introducing fractional HP or random damage. Each pellet independently resolves its nearest world/device/enemy surface.

## Shared query contract

shotgun_ballistics.gd:
- cast(world,origin,basis,exclude,definition,spread_multiplier=1.0) returns exactly the defined pellet count, clamped to 1..32.
- Every entry contains hit, pellet_index, direction, distance and damage.
- Collision hits also retain Godot's collider, position, normal and other raw ray-result fields. Misses have no collider key.
- Each ray uses layers world 1, enemy 4 and shootable device 8; area collisions and inside-origin hits are enabled.
- Exclusions apply independently to every pellet.
- For definitions without pellets, one ray is returned. Zero spread preserves exact camera direction; single-pellet spread preserves the SMG's square jitter.
- pellet_damage(distance,definition) returns the base integer damage with range cutoff. cast additionally applies deterministic indexed distance attenuation; integration must use each entry's damage.
- The helper never changes health, ammunition, pickups, events or accuracy.

Accuracy must count at most one successful hit per trigger/blast. A damage-zero impact is not a successful hit. Integration retains the existing behind-camera check for inside-origin overlapping hit areas. Enemy/device damage is applied by the controller, after the nearest-surface query; collision occlusion is not bypassed by pellet aggregation.

## Assets and source

Original Blender meshes/materials live in assets/source/security-shotgun; runtime GLB is under godot/assets/weapons. Source/export includes named Slide, Magazine and MagazineBase parts for the existing cached presentation wrapper. The shotgun has a longer cylindrical barrel, separate lower tube, ribbed fore-end, detachable magazine, stock and restrained amber markings. No external art or audio were downloaded.

The isolated [asset preview](campaign-screenshots/shotgun-asset.png) was rendered with neutral lighting in Godot. It is an asset inspection, not an integrated operation screenshot.

## Actual component verification

Installed Godot 4.7.2 stable / Windows Compatibility:
- Editor import completed; inspected log had no script/import errors.
- Headless shotgun_test.gd: 14/14.
- Graphical shotgun_test.gd: 15/15, including successful asset-preview capture; image inspected.
- Tests cover close full pellet damage, reduced medium damage, zero far damage, out-of-range misses, full and partial cover per-pellet occlusion, explicit exclusions, exact single-pellet direction, inside-origin metadata, shooter exclusion, device areas, invalid distance rejection and imported animation nodes.

Commands from the repo root:
```powershell
$godotBin = 'C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
& $godotBin --headless --path godot --script res://tests/shotgun_test.gd
& $godotBin --path godot --script res://tests/shotgun_test.gd
```

Integrated blast accuracy, inventory/switch/pause behavior, pickup supply balance and operation progression require the integration suite and final graphical run. Human firing feel, subjective sound/recoil and other hardware remain manual checks.

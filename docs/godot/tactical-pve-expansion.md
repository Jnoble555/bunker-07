# Deep Signal tactical PvE playtest

Branch: `feature/tactical-pve-expansion`, based on main `a6cd31c`.

## Launch

Open `godot/project.godot` in Godot 4.6.3 or newer, press F5, choose **Deep Signal / Tactical Operation**, read the briefing, then **Deploy**. CLI from the repository root: `godot --path godot`. The original campaign remains under **Start Campaign**. Browser gameplay is unchanged. No exported executable is included.

WASD movement; mouse look; Ctrl crouch; Shift sprint; Q/C collision-aware lean; RMB aiming zoom; E collect/use; 1 pistol, 2 SMG, 3 shotgun; click/Space fire; R reload; J journal; Esc/P pause; F5 retry. Aiming remains zoom, not sight alignment. Each retry resets the entire operation; there is no checkpoint save/resume.

## Operation and contracts

A 50m-square original industrial layout has entry/security, west maintenance, central relay, optional southeast armory, elevated northeast operations, and an extraction lift. Wide doors connect sectors and support alternate approaches. Three principal encounter arrangements are the security lane, relay/maintenance crossfire, and operations ramp/deck; the armory adds optional risk. Cyan floor markings lead through maintenance and up the ramp. Objective HUD shows the current task, distance, and E guidance when usable.

Restore access at the amber SECURITY terminal, recover the OPERATIONS archive upstairs, then enter the northeast extraction lift. Data cannot be collected before access restoration; remaining enemies do not gate extraction. Maintenance supplies and armory medical/ammo boxes are one-use and reset on retry. Inventory is operation-scoped, preserving the campaign's existing rules. Supplies add +24 pistol / +48 SMG / +8 shotgun reserve only for weapons owned at collection. The pistol's starting 48 rounds exceeds the eight enemies' total 39 HP; the collectible SMG adds 96 rounds, the shotgun 20 shells, and five supplies add reserves. This arithmetic establishes sufficient finite supply, not a guarantee of player accuracy or combat balance.

`tactical_operation_data.gd` owns mission/spawn/pickup data. `tactical_operation_room.gd` owns authored room geometry, cover, and AStar3D navigation. World/prop solids share collision layer 1. The navigation grid uses those same authored solid bounds expanded for capsule clearance, with explicit elevation heights; no engine navmesh baking is required. The operations ramp rises 1.2m over 6m. All enemy spawns connect to the graph; scripted player and enemy traversal validate the ramp.

`tactical_enemy.gd` owns the operation-only actor; `tactical_enemy_visual.gd` owns replaceable original primitive models and visible weapons. The original campaign continues using `armored_guard.gd`. Mobile SMG units prefer 7.5m; slower rifle units prefer 13m and reachable cover. States: patrol, suspicious/investigate, engage, search, reload. Enemies use actual player eye visibility, 0.65s initial reaction, burst windup, finite magazines (15 SMG / 9 rifle), reloads, limited shot hearing and nearby ally information, and remembered positions after sight loss. Firing checks both eye and muzzle visibility against world geometry and allies. Cover is selected from authored reachable points; player hits mark the previous position compromised. Separation, actor collision and sideways yielding reduce doorway stacking. These are simplified tactical heuristics, not squad planning or a guarantee against every crowd deadlock.

Enemy shots are simplified hitscan: two of each three fired rounds cause damage when visible (5 SMG / 8 rifle). No enemy ballistic projectiles or finite reserve pools. Amber attack warnings allow breaking sight; ranged balance needs human playtesting. Visors turn red during actual attack windup. Enemy guns face the target when firing, including during movement.

## Shotgun

Collect in the armory; select slot 3. Four-shell magazine, 16 initial reserve, 0.9s cadence, 2.2s complete-magazine reload, eight independently occluded pellets, 18m cutoff and wide spread (halved while aiming). Each pellet deals one damage; distance naturally reduces pellet concentration. Switching cancels a reload with no ammunition transfer; only completion transfers missing shells from reserve. It has original reproducible Blender source/export, distinct sound, and timing-driven presentation. The reload is stylized, not per-shell loading.

Analytics retains the existing CSV schema. One shotgun blast consumes one shell and counts as **one shot and at most one hit**, regardless of pellets/targets hit; accuracy cannot exceed 100%. Damage/death callbacks see the successful blast hit before recording their events. Weapon slot input now passes through the actual campaign input handler, fixing a pre-existing omission of slots 1/2.

## Executed validation

Linux Godot **4.6.3**, Blender **4.3.2**, Compatibility renderer. Earlier Windows/4.7.2 reports elsewhere are historical. `tactical-pve-results.json` records this pass separately.

| Check | Actual result |
| --- | --- |
| Editor import / parser | No script/import errors in inspected output |
| Existing native milestone | 46/46 |
| Existing three-mission campaign | 51/51 |
| Existing tactical movement, headless | 17/17, captured-mouse check explicitly skipped |
| Existing inventory | 16/16 |
| Tactical armed enemy | 14/14, including two independent review regressions |
| Integrated tactical operation | 28/28 headless |
| Integrated operation graphical suite | 26/26 before adding two additional headless navigation assertions |
| Final graphical composition smoke | 7 captures, no script errors; Mesa llvmpipe Compatibility |

Integrated assertions exercise real collision-driven direct/maintenance traversal, ramp ascent, complete objective extraction, all enemy graph connections, an enemy physically navigating up the ramp, objective sequencing/duplicates, optional armory acquisition, actual slot-3 input handler, multiple shotgun pellets with blast-level accuracy, solid occlusion, range, interrupted reload, pause, death/retry and campaign restart. Enemy tests exercise perception/reaction, lost-sight memory, world occlusion, burst magazines/reload, memory expiry, search arrival, facing and reset. Route tests freeze combat actors to isolate traversal; they are not human campaign completion.

Native checks, from the repository root:

```
godot --headless --editor --path godot --import
godot --headless --path godot --script res://tests/milestone_test.gd
godot --headless --path godot --script res://tests/campaign_test.gd
godot --headless --path godot --script res://tests/tactical_movement_test.gd
godot --headless --path godot --script res://tests/inventory_test.gd
godot --headless --path godot --script res://tests/tactical_enemy_test.gd
godot --headless --path godot --script res://tests/tactical_operation_test.gd
godot --path godot --script res://tests/tactical_visual.gd
```

The two new headless suites also pass with `--fixed-fps 60` for fast deterministic simulation. A graphical operation suite ran with real rendering and normal timing. On this cloud host, writable XDG data/config/cache directories were needed. Graphical runs use a dummy audio driver because no audio device is attached; audible mix was not verified.

## Independent review

One implementation delegate authored the separate enemy module. One independent reviewer ran afterward, with no parallel implementation team. The integration owner handled the level, shotgun, shared integration and fixes. Review found remembered-eye height preventing local search arrival, and movement facing overriding attack aim. Both are fixed and covered by two focused assertions. Existing regression tests also caught overlapping-enemy shots behind the camera; the original rule is restored for both hit areas and bodies. No old test assertion was weakened.

## Screenshots

Scripted views of the final integrated build; these are not human playthrough evidence. The result screen came from scripted traversal with enemies frozen.

- [Title](tactical-screenshots/title.png)
- [Entry / maintenance approach](tactical-screenshots/entry.png)
- [Security](tactical-screenshots/security.png)
- [Usable ramp](tactical-screenshots/ramp.png)
- [Elevated operations](tactical-screenshots/operations.png)
- [Shotgun](tactical-screenshots/shotgun.png)
- [Armed unit](tactical-screenshots/armed-unit.png)
- [Scripted extraction result](tactical-screenshots/result.png)

## Remaining work, in order

1. Human playtest from title through extraction. Measure first-play duration against the 10–15 minute design goal; adjust enemy placements in `tactical_operation_data.gd`, cover in `tactical_operation_room.gd`, and damage/cadence in `tactical_enemy.gd`. The duration and overall encounter balance are **unverified**.
2. Stress multiple enemies converging on doors and cover, especially `tactical_enemy.gd::_move_toward` yielding and `_choose_cover`. Basic separation is implemented; long-session crowd behavior and deadlock avoidance are **not exhaustively verified**.
3. Improve enemy visual articulation, model polish, physical input feel and audible weapon mix (`tactical_enemy_visual.gd`, `security_sidearm.gd`, `native_audio.gd`). Models are deliberately simple original geometry.
4. **Not implemented:** versioned explicit-checkpoint save/resume. Add a separate save module, serialize stage/inventory/taken pickups/living enemy states and committed campaign decisions; use temporary-write/replace and corrupt-save rejection. Integrate only at safe boundaries in `campaign_main.gd`, with duplicate-event/reward regression tests.
5. **Not implemented:** sight-aligned aiming. Current RMB is the existing FOV zoom. Preserve the independent weapon viewport when improving `player.gd` and `security_sidearm.gd`.
6. Test on the user's Windows Godot installation, other aspect ratios/drivers, and make a native export if desired. No full human playthrough, performance certification or cross-platform export is claimed.

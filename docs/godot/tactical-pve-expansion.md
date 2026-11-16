# Tactical PvE: Operation Iron Relay

Runnable feature branch: `feature/tactical-pve-expansion`, based on completed inventory commit `a6cd31c`. This adds a standalone native tactical operation; the original Breach, Control Room and Blackout campaign remains available. Classic browser source is unchanged. The merge with newer GitHub main preserves its Godot Pages hosting and separate Deep Signal operation; see [merge verification](tactical-main-merge.md).

## Play

Import `godot/project.godot` in **Godot 4.7.2 stable**, press **F5**, choose **Tactical Operation / Sector 12**, then **Start Tactical Operation → Deploy**. For the original campaign choose **Start Campaign → Deploy** on the initial title. The operation title also has an **Original Campaign** button.

From the repository root in PowerShell:

```powershell
$godotBin = 'C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
& $godotBin --path .\godot res://scenes/tactical_operation.tscn
# Original campaign:
& $godotBin --path .\godot
```

WASD moves, mouse looks, Ctrl crouches, Shift sprints, Q/C leans, RMB holds aiming zoom. Click/Space fires, R reloads, **1/2/3** selects owned pistol/SMG/shotgun, **E** collects supplies and operates objectives. P/Esc pauses, J opens the journal, F5 retries. Aiming remains zoom; it is not sight alignment.

## Included gameplay

- Restore Maintenance service access, recover the elevated Operations archive, then operate the eastern extraction lift. Clearing enemies cannot bypass this sequence. HUD distance/landmarks and terminal E prompts identify the next objective.
- Entry/security has staggered cover and crossfire; Maintenance offers a longer western approach; Operations has a raised archive, ramp, stairs and cover at different heights. Service access opens the east security gate. The western armory is optional and guarded.
- Eleven armed enemies use separate mobile SMG and slower, cover-oriented rifle configurations. Patrol, reaction, investigation, last-known-position search, cover/peeking, limited ally contact sharing, bursts and finite reloads use real world visibility. Physical bodies, separation and blocked-motion yielding reduce stacking. The static AStar3D graph shares blockers/terrain with the level, including its gate, ramp and stairs.
- Optional original Blender shotgun: four loaded shells, twelve reserve, eight individually occluded pellets, 0.85-second cadence and 1.7-second detachable-magazine reload. Damage loses effective pellets after 8 m and reaches zero at 18 m. Each blast consumes one shell and earns at most one accuracy hit. See [shotgun details and provenance](shotgun.md).
- E pickups require distance and world line-of-sight. Supplies grant finite reserve only to weapons currently owned; three caches can also restore up to 25 health. Weapon pickups do not auto-equip. All weapons keep independent magazine/reserve state; switching cancels an unfinished reload without transferring ammunition.
- Retry restores the whole operation: pistol 8/40, uncollected weapons/supplies, living patrols, closed gate, initial objectives, health and movement state. Inventory does not carry to another mission or a replay. Operation success does not commit original-campaign consequences. Preferences and session CSV follow the existing session behavior; pickups, switches, objectives and tactical events retain the CSV columns.

## Actual verification

Executed on Windows with Godot **4.7.2.stable.official.ed1daf0bf**, Compatibility renderer (D3D12/Mesa OpenGL), Blender **5.3.0**. No renderer change. Results below are fresh executions for this expansion, not saved historical reports.

| Check | Result and scope |
| --- | --- |
| Editor import/scripts | Exit 0; inspected output without script/import errors |
| `milestone_test.gd` | 46/46 headless; retained encounter/combat/device mechanics |
| `campaign_test.gd` | 51/51 headless; original three-mission progression, consequences, retries, menus and CSV |
| `inventory_test.gd` | 16/16 headless; independent ammunition, interruption, automatic timing, blocked pickups and resets |
| `tactical_movement_test.gd` | 17/17 headless plus 18/18 graphical; headless skips the captured handler while graphical verifies it; pitch math is tested separately |
| `operation_integration_test.gd` | 23/23 graphical; actual slot event dispatch, collision-driven complete/alternate routes, objectives, armory, reload switching, death/retry and pause |
| `operation_menu_test.gd` | 5/5 graphical; real button scene transitions and original Breach deployment |
| `operation_combat_test.gd` | 7/7 graphical; real production SMG windup, firing-time cover, lost-sight memory/search, reacquisition damage, magazine exhaustion, reload and pause |
| `shotgun_integration_test.gd` | 7/7 headless; blast damage, one-hit accuracy, defeat analytics, cover, range, shell consumption and interrupted reload |
| Independent `tactical_enemy_test.gd` | 22/22 headless; includes cover, allies, friendly obstruction, blocked yielding, actual operation ramp/stairs, death and reset |
| Independent `operation_level_test.gd` | 13/13 headless; authored physical routes, elevation and gate/navigation agreement |
| Independent `shotgun_test.gd` | 14/14 headless; pellet queries, falloff, partial occlusion, exclusions and asset parts; asset owner also ran 15/15 graphically |
| `close_smoke.gd` | Exit 0 with audio released and orderly shutdown |
| `npm.cmd test` | Exit 0; browser campaign, encounter and path suites passed; no browser engine errors reported |

The integration route suite disables AI to isolate collision/progression. The live-combat suite isolates one stationary production SMG and freezes the other ten actors. These are scripted graphical tests, **not a human full-operation combat playthrough**. The 10–15 minute first-playthrough goal has not been measured; short automated traversal times do not establish it. Independent review, fixed findings and coverage attribution are in [tactical-expansion-review.md](tactical-expansion-review.md).

Reproduce a suite with `& $godotBin --headless --path .\godot --script res://tests/NAME.gd`; omit `--headless` for graphical checks. Start with `& $godotBin --headless --path .\godot --editor --import --quit`. Historical campaign result JSON and earlier captures are preserved; these suites may regenerate them locally. Owner-executed outputs are saved in [tactical-expansion-test-output.txt](tactical-expansion-test-output.txt); component-owner and reviewer executions are attributed in their reports.

## Final integrated views

[Title](campaign-screenshots/operation-title.png), [entry](campaign-screenshots/operation-entry.png), [service access](campaign-screenshots/operation-access.png), [shotgun equipped](campaign-screenshots/operation-shotgun.png), [raised archive](campaign-screenshots/operation-archive.png), [completion](campaign-screenshots/operation-complete.png), [original campaign title](campaign-screenshots/operation-campaign-menu.png), and live enemy [windup](campaign-screenshots/operation-combat-windup.png), [firing](campaign-screenshots/operation-combat-firing.png), [reload](campaign-screenshots/operation-combat-reload.png). These use the final integrated scene and runtime asset. `operation-level-*` and `shotgun-asset.png` are isolated component previews, not gameplay playthrough evidence.

## Source and remaining work

`operation_main.gd` integrates menus/objectives/pickups; `operation_level.gd` owns authored geometry/navigation and the mission contract; `tactical_enemy.gd` owns tactics separately from `tactical_enemy_visual.gd`. Existing campaign/player/weapon infrastructure supplies shared movement, inventory, presentation and analytics. Interface agreement: [tactical-expansion-plan.md](tactical-expansion-plan.md).

All level geometry, enemy visuals, shotgun meshes/materials and synthesized sound are original project work. Editable shotgun `.blend` and reproducible generation script are under `assets/source/security-shotgun/`; runtime GLB is under `godot/assets/weapons/`. Existing original console/pistol/SMG assets are reused. No external asset or license dependency was introduced.

No confirmed blocking bug remains within the exercised scope. Before considering balance final, manually play the whole operation with all enemies active: measure duration/ammunition pressure, assess difficulty and audio, and test crowded doors/cover/elevation repeatedly. Other GPUs, resolutions and prolonged performance remain unverified.

Deferred optional stretch tasks:

1. **Safe checkpoint saves:** add a separate versioned serializer and tests, then integrate through `operation_main.gd`/`campaign_state.gd`. Persist objective/gate, actors, pickups, ammo and committed decisions atomically; test corrupt/missing files, event duplication and retries before exposing resume UI. Current progress is session-only; no save/resume UI is claimed.
2. **Sight alignment:** refine `scenes/security_sidearm.gd` and `scripts/player.gd` while preserving the isolated weapon viewport and world-camera behavior. Test all three weapons and their reloads; current RMB behavior is aiming zoom.

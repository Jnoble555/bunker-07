# Godot migration parity — partial port

Reference: browser implementation at `252e9a4`, especially `src/game.js`, `src/bunker-systems.js`, `docs/encounter-systems.md`, `docs/next-level-release.md`, and existing browser tests. This checklist was established before Godot implementation. The browser remains the complete playable reference. No full campaign parity is claimed.

Status: **Implemented M1** is validated by the 46 native checks and rendered smoke run recorded in verification.md; **Deferred** remains browser-only. This is still a partial port.

| Area | Implemented M1 | Deferred |
| --- | --- | --- |
| Movement/aiming | WASD/arrows, normalized 2.65 tile/s movement, wall collision, mouse/arrow yaw | Configurable sensitivity, other input devices |
| Weapon/feedback | 8-round magazine, .24s cooldown, .8s reload, shot occlusion, recoil/muzzle flash, hit and damage feedback | Original synthesized/spatial audio, full impact/stagger animation fidelity |
| Enemy | One armored guard: 3 HP, .58 tile/s chase, .42 patrol, 1.15 tile attack range, .75s windup, 18 damage, .12s stagger; LOS cancellation | Scout/turret roles, gunshot investigation/pathfinding, camera scan/detection, reinforcement spawn |
| Detection | Guard facing cone, 7-tile LOS range, 1.15s detection, alarm state; panel stops detection/silences alarm | Camera acquisition and 1.25s timing, multiple alert sources |
| Devices | Alarm panel: E within .85 tile, idempotent disable and retry reset | Shootable camera/lamp, power-light-camera tradeoff, bulkhead obstruction protection, one-use overload |
| Objectives | Control Room core gate/pickup and extraction; success/failure/retry | Breach/Blackout objectives and campaign transitions |
| Optional/campaign | Explicit partial-port result; no premature campaign consequence commit | Intel/cache, journal, ranks, successful-extraction-only campaign decisions |
| UI | Partial-port title, play/pause/resume/retry/result, HUD, controls | Settings/persistence, Breach onboarding, abandon confirmation, campaign summary |
| Analytics | Debug encounter event list for tests | CSV schema/export, session analytics, route/retry/rank event parity |
| Presentation | Original primitive 3D industrial geometry, materials, lighting, weapon and guard | Asset/animation/audio fidelity and remaining prop dressing |

## Shared implementation contract (agreed before delegation)

- `godot/project.godot` → `scenes/control_room.tscn` → `scripts/main.gd` (single integration owner). Runtime children: `World` (`room.gd`), `Player` (`player.gd`, CharacterBody3D + Camera3D/weapon), `Guard` (`armored_guard.gd`), UI CanvasLayer.
- Godot units are meters: **1 browser tile = 2m**; browser `(x,y)` maps to Godot `(2x,0,2y)`. Walls 3m high; flat floor, no jumping/pitch. Spawn `(3,0,17)`, yaw `-PI/2` looks east. Eye height 1.4m. Movement 5.3m/s, body radius .36m.
- Collision bits: **1 world**, **2 player**, **4 enemy**, **8 interaction reserved**. Actor movement masks world only (as browser actors do not block one another). Hitscan mask world|enemy, excluding player. LOS queries use world only; rays run in physics updates.
- Input actions: `move_forward`, `move_back`, `strafe_left`, `strafe_right`, `turn_left`, `turn_right`, `fire`, `reload`, `interact`, `pause`, `retry`. Space fires, E interacts, R reloads, Esc/P pause; no jump. Actions installed by main at startup, shared by UI and tests.
- All game timers use physics delta. SceneTree pause freezes actors and timers; menu input/UI process while paused. Retry reconstructs encounter state and clears pending actions, cooldown, reload, stagger, detection, gate, core and panel state.
- Room API: `build()` idempotent before play; `set_gate(closed: bool)`; `set_panel_disabled(value: bool)`; static `MAP` matches reference. Room generates world geometry/lighting only; no gameplay logic.
- Guard API: `setup(controller, spawn: Vector3)`; fields `hp`, `attack_windup`, `attack_cooldown`, `stagger`, `facing`, `alert_progress`, `moving`; `receive_hit()`; `reset_guard()`. Controller: `player`, `alarm_triggered`, `panel_disabled`, `active`, `has_los(from,to)`, `trigger_alarm()`, `damage_player(amount,source)`, `register_event(name,detail)`.
- Root owns player, weapon, session, input, UI and integration. Room owner edits only `godot/scripts/room.gd`; guard owner only `godot/scripts/armored_guard.gd`. Independent reviewer owns `godot/tests/milestone_test.gd` and review notes. Shared files are integrated by root.

## Baseline inspection and test provenance

Working tree initially clean on `main` at `252e9a4`; no applicable AGENTS.md found in repo or inspected ancestors. Installed executable: `C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`; actual `--version`: `4.7.2.stable.official.ed1daf0bf`.

Freshly executed `npm test`: 41 campaign + 53 encounter checks passed, no JS page errors; 3 local/Pages-path checks passed. Existing saved JSON reports are historical evidence except where regenerated by this run; browser test source remains unchanged. Runtime timing changes in regenerated reports do not represent gameplay edits.

Godot implementation/validation results are tracked separately in `verification.md`; passing browser tests does not establish native parity.

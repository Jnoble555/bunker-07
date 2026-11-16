# GHOST PROTOCOL: Phase 0 baseline

Historical Phase 0 findings and results below are preserved. Phase 1 now adds a passive recorder only; see the current [architecture](ghost-protocol-architecture.md) and [test results](ghost-protocol-test-plan.md). This is a historical baseline: Phase 2 now replaces immediate sharing for the SECURITY pair and removes the hidden-camera hit leak; see [radio implementation and verification](ghost-protocol-radio.md). Other historical findings remain the reference for unchanged local AI.

Audit date: 2026-11-15 (America/New_York). Source baseline: `0b50af7dec29daf432bfa10432501e888069d48f`. Initial working tree was clean. Scope: local source tracing and existing headless tests; no gameplay changes, new enemies, director implementation or difficulty tuning. [Architecture](ghost-protocol-architecture.md) and [test plan](ghost-protocol-test-plan.md) define future work.

## Verified active execution paths

`godot/project.godot` runs `scenes/control_room.tscn`, whose root script is `scripts/campaign_main.gd` (extends `main.gd`). `_ready` creates `player.gd`, `encounter_systems.gd`, `native_audio.gd`, builds menus and calls `show_title`. `_build_campaign_ui` binds both operation entries:

| Selection | Actual execution and dependencies |
| --- | --- |
| Deep Signal / Tactical Operation | `new_operation` selects `tactical_operation_data.gd::definition`, sets `operation_mode`, then `show_briefing` â†’ `deploy_current` â†’ `start_run` â†’ `_load_mission`. This creates `tactical_operation_room.gd` (extends `room.gd`), calls `build(mission)`, and `spawn_enemy` instantiates `deep_signal_enemy.gd` with `deep_signal_enemy_visual.gd`. Eight authored actors. |
| Tactical Operation / Sector 12 (Iron Relay) | `_launch_operation` changes scene to `scenes/tactical_operation.tscn`; `operation_main.gd` extends campaign controller but overrides `_load_mission` and `spawn_enemy`. It instantiates `scenes/operation_level.tscn` / `operation_level.gd`, reads `mission_contract`, and creates `tactical_enemy.gd` actors. Its title offers Start Tactical Operation and Original Campaign; it hides Deep Signal. |
| Original campaign | `new_campaign` selects `mission_data.gd` missions and `armored_guard.gd` through inherited `GuardScript`; `room.gd` and `encounter_systems.gd` handle campaign devices. |

Thus `tactical_enemy.gd` and `operation_level.gd` are active in Iron Relay, but are **not** Deep Signal's AI or geometry. Older passages in [Deep Signal documentation](deep-signal.md) retain pre-merge filenames; its opening correction and [merge record](tactical-main-merge.md) explain the split. No inference here relies on those historical test totals.

`campaign_main.gd::operation_interact` requires proximity and LOS to panel (23,0,39), then archive (43,1.2,7), incrementing `operation_stage`. `_physics_process` finishes at exit (45,1.2,4) only at stage 2. Restoring access is objective progression, not a Deep Signal navigation gate. Inventory/pickups are attempt-scoped through `reset_inventory`, `make_pickups`, `pickup_specs`; shared definitions/ballistics are `weapon_definitions.gd`, `shotgun_definition.gd`, `shotgun_ballistics.gd`. No objective depends on eliminating every guard.

## Deep Signal behavior inventory

All functions below are in `godot/scripts/deep_signal_enemy.gd` unless qualified. Classification is proposed future treatment, not a change made here.

| Behavior | Current implementation | Treatment |
| --- | --- | --- |
| Patrol | `setup` copies authored patrol; `_decide` cycles within .65m, speed .55 of normal | PRESERVED |
| Vision | `can_see_player`: rifle 28m / SMG 21m eye range; patrol beyond 3m uses forward dot >= .15 (about 163Â° full cone); other states have no cone restriction | EXTENDED with explicit observation snapshots; preserve tuning initially |
| LOS | `visible_point` ray from eye at +1.45m to live camera, world layer 1 only | PRESERVED; awareness LOS does not include allied bodies |
| Hearing | `hear_shot`: distance <=19m; no wall attenuation. Unless engaged, stores exact sound position for 7s and enters suspicious | EXTENDED with source identity, uncertainty and age |
| Memory | `last_known` / `memory_remaining`: sight sets camera position and 8s; no sight decrements timer. Search walks to snapshot; within 1.2m horizontally rotates; expiry clears memory/cover and patrols | EXTENDED; snapshot coordinate is eye height, path normalizes floor height |
| Ally communication | `_physics_process`: while seeing, every 2s directly calls ally `hear_shot(last_known,true)` for allies <9m from sender. Receiver independently rejects if >12m from reported position; engaged receivers ignore updates | REFACTORED: period is a throttle, not delivery delay; no sender/receiver LOS or interruption window |
| Suspicion/engagement | `_decide`: visual reaction .65s, then engage; loss of sight clears reaction, windup and burst. Suspicious investigation becomes search on arrival | EXTENDED while retaining readable attack timing |
| Cover | `_choose_cover`: rifle only; reachable authored points 5â€“23m from memory, skips points near compromised hit position and living allies within 1.2m; distance score gets -5 for low ray occlusion. Reconsiders every 5s | EXTENDED; proximity avoidance is not a reservation |
| Navigation | `_move_toward` calls `room.tactical_path` every .6s or target shift >1m; pops waypoints within .55m. Rifle 1.65m/s, SMG 2.5m/s | PRESERVED |
| Firing/reload | `_fire` rechecks sight, faces camera, checks eye-to-muzzle world ray and muzzle-to-target world/allies ray. Magazine 15 SMG/9 rifle; burst 3/2, windup .48/.65s; reload 1.9/2.4s. Every third magazine-indexed shot deliberately misses; damage 5/8 | LEFT UNTOUCHED |
| Collision/stuck | Capsule radius .32/height 1.8, world/player/enemy collision; gravity and .26m step helper. Ally separation within 1m; <.01m displacement accumulates stuck, sideways yield after 1.2s, resets after 2s | PRESERVED; EXTENDED only with stuck telemetry |
| Damage/death | `receive_hit` staggers .22s, interrupts burst, marks cover compromised; death removes collision layer, stops/hides actor and emits disabled event | PRESERVED; add lifecycle notification later |
| Hidden-position leak | Surviving `receive_hit` calls `hear_shot(_player_eye())`, querying live hidden camera without a visual observation; hearing radius/state checks may suppress it | REFACTORED in evidence phase; do not silently fix in Phase 0 |

Immediate sharing gives a nonobserving receiver a precise camera coordinate without transmission time, communication LOS or uncertainty. Its receiver-to-source range check also conflates radio and sound semantics. `reset_guard` clears primary state but does not explicitly reset `_share_timer`, `_reposition`, `_path_target` or `_flash`; actual mission retry recreates actors, so this primarily affects direct reuse/tests.

Iron Relay's separate `tactical_enemy.gd::_share_contact` immediately calls `receive_contact` within 11m plus ally LOS, throttled at 2.5s; it likewise has no delivery delay. Its `receive_hit` explicitly avoids querying hidden player location. Do not port its cover, peek, withdraw or navigation assumptions into Deep Signal automatically.

## Noise, navigation and lifecycle

`campaign_main.gd::shoot` broadcasts one `hear_shot(origin)` per enemy after ballistics (or `on_noise(player.global_position)` for Iron Relay); sound origin is the camera snapshot for Deep Signal. `encounter_systems.gd::on_shot` is Control Room-specific and returns outside that mission. `player.gd::_physics_process` implements crouch/sprint/lean/aim and physical movement but emits no movement/hearing events. `native_audio.gd::play` creates finite pausable spatial voices (24 cap, 40m audible range), independently of AI hearing. Muting audio does not mute perception. Enemy shots play sound but do not broadcast the player's gunshot hearing event.

`tactical_operation_room.gd::build` authors walls/cover and builds `AStar3D` through `_build_navigation`: 1m grid, cardinal links, <=.3m height difference, authored `solids` with .48m clearance. `height_at` maps elevated deck and ramp; `navigable` rejects bounds and inflated solids. `tactical_path` rejects invalid destinations, selects nearest graph endpoints, rejects end snap >1.6m, returns path plus requested floor destination. It does not use a NavigationAgent/navmesh. `cover` adds four side points around each 2.4Ã—1.25Ã—1.2m solid; navigation filters invalid points. Foundation/deck/ramp collisions are authored separately from blocker rectangles; physical traversal tests matter in addition to graph reachability.

Iron Relay instead exposes `operation_level.gd::find_path`, `floor_height`, `_edge_clear`, `_rebuild_navigation` and `set_access_granted`; its gate rebuild and cover points belong to that map only.

Enemies are PAUSABLE and controller is ALWAYS; controller `_physics_process` guards `active` and tree pause. `set_paused` clears held inputs; journal/settings pause play. `finish` clears pending actions/reload/windups, deactivates and pauses. Player death calls failure through `damage_player`. `retry_run` increments retries and calls `start_run`, which stops audio, unpauses, clears inputs, resets stats/inventory/objectives, frees/rebuilds room and actors via `_load_mission`, resets player/systems/pickups then activates. `show_title` deactivates and clears inputs; actors can remain allocated but inactive until next load. `advance_campaign` returns Deep Signal results to title. `_exit_tree` shuts audio down; `_quit_safely` deactivates, pauses and drains stopped streams before quit. Future director teardown must cover all these paths, not only retry.

## First encounter: SECURITY pair

Select the initial SECURITY area, not the isolated armory rifle or the upstairs single-approach deck. Coordinates are world meters from `tactical_operation_data.gd::definition`:

| ID | Role / HP | Spawn | Patrol points |
| --- | --- | --- | --- |
| security-smg | SMG / 5 | (24,0,38) | (24,0,38), (28,0,36) |
| security-rifle | rifle / 5 | (27,0,30) | (27,0,30), (24,0,28) |

The pair starts about 8.54m apart, on opposite sides of the z=32 sector divider's central x=22..28 opening. Nearby cover solids are centered at (20,0,41), (27,0,35), (22,0,28); candidate points are their Â±1.5m z and Â±2m x offsets, subject to `navigable` filtering. These walls/cover allow sight breaks and multiple approaches without redesign. The x=16 partition has a z=38..43 opening toward SECURITY; western maintenance provides an alternate approach, and the central opening connects to the rifle's sector. Entry is (5,0,44), with SMG/ammo near (7,0,43)/(8,0,43). SECURITY panel (23,0,39) is the first required objective; archive and northeast extraction follow. Guard elimination is optional.

Existing `tactical_operation_test.gd::walk_to` physically verifies direct entryâ†’(23,0,38), alternate entryâ†’(8,0,23)â†’(23,0,38), and onward relayâ†’(38,0,23)â†’rampâ†’(38,1.2,14)â†’archiveâ†’exit. Those tests stop most enemies during route checks; they establish traversal, not polished live combat or successful coordinated tactics. Alternate route fighting and exact sightlines still need human playtesting. No route or coordinate is taken from Iron Relay.

## Observability audit

`campaign_main.gd::register_event` appends `run`, `elapsed_seconds`, `event`, `bot_id`, health/ammo/shots/hits, `detail`, `mission_id`; `export_csv` delegates formatting to `campaign_state.gd::csv_text`, with native FileAccess or web download. Extend this stream rather than create another logger.

| Desired event | Present capture / gap |
| --- | --- |
| Sees player | `enemy_state=suspicious/engage` is indirect; no explicit observation position or first-seen event |
| Hears noise | State change may be logged; repeated hearing in same state is invisible |
| Loses contact | No explicit edge event; search state is incomplete evidence |
| Begins search | `_transition` emits `enemy_state=search` |
| Receives report | No explicit event; indistinguishable from hearing |
| Changes role | Weapon `role` is static; no tactical assignment role exists |
| Returns to patrol | `_transition` emits `enemy_state=patrol` |
| Becomes stuck | `_stuck` is internal; no event |
| Eliminated | `guard_hit`, then `bot_disabled`; legacy adapter converts disabled ID to enemy array index |

Use versioned JSON in existing `detail` for stable authored enemy ID, simulation tick, observation position, evidence/report IDs and metadata; schema and sampling are defined in [architecture](ghost-protocol-architecture.md). Avoid logging every sight frame and avoid a permanent HUD.

## Baseline execution

Fresh results below are from this audit, not copied historical reports. Godot executable/version: `C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`, `4.7.2.stable.official.ed1daf0bf`, matching `godot/README.md`.

From repository root PowerShell:

```powershell
$godotBin = 'C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotBin --version
& $godotBin --headless --path .\godot --editor --import --quit
# For EACH suite in the results table, substitute its exact name:
& $godotBin --headless --path .\godot --script res://tests/deep_signal_enemy_test.gd
```

Every table row uses the final command above with only the basename replaced (normal physics timing, no fixed-fps override). Console transcripts are retained locally at `$env:TEMP\bunker07-ghost-baseline\<suite>.log`. Import exited 0 but reported inaccessible root certificate store and failure saving global editor settings. All test process outputs must be interpreted alongside assertion totals; user-log writes are restricted in this environment.

| Suite (`res://tests/` basename) | Result | Exit | Warnings / limits |
| --- | --- | --- | --- |
| `deep_signal_enemy_test.gd` | 14/14 pass | 0 | E |
| `tactical_enemy_test.gd` | 22/22 pass | 0 | E |
| `operation_level_test.gd` | 13/13 pass | 0 | E |
| `operation_combat_test.gd` | 7/7 pass | 0 | E |
| `tactical_movement_test.gd` | 17 pass, 0 fail; captured-mouse check skipped | 0 | E; graphical input unavailable |
| `tactical_operation_test.gd` | 28/28 pass | 0 | E |
| `operation_integration_test.gd` | 23/23 pass | 0 | E |
| `operation_menu_test.gd` | 7/7 pass | 0 | E |
| `inventory_test.gd` | 16/16 pass | 0 | E |
| `shotgun_test.gd` | 14/14 pass | 0 | E |
| `shotgun_integration_test.gd` | 7/7 pass | 0 | E |
| `milestone_test.gd` | 46/46 pass | 0 | E |
| `campaign_test.gd` (default environment) | 49/51 pass; preferences and CSV write assertions fail | 1 | E; user data write restrictions |
| `campaign_test.gd` (isolated APPDATA rerun) | 51/51 pass | 0 | Root certificate-store error only |
| `close_smoke.gd` | Orderly stop/audio release message and clean exit | 0 | E |

E = each run reported failure opening the user log (including rotated log) and failure reading the root certificate store. These are environment errors, not assertion failures; engine output was captured externally. No other engine warnings/errors occurred in the listed runs.

The campaign rerun used this exact environment setup and command (in a separate shell process, leaving the user environment unchanged):

```powershell
$auditDir = Join-Path $env:TEMP 'bunker07-ghost-baseline'
$env:APPDATA = Join-Path $auditDir 'appdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
& $godotBin --headless --path .\godot --script res://tests/campaign_test.gd
```

Its transcript is `campaign_test-isolated.log` in the same temporary log directory. This rerun verifies persistence in a writable isolated profile; it does not certify the user's normal profile permissions. Import and test-generated changes to tracked `.import` metadata and result JSON were restored to baseline bytes. Only the three Phase 0 Markdown documents remain changed.

Graphical visual suites, captured mouse, audible sound verification, human playthrough and web export/browser smoke were not run in this documentation-only phase. They remain explicit validation limits, not passing checks. Existing tests exercise real engine physics but do not cover future delayed radio, uncertainty, assignment reservations or director lifecycle.

## Prioritized risks and readiness

1. **Fairness:** immediate precise sharing and live-camera hit reaction must be replaced during the evidence/communication milestone, with explicit regression assertions.
2. **Lifecycle:** controller inherits ALWAYS processing, actors are pausable; a future clock on the controller could run during pause unless guarded. Stale callbacks after retry or scene switch must carry attempt generation.
3. **Integration ambiguity:** both operations share mission ID `tactical-operation` while using different geometry, AI and objective logic. Gate director integration on Deep Signal mode/controller, not mission ID alone; include operation identity in future telemetry metadata.
4. **Navigation:** cover avoidance has no reservation, path endpoints snap to grid, and graph clearance is not a full dynamic collision guarantee. Preserve physical traversal tests and validate each future assignment.
5. **Evidence/telemetry:** state transitions omit observation provenance and report receipt; remapped legacy bot IDs are unstable. Add authored IDs without breaking CSV consumers.
6. **Validation limits:** headless checks cannot certify rendered cues, browser controls, audio or encounter enjoyment. Environment write/certificate errors are separately recorded above.

**READY WITH DOCUMENTED RISKS.** All 14 relevant test programs completed successfully, with campaign requiring an isolated writable application-data directory. The first campaign run failed two persistence assertions under the default restricted environment; the unmodified suite passed all 51 checks on rerun. No production correction was needed. Future coordination remains subject to the fairness and lifecycle risks above. Baseline assumptions: local checkout is authoritative, hosted deployment was not inspected, simulation stays on Godot 4.7.2 Compatibility, and Phase 1 initially adds passive infrastructure only. No new test scaffolding is needed before the real director exists.


## Phase 1 implementation checkpoint

The original code baseline was verified at the same commit before implementation, with only these three previously authored documents untracked. Phase 1 adds `security_director.gd`, passive hooks in `campaign_main.gd`/`deep_signal_enemy.gd`, and two new SceneTree test programs. No player, level, weapon, mission data, Iron Relay AI or original regression assertions were modified. Current behavior preservation evidence and execution results live in the [test plan](ghost-protocol-test-plan.md); the Phase 0 totals above remain historical.

The director records legitimate local sightings, sight loss at the last observed point, and audible shot events. It does not read evidence back into enemy decisions. Direct ally sharing and live-camera hit reactions remain exactly the risks described above; those legacy paths are excluded from new legitimate sound records. Mission ID collision between operations is handled by Deep Signal `operation_mode`, not ID matching. The Phase 0 Node suggestion was replaced with an explicitly advanced mission-owned RefCounted; current lifecycle/API details supersede the old proposal.

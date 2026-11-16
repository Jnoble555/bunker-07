# GHOST PROTOCOL: verification plan

Phase 2 current results and the tested radio acceptance matrix are in [ghost-protocol-radio.md](ghost-protocol-radio.md). The sections below preserve the original Phase 0/1 plan and results; delayed radio is now implemented/tested, while assignments, coordinated search and de-escalation remain future work. The runner now includes 18 programs.

Phase 1 implements a real passive director and two SceneTree test programs. The automation results below describe executed checks; the later behavior matrix remains future work. No mock radio/planner or existing regression assertion changes were introduced.

## Original behavior acceptance matrix

| Case | Fixture / stimulus | Required assertion |
| --- | --- | --- |
| Hidden movement | Confirm visual observation A, block sight, move player to B without noise | Local/shared evidence remains A with advancing age; no B in knowledge or assignments |
| Sound uncertainty | Emit one shot at A then move silently | Sound snapshot has nonzero uncertainty, expires, never tracks B; one event per shot rather than pellet |
| Radio delay | Submit report at tick T with delay D | No recipient/shared update through T+D-1; one delivery at T+D retaining original observation time |
| Interrupted report | Cancel at T+D-1 | No delivery later; cancellation includes reason |
| Dead sender | Kill before send and during pending send | Submission rejected / pending report cancelled; delivered historical evidence remains valid |
| Assignment separation | Two living guards request same sector | Different reserved reachable destinations or explicit no-assignment fallback; stable ID ordering |
| Invalid routes | Fake empty path; solid/outside/deck target in real room | Reject unreachable target; never snap through walls; no stale reservation |
| Pause | Pending report, decay and assignment expiration; pause via menu/journal/settings | No tick/deadline progress; resume delivers at remaining simulation delay |
| Retry | Pending report and reservation followed by F5 | New attempt has no knowledge/queue/reservations; old callbacks rejected |
| Replay | Same seed, observations and fixture; vary registration order | Identical canonical reports/roles/destinations/events; different seeds remain valid |

`godot/tests/security_director_test.gd` now tests the actual passive recorder, using existing `check`, printed totals and nonzero `quit` convention. Future communication/assignment tests should extend coverage when those implementations exist. Assert state and event contents, not only logs or existence of files. Do not weaken current regression assertions.

## Phase 3 executed coverage

`security_search_integration_test.gd` exercises actual SECURITY actors in the authored room. It verifies delayed assignment, provenance, two roles and separated reservations, reachable paths, deterministic replay, hidden-position invariance, physical arrivals, firing occlusion, reacquisition, delayed supersession, sight-episode deduplication, fallback, pause and lifecycle. It also records a bounded eight-guard performance sample. The original Phase 2 suites continue to verify radio delivery priority, the real pistol interruption and attempt isolation. See the [Phase 3 report](ghost-protocol-search.md) for encounters A–E, measured timings and remaining playtesting.

## Integration and regression

Use `operation_menu_test.gd` for actual title entry, `tactical_operation_test.gd` for Deep Signal traversal/progression/retry and `deep_signal_enemy_test.gd` for local perception/fire/memory/reload/pause/death. Iron Relay is covered independently by `tactical_enemy_test`, `operation_level_test`, `operation_combat_test`, `operation_integration_test`. Movement, inventory and shotgun suites must remain unchanged; campaign/milestone and close smoke protect inherited lifecycle/audio. Commands and fresh Phase 0 outcomes are in the [baseline](ghost-protocol-baseline.md).

Integration scenarios: enter Deep Signal from title, deploy, observe security pair, interrupt sender during radio, break LOS behind security cover, reposition via maintenance, pause mid-report, die then retry, complete panel/archive/extraction, return to title, launch Iron Relay and original campaign. Assert no old attempt event arrives, no duplicated signal connection, and no director in campaign/Iron Relay. Verify muted audio does not suppress AI noise events. Test sound on both sides of walls according to the documented future acoustic policy; baseline currently uses distance only.

## Human playtest (not performed in Phase 0 or Phase 1)

- Stealth: approach SECURITY from entry and maintenance; determine whether visual/radio cues explain each guard's response.
- Direct combat: engage the SMG, break sight during warning, kill a transmitting guard; verify the second guard has only delivered evidence.
- Reposition: use cover near (20,0,41) and (27,0,35), leave the old firing lane, and inspect whether searching stays tied to observations rather than hidden movement.
- Expiration: remain silent out of sight, observe search then patrol/de-escalation; make a new legitimate sound and compare response.
- Lifecycle: journal/settings/pause while transmitting, resume, F5, defeat, victory, title and operation switching. Confirm clean input capture, ammo/objective resets and no unexpected damage while paused.

Record route, seed, frame rate, engine/build, guard IDs and perceived fairness; do not claim measured encounter length from the 10–15 minute design goal. Native captured mouse, rendered visibility, audible mix and browser controls require graphical checks.

## Performance, reproduction and debugging

Measure baseline and director-enabled runs on the existing eight-guard map; capture average and p95 physics/director cost, queue length, path requests per second and telemetry size. Set a target budget on the supported device before tuning; avoid inventing measured numbers. Verify bounded queues, deduplication, expiration and no per-frame path query explosion. Stress repeated retries (100), simultaneous reports and guard removal; track orphan nodes/connections and memory growth. These are future checks, not Phase 0 results.

Replay fixtures contain engine version, physics rate, mission/geometry revision, seed and timestamped legitimate observations, never require a live player. Use event filters by run, stable enemy ID, observation and report IDs. Validate Web Compatibility import/export and a browser smoke run after integration; headless success does not establish browser or visual parity. Store generated logs/builds outside tracked source and distinguish assertion failures, engine warnings, skipped checks and process exit status.


## Phase 1 executed verification

All commands run from the repository root with Godot `4.7.2.stable.official.ed1daf0bf`. Use an isolated writable profile for the whole run, including persistence checks:

```powershell
$godotBin = 'C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$auditDir = Join-Path $env:TEMP 'bunker07-ghost-phase1'
$env:APPDATA = Join-Path $auditDir 'appdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
& $godotBin --headless --path .\godot --editor --import --quit
$suites = @('security_director_test','security_director_integration_test',
    'deep_signal_enemy_test','tactical_enemy_test','operation_level_test',
    'operation_combat_test','tactical_movement_test','tactical_operation_test',
    'operation_integration_test','operation_menu_test','inventory_test',
    'shotgun_test','shotgun_integration_test','milestone_test','campaign_test','close_smoke')
foreach ($suite in $suites) {
    & $godotBin --headless --path .\godot --script "res://tests/$suite.gd"
}
```

Run that setup in a separate shell to avoid changing the user's normal application-data environment. Local transcripts are retained at `$env:TEMP\bunker07-ghost-phase1\<suite>.log`; no logs/builds are committed. Import exited 0. All completed engine runs report the same host root-certificate-store read error; isolated profiles eliminate the earlier user-log/persistence write errors. This certificate error does not fail game assertions and is not fixed by changing unrelated game code.

| Program (`res://tests/` basename) | Actual result | Exit |
| --- | --- | --- |
| `security_director_test.gd` | 30/30 pass | 0 |
| `security_director_integration_test.gd` | 33/33 pass | 0 |
| `deep_signal_enemy_test.gd` | 14/14 pass | 0 |
| `tactical_enemy_test.gd` | 22/22 pass | 0 |
| `operation_level_test.gd` | 13/13 pass | 0 |
| `operation_combat_test.gd` | 7/7 pass | 0 |
| `tactical_movement_test.gd` | 17 pass, 0 fail; captured-mouse check skipped headlessly | 0 |
| `tactical_operation_test.gd` | 28/28 pass | 0 |
| `operation_integration_test.gd` | 23/23 pass | 0 |
| `operation_menu_test.gd` | 7/7 pass | 0 |
| `inventory_test.gd` | 16/16 pass | 0 |
| `shotgun_test.gd` | 14/14 pass | 0 |
| `shotgun_integration_test.gd` | 7/7 pass | 0 |
| `milestone_test.gd` | 46/46 pass | 0 |
| `campaign_test.gd` | 51/51 pass (isolated profile) | 0 |
| `close_smoke.gd` | Gameplay stopped, audio released, orderly exit | 0 |

All 14 Phase 0 regression programs and both new programs ran successfully: **328 passing assertions plus orderly-close smoke**, zero final assertion failures. All rows share the certificate-store error described above; no other final test engine errors/warnings were reported. Results were collected during the 2026-11-16 session (America/New_York).

The new unit suite exercises uninitialized/invalid input rejection, exact simulation deltas and deadlines, all three event kinds, IDs, detached input/query data, object/nested metadata rejection, 1000-event capacity pressure, eviction reason, clear/reinitialize and deterministic replay. No graphical game is required.

The integration suite uses the actual Deep Signal room/controller/actors. It tests original campaign and Iron Relay exclusion, single initialization per attempt, visible contact and one-second refresh, once-only loss at the old visual point, hidden movement, pause/journal/settings/resume, sound radius and actual shooting broadcast, existing investigation/memory behavior, excluded legacy sharing/hit shortcuts, death/value-only evidence, structured CSV telemetry, three retries, defeat/victory/abandon, campaign switching and scene teardown. Existing enemy combat/navigation assertions remain in the unmodified regression suites.

A test-only parser mistake in the initial integration run (`RefCounted is Node` cannot type-check) was corrected before the successful runs; production logic and existing assertions were not weakened.

### Native graphical smoke

```powershell
$env:APPDATA = Join-Path $auditDir 'graphical-appdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
& $godotBin --path .\godot --rendering-driver opengl3 --audio-driver Dummy --script res://tests/security_director_integration_test.gd
```

Executed with exit 0, **33/33 passed**, Compatibility/OpenGL ES via ANGLE on Qualcomm Adreno X1-85. Transcript: `security_director_integration-graphical.log`. This is scripted native rendering smoke, not human input, visual-quality certification or audible sound testing. The dummy audio driver leaves audible mix unverified.

### Web and performance limits

Local export was attempted, and exited **1 (blocked)** because the matching Godot 4.7.2 web export templates are not installed. No web build was produced, so browser smoke of these changes is **unverified**. The hosted game was not used as evidence for local modifications. Transcript: `web-export.log`.

```powershell
$webDir = Join-Path $auditDir 'web'
New-Item -ItemType Directory -Force -Path $webDir | Out-Null
& $godotBin --headless --path .\godot --export-release Web (Join-Path $webDir 'index.html')
```

Install the engine-matching official web templates and repeat this command before browser validation. The existing Pages workflow pins 4.6.3 whereas native documentation/testing uses 4.7.2; that pre-existing version mismatch remains a documented release risk. No workflow version was changed in this phase.

No rendering/networking/external dependencies, independent timers or geometry queries were added to the director. The active evidence scan is capped at 128 records; unit tests exercise 1000 insertions. There is no measured CPU/p95/frame-time or long-session memory budget in this phase. Session CSV history remains unbounded as in the baseline; refresh throttling avoids per-frame observation logs but repeated real shots still add evidence/events. Human fairness testing and full performance stress remain pending before the records influence behavior.

### Phase 2 readiness

The passive foundation is usable for delayed-radio development. Before changing behavior, add report provenance/attempt generations, cancellation on death/exit and stale-evidence handling; then replace direct sharing and hidden-position hit leakage explicitly. Add the future matrix tests rather than treating the current passive tests as proof of fair radio/search behavior. No radio, assignments, flanking, sector alerts, uncertainty aging or decision outputs exist yet.


### Gameplay preservation and final source check

A source comparison against `0b50af7dec29daf432bfa10432501e888069d48f` confirms these existing Deep Signal functions are unchanged: `capacity`, `eye`, `visible_point`, `_player_eye`, `can_see_player`, `_transition`, `_decide`, `_fire`, `_face`, `_move_toward`, `_choose_cover`, `_step_up`. The original ally-sharing loop, reaction/windup/reload calculations and memory assignments are retained. The only change to the hit call adds a passive-logging suppression argument; the legacy camera read and investigation outcome are deliberately tested as preserved.

Generated changes to `security_shotgun.glb.import`, `security_smg.glb.import`, `campaign-results.json` and `milestone-results.json` were restored after execution. New `.gd.uid` sidecars follow existing source conventions and are retained. `git diff --check` and document placeholder/whitespace checks completed without errors. No existing test file, player/weapon/level/mission data or workflow was changed.

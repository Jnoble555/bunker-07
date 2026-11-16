# GHOST PROTOCOL Phase 2: interruptible radio

## Scope and starting evidence

Branch: `feature/ghost-protocol-radio`, from clean, freshly fetched `main` at deployed baseline `40567cb441f65b7d2f78ca2983ba6e521f9ff034`. All **16 baseline programs passed before production edits** (328 assertions plus orderly-close smoke). Phase 2 changes information transfer and the damage information leak only. No flanking, coordinated search, role assignments, global alerts, reinforcements, new actors or geometry are implemented.

**BROWSER SMOKE TEST BLOCKED.** An interactive attempt against https://jnoble555.github.io/bunker-07/ returned `The browser access host is unavailable`. No safety controls were bypassed. Title/briefing, mouse capture, aiming, movement, shooting, live cover/damage, pause/F5, audible audio and console cleanliness are all unverified in a browser. Prior HTTP asset checks establish release identity only. This remains an open release gate, even if CI and export pass.

## Before and after

Previously, any seeing Deep Signal guard could immediately call nearby allies' `hear_shot(last_known,true)` every two seconds. That conflated sound with exact sightings, lacked transmission delay/interruption and could promote arbitrary memory. Nonfatal damage also called the live player camera, revealing hidden positions.

Now the observing guard records a real `visual_contact` and offers that exact observation ID for transmission. The mission controller authorizes only the `security-smg` / `security-rifle` partnership, within **12m** at submission and delivery. The director copies the original evidence and schedules completion **1.4 simulation seconds** later. No shared/local recipient knowledge is created before completion. Original position, observation time, confidence, observer ID and expiry survive unchanged. The recipient uses its existing suspicious/search/navigation behavior; radio does not manufacture visibility or enable shooting through walls.

The initial 9m candidate was rejected because authored patrol endpoints can separate the pair by 10m. The 12m radio radius covers those patrols without editing spawns or patrol points. The existing two-second attempt throttle is retained; a sender may have only one pending report. Other six guards still perceive, hear, fight, navigate and search locally, but cannot broadcast radio in this milestone. No radio obstruction ray is added: walls block vision/projectiles, not this short-range link.

Any actual hit entering the existing .22s stagger cancels an active report immediately; death also cancels. Reload, attack and pose animations do not cancel. Losing sight does not cancel an already valid historical report. Evidence expiry, missing/dead actors, out-of-range recipients and mission cleanup also prevent delivery. Repeated hits or repeated cancellation cannot produce duplicate finish cues.

A nonfatal hit preserves health reduction, stagger, interrupted burst/windup, compromised-cover handling and hit telemetry, but supplies no position. An unaware patrol becomes suspicious. Existing legitimate remembered evidence remains unchanged. The actual player shot broadcast still follows damage and can independently be heard within the unchanged 19m radius. Thus interrupting a warning at close range may still alert the partner honestly through gunfire; cancellation is not silence.

## Implemented contracts

The Phase 1 observation API remains available, including 128 observations, finite validation, detached queries and deterministic expiry. `initialize_for_mission(mission_id, attempt_id=0)` adds an optional attempt identity; existing one-argument callers remain valid. The controller passes its monotonically increasing attempt counter. A standalone director generates a local generation when no positive attempt ID is supplied.

Radio APIs in `security_director.gd`:

```gdscript
func sync_radio_actors(actors: Dictionary) -> void
func queue_radio_report(sender_id: String, observation_id: int,
    recipient_ids: Array, delay_seconds: float) -> int
func cancel_radio_report(report_id: int, reason: String) -> bool
func cancel_reports_from(sender_id: String, reason: String) -> void
func get_pending_radio_reports() -> Array[Dictionary]
func get_radio_report(report_id: int) -> Dictionary
func get_radio_history() -> Array[Dictionary]
func get_delivered_knowledge_for(recipient_id: String) -> Array[Dictionary]
func get_attempt_id() -> int
signal radio_report_changed(report: Dictionary)
signal radio_report_delivered(recipient_id: String, report: Dictionary)
```

Queue rejection returns 0 and consumes no ID. Cancellation returns true once for a pending report, false otherwise; reason must be nonempty and at most 64 characters. Unknown, expired, nonvisual or another observer's source cannot be transmitted. Forwarding/relay chains are intentionally unsupported. Only registered living, unstaggered senders can submit. The controller supplies position/alive/interrupted value snapshots, never actor objects; the pure director accepts at most 64 valid IDs and production supplies only two. Recipient arrays are validated as strings, sorted/deduplicated, self/unknown/dead/out-of-range IDs filtered, and fanout capped at two (production partnership has one).

| Report field | Meaning |
| --- | --- |
| `id` | Increasing report ID per attempt, separate from observation IDs |
| `observation_id`, `observer_id` | Original visual evidence and author |
| `sender_id` | Actual transmitter; must equal original observer in Phase 2 |
| `recipient_ids` | Sorted unique intended eligible IDs at submission |
| `position`, `observed_at`, `confidence`, `expires_at` | Immutable copies of original sighting position, created time, confidence and expiry |
| `submitted_at`, `completes_at` | Simulation submission time and scheduled completion |
| `attempt_id`, `mission_id` | Attempt and operation identity |
| `status`, `cancellation_reason` | `pending`, `delivered` or `cancelled`; reason is explicit for cancellation |
| `delivered_recipient_ids` | Living/in-range recipients retained at successful completion |

The pending queue is capped at **16**, terminal history at **64**, and active delivered history at **32 per recipient**. Capacity rejects new pending reports rather than evicting a transmitter invisibly. Recipient history evicts oldest delivered records; dedup keys remain for each active source so history eviction cannot allow repeated refresh. Keys disappear on source expiry/eviction or recipient removal; only still-queueable source observations need keys. An in-flight report may retain an evicted original snapshot until its original expiry, without requiring a history reference. Every returned record/list is deeply copied. No observation/report/actor snapshot stores a Node.

## Clock, delivery and lifecycle

The controller advances the director once in active, unpaused physics, after this tick's player fire/actions. This makes player hit interruption win a completion-frame tie. Before advancing it synchronizes current pair membership, positions, life and stagger. Queue submission also synchronizes eligibility. At completion both director and controller revalidate sender, recipients, range and attempt. Queued-for-deletion actors are ineligible. Same-deadline reports resolve in stable report-ID insertion order; recipient order is lexical. Equal ordered updates/events produce equal reports and knowledge. No wall clock, independent timer, random decision, networking or player lookup is used by the director.

Evidence that cannot outlive the scheduled completion is rejected up front. If a late simulation update finds evidence already expired, it cancels rather than retrospectively delivering stale knowledge. Knowledge expires at the original deadline. Newer or strictly more confident active local evidence wins over incoming radio; equal timestamp ties keep current knowledge. Receiving stores remaining original lifetime, not a new eight-second timer. Delivered-history queries describe arrived messages, not a fused best belief; the actor retains authority over its newer direct/local knowledge. Dedicated `receive_radio_report` never calls `hear_shot`, `can_see_player`, or the camera.

Immediate death/hit cancellation supplements per-tick revalidation. Pause/journal/settings freeze the countdown. Retry, briefing/campaign switch, defeat/victory, title/abandon, scene exit and orderly quit use the existing common cleanup. It disconnects gameplay radio signals, clears local indicators, cancels pending reports for telemetry, clears history/knowledge/identity and releases the director. Completion callbacks cannot repopulate a cleared attempt; stale previous-attempt deliveries are rejected by the actor. Death does not resurrect a recipient or retain actor references.

## Readability and telemetry

`native_audio.gd` adds short spatial `radio_start` (.16s), `radio_success` (.14s) and `radio_interrupted` (.18s) synthesized chirps, gains .12/.10/.13 versus pistol .24. They use the existing cached PCM/24-voice budget and guard world position. Muting returns only from sound playback; it cannot affect delivery. A cyan chest light and small depth-tested, camera-facing RADIO label appear on the transmitting guard only. No global guard-location message or permanent HUD is added. Native screenshot inspection caught overlap with the SECURITY sign; the label was offset beside the guard and inspected again.

Existing CSV telemetry adds `security_radio_started`, `security_radio_delivered`, `security_radio_cancelled` with JSON detail containing report/source/actor IDs, source deadlines, recipients, attempt and simulation time. Existing columns and CSV escaping remain unchanged. Start/finish emit once, not every frame. Old `shared=true` hearing calls are explicitly rejected, and nonfatal damage no longer calls the camera.

## SECURITY encounter evaluation

Tests instantiate the actual Deep Signal room and authored guards: SMG (24,0,38), patrol to (28,0,36); rifle (27,0,30), patrol to (24,0,28). No level or mission data was edited. Physics/rays, local decision functions, damage, pistol ballistics and audio nodes are real; most actor/controller processing is disabled so tests can drive exact deltas. These are scripted encounter measurements, not a human playthrough.

| Scenario | Actual fixture and result |
| --- | --- |
| A: uninterrupted | Player at (24,0,34), visible to SMG, behind rifle's initial patrol cone. At t=1.0s rifle still has no knowledge. At t=1.4s it receives A, becomes suspicious and produces an existing reachable investigation path; memory is 6.6s. |
| B: interrupted | Damage at .7s kills the transmitter, or a nonfatal hit applies .22s stagger. Neither delivers at 1.4s; partner remains unaware in isolated radio tests. An additional actual pistol scenario uses player (24,0,48.9), sender facing south at the original spawn: five shots at explicit .24s cadence incapacitate it before completion; rifle is >19m from gunfire and learns nothing. The first real hit cancels the report. |
| C: reposition | Begin report at A, advance .6s, move silently to B=(5,0,35). Real world rays confirm both guards cannot see B. Completion at 1.4s delivers A. Rifle cannot fire through occlusion; its magazine and player health remain unchanged. |

The long-range B scenario changes facing and player approach only in the fixture. It does not claim the default patrol already faces south. At close range a real shot can legitimately alert the rifle independently of a cancelled report. Normal patrol timing, player perception of cues, audible balance and encounter enjoyment still require human/browser playtesting.

## Executed validation and limits

`python scripts/run_godot_tests.py --godot <4.7.2-console-exe> --logs <temporary-log-directory>` now runs 18 programs using isolated writable profiles. Initial full regression ran 18/18 successfully; the expanded final radio suites were rerun separately. Latest local totals: **412 passing assertions plus orderly-close smoke**, including director 32/32, original integration 33/33, radio unit 37/37, radio integration 43/43, Deep Signal enemy 16/16 and unchanged remaining regression counts. Packaging tests: **10/10**. Two Phase 1 assertions that explicitly required the legacy shortcuts were replaced with stronger assertions that the same calls cannot change memory or fabricate evidence; other regression assertions were retained. Initial missing-API tests and fixture failures were corrected before these final results. A red same-tick callback-cancellation test also exposed and fixed a stale queue-iteration edge case; the cancelled report is now skipped before any delivery. No current failures are concealed. Godot import exits 0. Captured mouse remains explicitly skipped headlessly. Root certificate-store read errors are the known host diagnostic; no final game script errors are accepted.

Commands, using repository root PowerShell:

```powershell
$godotBin = 'C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$radioDir = Join-Path $env:TEMP 'bunker07-radio'
python scripts/run_godot_tests.py --godot $godotBin --logs (Join-Path $radioDir 'final-tests')
python -m unittest discover -s tests -p test_web_build.py -v
$env:APPDATA = Join-Path $radioDir 'graphical-appdata'
$env:BUNKER_RADIO_CAPTURE = Join-Path $radioDir 'screenshots'
& $godotBin --path godot --rendering-driver opengl3 --audio-driver Dummy --script res://tests/security_radio_integration_test.gd
```

Native graphical integration passed **43/43** using Compatibility/ANGLE on Adreno X1-85, with a captured/inspected warning frame. Audio assertions verify short spatial players/cue identities and mute independence; the dummy driver means **audible mix is not verified**. Raw logs/captures are in `$env:TEMP\bunker07-radio`, not Git.

A microbenchmark of 1000 controller/director updates with eight authored actor objects and one pending report measured roughly **18-22 us/update across the headless and graphical runs** on this host. It excludes full enemy physics/render cost and is not a measured FPS claim. Production does two ID lookups across eight enemies plus small bounded snapshot/queue scans, with no added geometry queries for radio. Active storage/queue/history and 1000-event observation stress are asserted. Session telemetry remains session-long as in the baseline; repeated legitimate sighting refreshes can generate repeated two-second warnings, so audible frequency should be playtested.

A complete local export succeeded with pinned Godot `4.7.2.stable.official.ed1daf0bf` and matching official nonthreaded templates, exit 0. Artifact validation passed for HTML, engine JS, WASM and packed resources, with the actual source SHA in `build-info.json`. The first committed candidate was `44e07533d322f426168d41945d86f3a5d0e8e239`; final documentation/test commits must be rebuilt, not relabeled. Local HTTP returned 200 for all manifest files with matching SHA256/byte sizes and `application/wasm` MIME. PCK was 665,664 bytes, WASM 39,514,754 bytes. These are artifact checks, not interactive browser proof. The same 18-program/export gate runs in the existing PR workflow; feature refs cannot deploy.

## Review and next phase

All code stays on the feature branch pending owner review. The existing PR workflow validates/exports/uploads, but cannot deploy the feature branch. Do not merge or deploy without a new explicit approval. Phase 3 may add reachable search assignments only after the open browser/audio/human gates are satisfied; broad squad radio, uncertainty tuning, forwarded provenance and coordinated movement remain separate future work.

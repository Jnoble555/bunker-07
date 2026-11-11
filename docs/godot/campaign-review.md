# Independent native campaign review

Scope: the Godot campaign expansion against the browser maps and behavior in `src/game.js`, `src/bunker-systems.js`, and `src/missions/`. The browser implementation and its existing tests remain the reference; native rendering and filesystem choices are intentionally platform-specific.

Review/test ownership was agreed in `campaign-plan.md` before implementation. The reviewer owns only `godot/tests/campaign_test.gd` and this record. Root integrates gameplay/UI/session state, with separate owners for world/enemy and device/audio code. No dedicated code-review skill is available in the session catalog, so review uses direct inspection plus an independently authored native physics harness.

## Executed status

The independent campaign test script passed Godot parser validation. After resuming checkpoint `d3c6aa0`, the reviewer freshly reran the combined native campaign suite: **51 checks, zero failures**, exit 0, on installed Godot 4.7.2 stable. It emitted no runtime or ObjectDB warning. Results are saved in `godot/tests/campaign-results.json`. This is executed native evidence, not an inference from saved M1/browser reports.

Root separately reports the retained M1 mechanics suite passed 46 checks after isolating new camera/lamp targets from the old guard-only scenarios. An earlier M1 exit warning named three audio playback/stream objects rather than leaked game nodes. Root diagnosed asynchronous mixer release, detached voice streams and cached resources explicitly, and allowed the event loop a short cleanup drain; its final verbose 46-check run exited cleanly. The reviewer inspected that shutdown path and independently executed `close_smoke.gd` with alarm/fire sound active: gameplay stopped and the process exited 0 with no runtime or ObjectDB warning. The root's actual window-close handler pauses gameplay and performs the same bounded drain while its timer remains active during pause.

## Harness coverage

The harness exercises real mission progression/objective gating, all three collision-driven mission routes, native enemy roles, camera tracking and walls/power, actual shootable-device hits and accuracy, bulkhead toggling/obstruction, one-use overload, provisional versus successfully committed optional rewards and consequences, retry reset, Blackout power/extraction, settings/journal pausing, persistence/reset, onboarding, S-rank results, and actual CSV export/escaping. It isolates enemy processing during route/device tests and separately enables turret combat; it does not claim a human campaign playthrough. Preferences and onboarding state are restored after the test.

## Source review

The port's mission data preserves reference maps, native coordinate conversion, initial roles, objectives and spawn locations. Device range/camera cone and timing, optional reward branches, success-only session commits, enemy timing and role properties were reviewed against browser constants. Combined implementation uses `campaign_main.gd` over the existing M1 shell, keeping shared movement/combat behavior available for regression checks.

Confirmed findings fixed before the passing campaign run:

- Opening settings through its public active-play entry point originally left simulation running behind the menu. It now pauses first, and closing settings preserves the paused encounter.
- Device/panel target IDs originally occupied CSV `detail` rather than the browser's `bot_id` field, and packed `id|detail` values were not separated. The adapter now preserves target/detail semantics; regression assertions cover service power, camera and alarm panel rows.
- Enemy-disable callbacks originally logged before the hit counter advanced. Successful shots now update cumulative hits before those callbacks; a real two-shot scout kill asserts the disabled row has the current count and one-based target ID.

One initial Blackout traversal assertion rejected the valid final `summary` menu because a shared helper accepted only `result`; the helper was corrected without changing valid gameplay. Duplicate device-use audio was also identified and root coordinated its removal.

Final combined source review includes post-checkpoint hit feedback, pausable impact tweens, role attack/step sound hooks, settings lifecycle, successful consequence commits, and CSV adapters. Physics queries consider nearest world/body/area hits and apply positive target-center depth before the nearest wall; enemy hits increment before disable callbacks. Audio voices are finite, capped and detached on retry; explicit exit shutdown was also inspected. No new functional blocker was found within this coverage.

The final source-only spot check also confirmed that mission journal notes now come from the authoritative encounter module once per attempt, and visible turrets rotate toward the player without changing their stationary movement, attack timing or damage. No new blocker was found in those presentation fixes; root owns the subsequent combined validation runs.

Browser runtime/test/style/index source diff against `af85238` was empty during final review. **No remaining blocking defect was found within the implemented and tested campaign scope.** This signoff is bounded by the checks and limits described here; it does not guarantee zero bugs or exact visual/audio equivalence to the browser. The 51-check run preceded the shutdown-only adjustment; that affected lifecycle path was separately inspected and verified by the independent close smoke test rather than claiming a redundant full campaign rerun.

## Limits

Deterministic tests cannot establish subjective visual/audio quality, a full manual mouse-capture playthrough, cross-platform behavior or long-session performance. Export writes a native file rather than a browser download. Audio is original synthesized PCM rather than an identical Web Audio graph. Final parity documentation should distinguish implemented behavior from these platform differences and any outstanding features.

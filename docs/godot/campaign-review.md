# Independent native campaign review

Scope: the Godot campaign expansion against the browser maps and behavior in `src/game.js`, `src/bunker-systems.js`, and `src/missions/`. The browser implementation and its existing tests remain the reference; native rendering and filesystem choices are intentionally platform-specific.

Review/test ownership was agreed in `campaign-plan.md` before implementation. The reviewer owns only `godot/tests/campaign_test.gd` and this record. Root integrates gameplay/UI/session state, with separate owners for world/enemy and device/audio code. No dedicated code-review skill is available in the session catalog, so review uses direct inspection plus an independently authored native physics harness.

## Executed status

The independent campaign test script passed Godot parser validation, then the combined native campaign run passed **51 checks, zero failures**, exit 0, on installed Godot 4.7.2 stable. Results are saved in `godot/tests/campaign-results.json`. This is a freshly executed native run, not an inference from saved M1/browser reports.

Root separately reports the retained M1 mechanics suite passed 46 checks after isolating new camera/lamp targets from the old guard-only scenarios. Root observed three ObjectDB instances reported leaked at M1 test exit; the campaign run reviewed here did not emit that warning. Its cause is **unresolved**, and no further long run was performed after the user's immediate pause/usage-limit request. Do not treat this checkpoint as final release approval.

## Harness coverage

The harness exercises real mission progression/objective gating, all three collision-driven mission routes, native enemy roles, camera tracking and walls/power, actual shootable-device hits and accuracy, bulkhead toggling/obstruction, one-use overload, provisional versus successfully committed optional rewards and consequences, retry reset, Blackout power/extraction, settings/journal pausing, persistence/reset, onboarding, S-rank results, and actual CSV export/escaping. It isolates enemy processing during route/device tests and separately enables turret combat; it does not claim a human campaign playthrough. Preferences and onboarding state are restored after the test.

## Source review

The port's mission data preserves reference maps, native coordinate conversion, initial roles, objectives and spawn locations. Device range/camera cone and timing, optional reward branches, success-only session commits, enemy timing and role properties were reviewed against browser constants. Combined implementation uses `campaign_main.gd` over the existing M1 shell, keeping shared movement/combat behavior available for regression checks.

Confirmed findings fixed before the passing campaign run:

- Opening settings through its public active-play entry point originally left simulation running behind the menu. It now pauses first, and closing settings preserves the paused encounter.
- Device/panel target IDs originally occupied CSV `detail` rather than the browser's `bot_id` field, and packed `id|detail` values were not separated. The adapter now preserves target/detail semantics; regression assertions cover service power, camera and alarm panel rows.
- Enemy-disable callbacks originally logged before the hit counter advanced. Successful shots now update cumulative hits before those callbacks; a real two-shot scout kill asserts the disabled row has the current count and one-based target ID.

One initial Blackout traversal assertion rejected the valid final `summary` menu because a shared helper accepted only `result`; the helper was corrected without changing valid gameplay. Duplicate device-use audio was also identified and root coordinated its removal.

No further gameplay blocker was found within inspected/tested coverage, but the exit-time ObjectDB warning above and final post-checkpoint integration review remain open. Browser runtime/test/style/index source diff was empty during review. The latest root feedback/audio tweaks made after the 51-check run have not been freshly certified by this reviewer.

## Limits

Deterministic tests cannot establish subjective visual/audio quality, a full manual mouse-capture playthrough, cross-platform behavior or long-session performance. Export writes a native file rather than a browser download. Audio is original synthesized PCM rather than an identical Web Audio graph. Final parity documentation should distinguish implemented behavior from these platform differences and any outstanding features.

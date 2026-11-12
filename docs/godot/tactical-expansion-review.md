# Independent tactical expansion review

Reviewed the combined working tree on `feature/tactical-pve-expansion`, based on `a6cd31c`. The reviewer read shared source without editing it. No dedicated code-review skill was available in the session catalog; review used direct source inspection and isolated Godot physics checks. This is a bounded review, not a claim that all gameplay or platform behavior is certified.

## Confirmed findings and disposition

1. **Operation completion could bypass its objectives.** The inherited `campaign_main.gd::_physics_process` treated an unknown mission ID like Breach: `remaining() == 0` unlocked extraction. Killing every operation enemy and approaching the lift could call `finish(true)` with service access/data incomplete. The integration owner changed the fallback to explicit Breach only and added a defensive objective-count guard in `operation_main.gd::finish`. Both source fixes were independently inspected. The owner added an all-enemies-dead/early-extraction regression and reports it passing in the combined graphical 23-check suite.
2. **Blocked enemies could fail to enter their yield behavior.** `tactical_enemy.gd::_physics_process` originally measured intended speed after `move_and_slide()`, which can zero velocity during a head-on collision. `_blocked_clock` could therefore remain zero and never activate the escape/repath branch. The enemy owner now captures intended speed before sliding and measures actual displacement afterward. The reviewer independently executed the added blocked-intent/yield checks as part of the passing 20-check enemy suite.
3. **Slot input was omitted by the campaign override.** The integration owner found that the existing campaign `_unhandled_input` omitted slots 1/2 despite parent bindings. Its production handler now includes slots 1/2/3, and the parent installs all three keys. Source was inspected independently. The integration test initially checked the first queued key before an idle frame had dispatched it; its helper now waits `process_frame` after press/release while retaining actual `Input.parse_input_event` dispatch and the original assertions. The owner reports all dispatched slot assertions passing in the combined graphical 23-check suite.
4. **Typed operation journal initialization was corrected by the integration owner.** The initial assignment of an untyped array to the typed journal was replaced with `clear()` and `session.note()`. The corrected source was inspected; this finding was supplied by the integration owner's runtime check rather than discovered independently by the reviewer.

## Independent execution

Using installed Godot `4.7.2.stable.official.ed1daf0bf` on Windows:

- `--headless --path godot --script res://tests/tactical_enemy_test.gd`: final **22/22 passed**, exit 0 with no engine errors. Includes reaction/windup, firing-time cover recheck, remembered-position search, reload/pause, reachable cover, limited ally sharing, friendly-body occlusion, nonstacking bodies, blocked-intent/yield, stagger, death, and actual operation ramp/stair traversal. This reruns and supersedes the earlier independent 20-check result.
- `--headless --path godot --script res://tests/shotgun_test.gd`: **14/14 passed**, exit 0. Includes individual pellet occlusion, partial cover, falloff, range, exclusions, precise zero-spread direction, inside-origin metadata, device areas and required model parts.
- `--headless --path godot --script res://tests/operation_level_test.gd`: **13/13 passed**, exit 0. Includes actual player traversal to service access, both archive approaches, elevation/stairs, extraction, the risk armory, reachable enemy/cover points and gate/navigation agreement. This was a fresh completed run; the earlier partial output whose process handle expired across the pause was not counted.

These isolated suites do not mutate campaign preferences or saved regression reports. Existing campaign/inventory/report-writing suites and full operation integration are owned and run by the integration owner to avoid concurrent state changes.

The integration owner separately reports `operation_integration_test.gd` **23/23 passed graphically**, exit 0 without engine errors, including the corrected objective guards, journal initialization and actual slot dispatch. The owner also reports integrated shotgun checks **7/7 passed**. These are owner-executed results, not additional independent executions by this reviewer.

The owner subsequently reports these final executions:

- Original Godot headless mechanics **46/46**, campaign **51/51**, inventory **16/16**, and movement **17/17** passed. The captured-mouse handler was explicitly skipped headlessly; the graphical movement suite then passed **18/18**, including the actual captured handler.
- Graphical operation menus **5/5** passed, including real button transitions between the original campaign and operation and original Breach deployment.
- Graphical operation live-combat checks **7/7** passed for windup, cover, reacquisition, reload and pause. This deliberately used one controlled stationary SMG enemy while the other ten enemies were frozen; it does not establish a complete unrestricted combat playthrough.
- `npm.cmd test` completed all browser suites with exit 0. The close smoke check exited 0, and the final Godot import completed without errors.

These final results are attributed to the integration owner. Only test capture/HUD synchronization changed after the reviewer's final gameplay-source inspection.

## Source assessment

- Shotgun physics resolves each pellet against its nearest world/body/device surface. The integration uses each pellet's attenuated `damage`; impact-only or zero-damage pellets do not earn a hit. `counted_hit` permits at most one accuracy hit per trigger and is incremented before actor damage, preserving defeat-event counters. A dead registered actor does not receive repeated damage credit.
- Magazine/reserve values remain independent per owned weapon. Ammo moves only on reload completion; switching cancels the timer, preserves both ammo states and retains shot cooldown. Pickups require eye-distance and world line-of-sight, become taken once, and are rebuilt on retry. The operation's pickups and objective state are rebuilt together.
- Enemy perception uses actual player eye position and world occlusion. Hidden search follows remembered positions rather than continuously reading the hidden player's destination. Contacts are shared only with nearby visible allies and are rate limited. Every enemy round rechecks world/friendly-body visibility before damage, and finite magazines/reserves govern reloads.
- Operation geometry and navigation share obstacle footprints and authored terrain heights. The graph rejects blocked/outside destinations, does not fall back to direct movement for unreachable targets, and represents the ramp/stairs. Physical enemy bodies and steering/yielding supplement static navigation; this is not a guarantee against every crowd configuration.
- Enemy stair stepping sweeps the full capsule upward by at most 0.26 m, checks a raised forward tread probe, and requires a downward landing with an upward-facing normal before changing height. A 0.12-second grace period bridges riser corners and restores normal floor snapping when it expires; gameplay pause stops that timer. Full-height walls fail the upward/forward clearance tests. This is bounded step assistance rather than an unchecked vertical teleport.
- The operation has its own controller and success path. Archive interaction checks elevation, reach and intervening geometry; terminal rays may end on the intended housing's metadata but cannot ignore unrelated cover. Existing campaign enemy configuration remains separate.

## Verification limits and remaining work

The corrected integration, dispatched slot checks, original-campaign regressions and controlled live-combat checks have owner-reported passing results above. No additional blocking issue is currently confirmed from this bounded source review and its isolated tests; this does not certify absence of bugs outside their coverage.

The reviewer has not completed a human mouse-driven operation, measured its 10–15 minute design target, audited subjective sound/aiming feel, or stress-tested all crowded doorway/elevation combinations. Route suites isolate combat where stated; they must not be described as a full human combat playthrough. Other drivers/window sizes and prolonged performance remain manual checks.

Checkpoint save/resume and true sight alignment are deferred stretch features in this milestone. No save UI or half-working resume path is present to review. Existing aiming zoom must continue to be described as zoom rather than verified sight alignment.

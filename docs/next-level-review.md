# Independent expansion review

Reviewed the reactive bunker changes on 2026-11-11. This review covered the new systems module, integration hooks in the main game, role-based combat, procedural art references, sound cleanup/failure handling, grouped sprite clipping, and horizontal-surface rendering changes.

## Findings resolved

- The initial systems module requested two missing prop names, causing the broken light and cache art to disappear silently. Canonical names and compatibility aliases now resolve; tests assert that all emitted prop assets exist.
- Persistent equipment status initially replaced the player's mission objective. Integration now appends contextual equipment information, preserving the core/extraction goal.
- Tactical shots at cameras/lights initially consumed ammunition without rewarding accuracy. Device hits now increment the hit count and show feedback; a regression check covers the actual shooting path.

No remaining blocking defect was found in this review. This statement is bounded by the checks below and does not guarantee all possible behavior.

## Independent browser checks

Run `node tests/next-level-test.cjs` with installed Windows Chrome (or set `CHROME_PATH`). The server uses an ephemeral localhost port and closes its browser/server after success or failure.

The latest run passed 53 checks with no JavaScript page errors. It tests:

- Camera detection, walls preventing detection, disabling and destroying the camera, and wall/enemy occlusion of device shots.
- Guard patrol and last-heard investigation, role assignments, armored stagger/damage, stationary ranged turret attacks, attacker direction feedback and windup cancellation behind a wall.
- Service-power lighting tradeoff, shootable lamps, bulkhead collision/ray blocking and obstruction protection, overload stagger/attack cancellation, one-use cache rewards and optional intel's alarm risk.
- Successful versus failed consequence commits, security shutdown disabling the later turret, alarms adding armored opposition, fresh-campaign reset and mission retry state.
- S-rank scoring for a fast accurate optional stealth run, result summaries and field-log entries.
- Actual collision/update traversal through the complete optional maintenance route with all rewards and through the direct alarm route to extraction.
- Real browser keyboard/menu interaction for J → field log → back → resume, plus role/prop render smoke checks.
- Pixel assertions for grouped billboard clipping: a nearer-wall stripe remains unpainted, an adjacent visible stripe is painted, and the clip does not leak into subsequent drawing.

Many gameplay checks advance the real game functions deterministically; they are not a full human campaign playthrough. Pointer capture is stubbed for UI tests. The existing browser suite separately covers baseline campaign/settings/input/CSV behavior.

## Visual evidence

Screenshots were inspected for silhouette/material continuity, equipment visibility, depth clipping and journal readability:

- [Service terminals](screenshots/next-level-maintenance.png)
- [Armored guard](screenshots/next-level-armored.png)
- [Ranged turret](screenshots/next-level-turret.png)
- [Field log](screenshots/next-level-journal.png)

The renderer remains a flat single-height raycaster. Bulkheads toggle full grid-cell collision and wall visibility; these are not sliding geometric doors. Props/effects remain billboards with wall-depth clipping. The new horizontal floor/ceiling pass shares symmetric world samples and interpolates across rows; this is consistent with planar surfaces. Real shadows, stairs and multiple floor levels remain unsupported.

Remaining coverage limits: other browsers/devices, audible subjective balance, a complete manual pointer-lock campaign, and prolonged performance testing. The primary agent owns final integration, the full test run and publication.

# Reactive encounter systems

`bunker-systems.js` is original project code. It has no asset downloads or third-party runtime dependencies. Root integration owns combat damage, renderer changes, UI, and campaign menu wiring; this module owns device state and security patrol behavior.

## Playable additions

Control Room includes a scanning camera in the direct hall and a slow armored guard that patrols and investigates gunshots. The camera requires 1.25 seconds of visible tracking inside its scan cone to call the existing alarm and single reinforcement. The maintenance service terminal toggles camera power at the cost of reduced service lighting. The alarm panel also prevents camera detection. Shooting the camera disables it; shooting the service lamp dims its region. Device hits respect both wall depth and nearer enemy depth.

The maintenance bulkhead switch opens/closes the tile at `(8,6)`, affecting collision, ray visibility and shots through the shared wall callback. The switch refuses to close on the player or a living enemy. The bulkhead begins open and can always be reopened from its switch; the direct route provides another connection. The overload terminal can stagger visible security units within four tiles for three seconds once per attempt.

An optional evacuation manifest near the data core triggers the alarm unless the alarm panel has been disabled. It is preserved only if the player extracts successfully. The side alcove behind maintenance holds a hidden cache with a one-time 25-health recovery capped at 100 and a story entry. `J` is provided by root integration to read the module's current mission journal.

Enemy role data differentiates fast lightly armored scouts, slow stronger armored units, and stationary ranged turrets. Root combat reads the role fields. Successful quiet panel shutdown disables the Blackout turret; a Control Room alarm instead deploys an additional armored pursuit unit. Recovered intel supplies a later mission clue. Failed attempts do not commit those consequences, and a new campaign clears them.

Successful results show rank, clean/combat status, active time, accuracy, and Control Room optional finds. Rank points reward a clean run (two), under 120 seconds (one), at least 60% accuracy (one), intel (one), and secret (one): S at five points, A at four, B at two, otherwise C. With no shots fired, accuracy is treated as 100% for the rank. Control Room clean status means no alarm; other missions use full health. These are local replay goals, not online leaderboards.

## Integration API

`window.Bunker07Systems.create(api)` returns `reset`, `update(dt)`, `noise(x,y)`, `interact`, `shoot(dx,dy,wallDepth,nearestBotDepth)`, `objects`, `light(x,y)`, `isWall(x,y)`, `prompt`, `entries`, `finish(won)`, `summary(won)`, and `newCampaign`.

- `api.state()` supplies current `mission`, `player`, `enemies`, `map`, `mode`, `time`, `alarmTriggered`, `panelDisabled`, `shots`, and `hits`.
- `api.move`, `api.ray`, `api.log`, `api.triggerAlarm`, and optional `api.message` connect to the actual game. The module does not replace combat or apply damage itself.
- Call `reset` after the root reset, `update` before combat, `noise` once per fired shot, and `shoot` before damaging a possible enemy. A device consumes the shot only when it is nearer than both the wall and enemy target.
- Call `interact` before the original panel interaction. It consumes E only for a visible device within 0.8 tile. The original alarm panel occupies a separate position.
- Root respects `bot.stagger`, preserves patrol-set `bot.moving`, and reads `speed`, `attackRange`, `damage`, `role`, `facing`. Guards retain the existing unalerted combat gate. `update` fills role data for new reinforcements.
- Merge `objects()` with the existing far-to-near depth-clipped scene path. Props use `camera`, `cameraOff`, `lampBroken`, `crate`, `terminal`, `intel`, `damagedRack`, `console`, and `lamp` art keys. `light` is a cheap multiplier for existing simulated lighting; no real shadows or geometry beyond the bulkhead are implied.
- Call `finish(won)` before `summary(won)` and before leaving the mission state; results are idempotent. `newCampaign` clears committed decisions, while retries call only `reset`.

Public read-only fixture coordinates are in `systems.data`; `systems.current` provides attempt state and `systems.campaign` committed decisions for deterministic integration tests. Public state is exposed for testing, not browser storage. Campaign choices intentionally last only for the running campaign/session.

`api.sound('detect',x,y)` plays a positional camera acquisition cue; `api.impact(x,y,'spark')` adds device-hit feedback. Successful mission journal entries remain readable during subsequent missions; failed-attempt entries are discarded on retry.

# GHOST PROTOCOL Phase 3 coordinated search

Deep Signal’s authored SECURITY pair can coordinate a search after the recipient accepts a delivered visual radio report. Before Phase 3, the recipient used its normal local investigation while the sender made its own decisions independently. With Phase 3, one guard can check the reported area while the other covers a separate approach. The original 1.4-second radio delay, combat mechanics, room geometry, spawns and patrols are intact.

## Ownership and information flow

The mission owns a value-only Security Director. Once Phase 2 delivers a report, the controller checks actor identity, attempt, life, interruption and radio range, then calls the receiver’s existing evidence-priority check. The director looks up the delivered report in its own recipient knowledge. Sound events have no entry point into this flow.

The incident ID is the source report ID within an attempt. The director retains one active incident, its original sighting evidence, an absolute deadline and up to two role records. Each role record reserves its own destination and contains the checked path, role, guard ID, start, arrival status and deadline. Incident queries and signals return copies. The director invokes the controller’s planning callback synchronously and keeps no actor, player, room or callback references. Its normal simulation update checks expiry, actor membership and dwell without generating paths.

The recipient is the first investigator candidate. The sender is the first holder candidate. If the recipient cannot investigate, the sender may investigate and the recipient may hold. A guard with current local visual contact, hit stagger or invalid membership is unavailable. The controller uses the most recent result from normal actor perception. Actor physics checks real visibility again before executing either assignment.

A monotonically increasing sight-episode number per guard distinguishes a fresh acquisition from one-second refreshes. Only one report from an episode can be considered for coordination. An active incident can be superseded only by a newer delivered sighting at least 3 m away that yields a valid plan. Incidents and their original deadlines cannot be renewed by duplicate reports. Existing Phase 2 evidence handling continues independently.

## Positions and execution

- **Investigator** considers the sighting projected onto the authored walk surface and eight nearby points within about 2.12 m. It follows the selected path, then sweeps its view around the evidence for 1.2 simulation seconds.
- **Holder** considers up to six authored cover offsets between 2.7 and 8 m from the sighting, and its current ground position as fallback. Valid cover outranks a valid current position. The holder faces the reported approach on arrival.
- Both roles reject nonfinite or blocked endpoints, destinations within 1.35 m of the partner’s current position, reservations within 2.2 m, elevation mismatches and over-budget routes. The level uses its existing AStar links and checks both off-grid connectors in 0.24 m samples for clearance and height. Travel budgets use the existing rifle and SMG speeds and reserve time for dwell.
- The investigation score weights route length and distance to the sighting. The hold score weights route length and closeness to a 4.5 m standoff. Candidates tie by stable index. Investigator selection draws among at most the best three from a private Godot RNG seeded with `attempt_id * 1000003 + observation_id * 97 + report_id`. Equal ordered events, actor positions and geometry reproduce choices on the tested engine. The weapon RNG is independent.
- Planning issues at most 25 candidate path requests in the role-reversal case and at most 16 with preferred roles. Accepted assignments seed the existing movement cache. Route recovery uses the original stuck handling with the same search path validation. Invalid recovery cancels the role.
- Each actor still owns combat, firing rays, reload, stagger, collisions and movement. An assigned actor that sees the player abandons its role immediately and uses local combat. A hit also abandons the role. Required reload pauses movement within the original deadline. Holder loss releases that reservation and the investigator continues. Investigator loss releases the whole incident.
- The absolute deadline is the earlier of 6.5 simulation seconds after assignment and the original evidence expiry. Arrival tolerance is 0.65 m. Investigator dwell or timeout releases all remaining reservations. Completion clears the exhausted, matching visual memory while preserving independent local evidence. Retry, title, mission result and teardown clear the director and actor assignments. Pause, journal and settings freeze the simulation.
- Guard-local, depth-tested SEARCH, HOLD and brief CLEAR labels complement the existing cyan RADIO and delivered chirp. The holder lowers its weapon slightly while holding. Mute affects playback only.

Telemetry uses the existing structured CSV path. `security_search_started`, `assigned`, `arrived`, `released`, `completed` and `cancelled` events include attempt, source observation and report IDs, reason, deadline and simulation time. Guard events include the role and destination.

## Recorded encounters

The dedicated suite instantiates the actual Deep Signal room and actors. It uses real navigation, collision, sight, firing and hit handling with explicit simulation steps. Player test positions and seed are controlled.

| Encounter | Recorded outcome |
| --- | --- |
| A — Coordinated delivery | SMG sees (24, 1.4, 34). Delivery at 1.4 s creates incident 1. The rifle investigates (24, 0, 32.5) over a 7.21 m graph route. The SMG holds the authored offset (27, 0, 36.5) over a 5.21 m route. There are two distinct reservations and 13 initial path requests. |
| B — Silent escape | The partition occludes (5, 0, 35) for both assigned guards. Both arrive in their respective roles without a shot through the wall. Repeating with the same attempt seed and hidden position (6, 0, 35) produces the same paths. |
| C — Interruption | Killing the SMG at 0.7 s cancels report 1 with reason `death`. The rifle retains no sighting or assignment. The existing radio suite separately exercises a real five-shot interruption and legitimate hearing. |
| D — De-escalation | The holder arrives at about 2.69 s and the investigator at about 4.18 s. Incident 1 completes at about 5.39 s with `area_checked`. Both reservations clear and patrol resumes. A separate reload case verifies that expiry clears suspended roles. |
| E — Reacquisition | The rifle directly sees (25, 1.4, 26), clears its assignment and begins local combat reaction. The SMG retains A until report 2 delivers at 2.8 s, at which point incident 2 assigns a solo SMG investigator because the rifle is busy. |

## Validation and limits

Pinned Godot 4.7.2.stable, Compatibility renderer, Linux x86-64, AMD EPYC 9V74. The headless scripted run measured 2.54 ms for initial radio delivery including planning and cue handling, with 13 candidate path requests. A thousand active updates with eight actors in the scene averaged 12.37 µs with a p95 of 15 µs for actor synchronization plus director update. Across 238 sampled 60 Hz ticks, the eight guard physics callbacks plus director update took 1.28 ms p95 and 4.20 ms maximum. These microbenchmarks exclude rendering, player callbacks and engine frame scheduling. The prior radio-only baseline measured about 10 µs per controller/director tick with a pending report.

| Gate | Result |
| --- | --- |
| Phase 2 baseline on pinned Godot | 18/18 programs passed |
| Phase 3 regression runner on pinned Godot | 19/19 programs passed, including 37/37 coordinated search checks and all unchanged Phase 2 radio checks |
| Packaging | 10/10 tests passed |
| Web export | The pinned release pipeline exported and validated the feature commit and asset manifest |
| Browser | Shared Chrome returned `ERR_CONNECTION_REFUSED` for the local feature build. Interactive gameplay in the export remains unverified. |
| Native graphics and real audio | Godot could not open X11 or Wayland from the execution environment. ALSA found no sound card and fell back to the dummy driver. |

Human escape, repositioning, perceived readability and the audio mix remain playtest questions. Phase 4 should start with that evaluation and adjust the SECURITY encounter based on player reactions before expanding coordination scope.

# Godot campaign parity

The browser source remains the behavioral reference. M1 was planned and implemented first at `7bcfac1`; its pre-implementation contract and validation are preserved in Git history and [verification.md](verification.md). The campaign contract was agreed before independent work in [campaign-plan.md](campaign-plan.md).

**Current status:** all three campaign missions and the listed gameplay systems are implemented. This is a native campaign preview with explicitly bounded verification, not identical rendering/audio or complete platform certification.

| Area | Implemented and exercised | Remaining limits |
| --- | --- | --- |
| Movement/aim | Normalized reference speed, wall collision, mouse/arrow yaw, sensitivity preferences, horizontal FOV | No gamepad/mobile input; no jump/pitch, matching reference |
| Weapon/combat | Eight rounds, .24s cooldown, .8s reload, wall/target hit precedence, .28-tile enemy shot tolerance, windup/stagger/cancellation, recoil/flash/sparks/hit/damage feedback | Native collision volume edge behavior and visual effects differ from 2D rendering |
| Security/enemies | Armored/scout/turret roles, guard patrol/investigation, camera sweep/cone/LOS/tracking, single reinforcement | No full human combat campaign or long-session performance certification |
| Devices | Shootable camera/lamp, power-camera-light tradeoff, live bulkhead collision/LOS and actor obstruction, one-use LOS overload | Bulkhead toggles a full grid cell instantly, as reference; no sliding animation |
| Objectives | All reference maps/spawns, Breach bot gate, Control Room alarm/core/gate/extraction, Blackout power/extraction | No native binary/web export produced |
| Optional/campaign | Intel risk, one-use cache, journal, ranks, retries; consequences commit only after success and affect Blackout | Campaign progress remains session-only, matching reference |
| Menus/settings | Title/controls/briefings/deploy/pause/journal/settings/confirm-return/results/continue/final summary; preferences and onboarding persist | UI layout is native, not pixel-identical HTML |
| Analytics | Browser CSV schema, cumulative counts, target/detail semantics, mission IDs and actual native file export | Native user-data file export instead of browser download; extra debug events may appear |
| Presentation/audio | Original 3D rooms/materials/lights/roles/weapon/effects; spatial generated audio; pause and orderly shutdown | Original synthesized PCM differs from Web Audio graph; subjective mix quality and other hardware remain unverified |

## Verification boundaries

46 retained mechanic checks and 51 independently authored campaign checks execute real Godot physics. Route tests isolate enemies; separate checks enable combat/detection. Rendered smoke captures use scripted transitions for views and validate actual Blackout power use and summary, not human completion times. The exit cleanup regression has a separate active-audio close test.

See [campaign-release.md](campaign-release.md) for exact commands, final outcomes, original asset provenance and current release status. Browser code/tests/styles/entry page are unchanged by this migration. There are no known blocking defects within tested scope; that is not a guarantee of zero bugs.

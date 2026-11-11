# Bunker 07

An **in-progress Godot campaign port** is available in [`godot/`](godot/README.md). The browser version below remains the behavioral reference. See the [current campaign checkpoint](docs/godot/campaign-checkpoint.md); the [M1 checklist](docs/godot/parity.md) and [M1 verification](docs/godot/verification.md) describe the earlier Control Room milestone.

### [▶ Play Bunker 07 in your browser](https://jnoble555.github.io/bunker-07/)

**No download or installation required.** Open the game in a desktop browser and choose **Start Campaign**.

A Wolfenstein 3D-inspired browser FPS built with OpenAI Codex for a Web Analytics class. The original map and security bots are drawn in JavaScript using Canvas 2D.

## Play

**[Launch the hosted game →](https://jnoble555.github.io/bunker-07/)**

Start Campaign opens a short mission briefing before deployment. Breach introduces combat, Control Room offers the guarded direct and longer maintenance routes, and Blackout asks you to restore power and reach the extraction lift.

To play offline, download or clone this repository and open `index.html` in a desktop browser. The local version requires no installation, network access, or build step.

| Control | Action |
| --- | --- |
| WASD or up/down arrows | Move |
| Mouse or left/right arrows | Aim |
| Click or Space | Fire |
| R | Reload |
| E | Use a nearby panel to disable/silence the alarm or restore power |
| J | Open the field log (pauses play) |
| P or Esc | Pause |

The title screen includes **Controls** and **Settings**. Settings adjusts master volume, mute, and mouse sensitivity; **Reset to defaults** restores the original values. Preferences are saved in browser storage when available. Gameplay remains playable if storage or browser audio is unavailable. The pause menu provides Resume, Settings, and a confirmed Return to title action.

First-time Breach prompts teach movement, aiming, firing, and reloading. A nearby panel or switch displays its E interaction prompt. In Control Room, break the guard's line of sight during the warning to avoid detection, or use the maintenance route to reach the alarm panel. Disabling the panel after the alarm sounds silences it but does not remove a reinforcement already deployed. Surviving bots do not block extraction.

## Gameplay analytics

Use **Export session CSV** below the game or on a results screen to download events for all attempts since the page loaded. The export retains the existing columns and appends `detail` and `mission_id`; group rows by `run` and mission ID to distinguish retries, routes, and outcomes. Route entry, alarm trigger/disable, reinforcement spawn, core/power objectives, combat, and mission results are recorded. Starting a new campaign preserves the session log; refreshing the page clears it.

To analyze the CSV, group events by run. Use the final cumulative shots and hits to calculate accuracy and compare active play time for completed runs. Treat runs without a win or loss as incomplete.

## Build on it

The entry page is `index.html`. Gameplay, rendering and menus are in `src/game.js`, encounter systems are in `src/bunker-systems.js`, and mission definitions are in `src/missions/`. Original procedural art and synthesized sound are in `src/bunker-art.js` and `src/audio.js`. Styles are in `styles/game.css`. These load locally without a build step. Maps are grids of walls and open tiles. The raycasting function finds wall intersections, the update loop handles gameplay, and the renderer draws the scene.

```text
bunker-07/
├── index.html               # Browser / GitHub Pages entry point
├── src/                     # Game code, art and audio
│   └── missions/            # Mission definitions
├── styles/                  # Game and menu styles
├── tests/                   # Browser checks
│   └── fixtures/            # Before-upgrade comparison page
├── docs/                    # Research, reports and test results
│   └── screenshots/         # Visual evidence
├── package.json             # Optional development test commands
└── README.md
```

- [ ] Playtest mouse capture, settings persistence, and CSV export in additional desktop browsers.
- [x] Browser-test campaign progression, retries, and mission CSV analytics in Chrome on Windows.
- [ ] Validate across additional browsers and storage-restricted environments.
- [ ] Display accuracy and completion times across attempts.

There is no build step. Use a desktop browser for the full first-person experience; an optional browser test harness is described below.

## Control Room visual upgrade

The industrial art, renderer constraints, applied Lode / Level Design Book techniques, before-and-after screenshots and browser verification are documented in [the upgrade report](docs/control-room-upgrade.md). All new visual assets are original procedural drawings; see [asset provenance](docs/assets.md). The optional development browser harness runs with `npm install` and `npm test` (Windows Chrome); playing the game needs neither.

## Reactive bunker encounters

Control Room now has a scanning camera, an armored patrol that investigates shots, and a fast scout reinforcement. Shoot the camera or service lamp, reroute maintenance power to blind surveillance at the cost of lighting, operate the bulkhead, or overload the grid once to stagger nearby visible enemies. Aim at a device's horizontal position; the renderer has no vertical aiming. Press E at the separate alarm panel to prevent/silence the alarm. Nearby devices show an E prompt while the mission objective remains visible.

The archive near the core holds optional intel: taking it triggers security unless the alarm panel is disabled. Search the maintenance alcove for a one-use medical cache and recovered log. Use J or the pause menu to read transmissions. Intel, secrets, active time, accuracy and stealth contribute to local result ranks; there is no online leaderboard. Camera and lamp hits count toward accuracy.

Extracting after a quiet panel shutdown disables Blackout's stationary ranged turret. An alarm instead adds an armored pursuer. Recovered intel supplies a later clue. These consequences commit only on successful extraction; failed attempts reset devices and provisional rewards. Start Campaign clears prior campaign decisions while preserving the current session CSV.

New impact sparks, enemy stagger, damage-direction cues and positional synthesized audio reinforce combat. All visual/audio assets are original. Implementation details, limits and verification are in [the expansion report](docs/next-level-release.md), [systems documentation](docs/encounter-systems.md), and [art/audio provenance](docs/feedback-assets.md). `npm test` runs both the existing campaign checks and the independently authored encounter suite.

# Bunker 07

A Wolfenstein 3D-inspired browser FPS built with OpenAI Codex for a Web Analytics class. The original map and security bots are drawn in JavaScript using Canvas 2D.

## Play locally

Double-click `index.html` (or open it in a current desktop browser) and choose **Start Campaign**. No installation, network access, or build step is required. Start Campaign opens a short mission briefing before deployment. Breach introduces combat, Control Room offers the guarded direct and longer maintenance routes, and Blackout asks you to restore power and reach the extraction lift.

| Control | Action |
| --- | --- |
| WASD or up/down arrows | Move |
| Mouse or left/right arrows | Aim |
| Click or Space | Fire |
| R | Reload |
| E | Use a nearby panel to disable/silence the alarm or restore power |
| P or Esc | Pause |

The title screen includes **Controls** and **Settings**. Settings adjusts master volume, mute, and mouse sensitivity; **Reset to defaults** restores the original values. Preferences are saved in browser storage when available. Gameplay remains playable if storage or browser audio is unavailable. The pause menu provides Resume, Settings, and a confirmed Return to title action.

First-time Breach prompts teach movement, aiming, firing, and reloading. A nearby panel or switch displays its E interaction prompt. In Control Room, break the guard's line of sight during the warning to avoid detection, or use the maintenance route to reach the alarm panel. Disabling the panel after the alarm sounds silences it but does not remove a reinforcement already deployed. Surviving bots do not block extraction.

## Gameplay analytics

Use **Export session CSV** below the game or on a results screen to download events for all attempts since the page loaded. The export retains the existing columns and appends `detail` and `mission_id`; group rows by `run` and mission ID to distinguish retries, routes, and outcomes. Route entry, alarm trigger/disable, reinforcement spawn, core/power objectives, combat, and mission results are recorded. Starting a new campaign preserves the session log; refreshing the page clears it.

To analyze the CSV, group events by run. Use the final cumulative shots and hits to calculate accuracy and compare active play time for completed runs. Treat runs without a win or loss as incomplete.

## Build on it

Gameplay and menus are in `index.html`; mission definitions are in `breach-mission.js` and `blackout-mission.js`, and optional synthesized sound effects are in `audio.js`. These load locally without a build step. Maps are grids of walls and open tiles. The raycasting function finds wall intersections, the update loop handles gameplay, and the renderer draws the scene.

- [ ] Playtest mouse capture, settings persistence, and CSV export in additional desktop browsers.
- [x] Browser-test campaign progression, retries, and mission CSV analytics in Chrome on Windows.
- [ ] Validate across additional browsers and storage-restricted environments.
- [ ] Display accuracy and completion times across attempts.

There is no build step. Use a desktop browser for the full first-person experience; an optional browser test harness is described below.

## Control Room visual upgrade

The industrial art, renderer constraints, applied Lode / Level Design Book techniques, before-and-after screenshots and browser verification are documented in [the upgrade report](docs/control-room-upgrade.md). All new visual assets are original procedural drawings; see [asset provenance](docs/assets.md). The optional development browser harness runs with `npm install` and `npm test` (Windows Chrome); playing the game needs neither.

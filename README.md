# Bunker 07

A Wolfenstein 3D-inspired browser FPS built with OpenAI Codex for a Web Analytics class. The original map and security bots are drawn in JavaScript using Canvas 2D.

## Play locally

Clone the repo or download the ZIP from GitHub. Open `index.html` in Chrome or Edge and select **Start mission**. No installation or server is required. Disable three bots and reach the green exit beacon.

| Control | Action |
| --- | --- |
| WASD | Move |
| Mouse or left/right arrows | Aim |
| Click or Space | Fire |
| R | Reload |
| P or Esc | Pause |

## Gameplay analytics

**Export session CSV** saves events for all attempts since the page loaded. The game records start, shots, disabled bots, reloads, damage, wins, and losses in browser memory. Refreshing clears the log.

To analyze the CSV, group events by run. Use the final cumulative shots and hits to calculate accuracy and compare active play time for completed runs. Treat runs without a win or loss as incomplete.

## Build on it

All source is in `index.html`. The map is a grid of walls and open tiles. The raycasting function finds wall intersections, the update loop handles gameplay, and the renderer draws the scene.

- [ ] Playtest mouse capture, collisions, and CSV export in a desktop browser.
- [ ] Add sound effects and clearer hit feedback.
- [ ] Add another map and a difficulty selector.
- [ ] Display accuracy and completion times across attempts.

Initial JavaScript smoke tests covered raycasting, shooting, victory, defeat, pause, and restart. Full browser playtesting is pending.

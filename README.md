# Bunker 07

[Project documentation guide](docs/README.md) — current setup, systems, historical reports and repository layout.

A first-person tactical game built with **Godot 4.7.2**, developed with OpenAI Codex for a Web Analytics class.

**[Play in your browser](https://jnoble555.github.io/bunker-07/)** · [Controls and local setup](godot/README.md) · [Build identity](https://jnoble555.github.io/bunker-07/build-info.json)

## Start the demo

**[Download the polished Windows desktop demo](https://github.com/Jnoble555/bunker-07/releases/latest/download/Bunker07-DeepSignal-Windows.zip)** — extract the ZIP and run **Bunker07.exe**. No Godot installation needed. This build starts the desktop Deep Signal visual showcase directly. Windows x64; modern Vulkan-capable graphics required. See [release details](https://github.com/Jnoble555/bunker-07/releases/latest). The executable is unsigned.

1. Open the game in a desktop browser.
2. Choose **Deep Signal / Tactical Operation**, read the briefing, and deploy.
3. Restore SECURITY access at the amber terminal, recover the OPERATIONS archive up the striped ramp, and extract at the northeast lift.

Take the west MAINTENANCE route to avoid the direct security lane. An SMG and ammunition are available near the entrance. The southeast ARMORY holds an optional shotgun.

## Controls

| Input | Action |
| --- | --- |
| WASD | Move |
| Mouse | Look |
| Left click / Space | Fire |
| Right mouse, held / Z, toggle | Aim; pistol iron sights |
| C in browser / Ctrl on desktop, held | Crouch |
| Shift, held / Caps Lock, toggle | Sprint |
| Q / E | Lean left / right; hold by default, toggle option in Settings |
| F | Interact or collect supplies |
| R | Reload |
| 1 / 2 / 3 | Select owned pistol / SMG / shotgun |
| Esc / P | Pause |
| F5 | Retry |
| J | Field journal |

Aim slows movement and mouse look. Cover blocks sight and shots. A green hit marker confirms a target hit; a brief amber dot indicates a surface impact. Break line of sight during a guard's attack warning, then reposition.

For a trackpad, press **Z** to aim, move the trackpad to look, and press **Space** to fire. Press Z again to lower the sights. **Caps Lock** toggles sprint. Enable **Toggle Q/E lean (trackpad)** in Settings to lean with a tap. Tap the same lean key to return upright, or the opposite key to switch sides. Pause, focus loss, and retry clear the toggles. Sprint pauses while aiming and resumes when you lower the sights.

## What is included

- **Deep Signal** — a standalone operation with alternate approaches, supplies, elevated objectives, and eight guards. The initial SECURITY pair can coordinate a search after a delayed radio report.
- **Original campaign** — Breach, Control Room, and Blackout, with security devices, optional objectives, and consequences between missions.
- **Iron Relay** — a separate tactical operation with patrols, an elevated archive, and a collectible shotgun.
- **Session analytics** — export CSV events to examine accuracy, active play time, route choices, objectives, and retries.

Deep Signal is a compact playable prototype. Its 10–15 minute target is a design goal. The current route has not been validated against that duration.

## Run locally

Install **Godot 4.7.2 stable**, import `godot/project.godot`, and press **F5**. The project uses the Compatibility renderer.

From the repository root, with the matching engine on your PATH:

```bash
godot --path godot
```

The hosted site is built from this Godot project by GitHub Actions. Its `build-info.json` records the deployed commit and resource hashes.

## Repository guide

| Location | Contents |
| --- | --- |
| `godot/scripts/` | Player controls, missions, combat, AI, menus, and analytics |
| `godot/scenes/` | Game entry point and reusable scenes |
| `godot/tests/` | Godot regression programs |
| `scripts/` | Test runner, web export, and artifact validation |
| `tests/` | Packaging checks and legacy browser tests |
| `docs/godot/` | Architecture, verification, screenshots, and development reports |
| `assets/source/` | Original art source and provenance |
| `src/`, `styles/`, `classic.html` | Original JavaScript edition |

The [classic JavaScript game](https://jnoble555.github.io/bunker-07/classic.html) is also playable. Its controls and implementation differ from the Godot edition.

## Development checks

```bash
godot --headless --path godot --editor --import --quit
python scripts/run_godot_tests.py --godot godot --logs /tmp/bunker-tests
python -m unittest discover -s tests -p test_web_build.py -v
```

See the [web release procedure](docs/godot/web-release.md) for clean-commit exports and deployment validation. Historical reports under `docs/` describe the build and verification state at the time they were written.

## Project notes

- [Coordinated search behavior](docs/godot/ghost-protocol-search.md)
- [AI architecture](docs/godot/ghost-protocol-architecture.md)
- [Weapon inventory](docs/godot/weapon-inventory.md)
- [Desktop visual benchmark](docs/godot/deep-signal-visual-benchmark.md)
- [Original art and audio](docs/assets.md)

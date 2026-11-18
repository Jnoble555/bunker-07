# Documentation guide

## Playing and building the current game

- [Repository README](../README.md): desktop download, browser link, controls and demo route.
- [Godot setup](../godot/README.md): editor launch, source layout and campaign behavior.
- [Desktop release instructions](godot/DESKTOP-DEMO.txt): standalone Windows package.
- [Web release](godot/web-release.md): browser packaging and deployment.
- [Deep Signal visual showcase](godot/deep-signal-visual-benchmark.md): art direction, captures and measured limitations.
- [Deep Signal](godot/deep-signal.md) and [Iron Relay](godot/tactical-pve-expansion.md): operation details.

## Systems and assets

- [Encounter systems](encounter-systems.md): reactive devices and security behavior.
- [Security architecture](godot/ghost-protocol-architecture.md), [radio](godot/ghost-protocol-radio.md) and [search](godot/ghost-protocol-search.md).
- [Movement](godot/tactical-movement.md), [inventory](godot/weapon-inventory.md) and [shotgun](godot/shotgun.md).
- [Asset provenance](assets.md); editable art and generation scripts live in `assets/source/` at the repository root. Runtime exports live in `godot/assets/`.

## Historical records

Plans, checkpoints, reviews, saved results and screenshot folders record earlier milestones. Their branch names, controls, parity statements and performance measurements describe those versions; they are not necessarily current launch instructions. Keep these records for traceability and comparisons. A saved passing report does not establish that a new revision has been tested.

Current automated checks live in `godot/tests/` and `tests/`. The native regression runner is `scripts/run_godot_tests.py`; release workflows live in `.github/workflows/`.

## Repository housekeeping

`main` contains completed work. Create a short-lived branch for new changes, merge it when ready, then delete the merged branch label. Commits remain in main, and release tags identify published desktop builds.

`work/`, `godot/.godot/`, `_site/` and `node_modules/` are ignored generated files. Build downloads can be removed when no longer needed. `node_modules/` can be recreated with `npm ci`. Keep source assets, Godot `.uid` and `.import` metadata, and regression tests.

The checked-in root `index.html` and `classic.html` currently provide the original JavaScript edition. The web build generates the hosted Godot `index.html` and copies the classic edition alongside it. Use the root README to choose the intended version.

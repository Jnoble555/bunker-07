# Campaign migration checkpoint — paused before merge

**Historical checkpoint:** subsequent finalization and cleanup verification are documented in [campaign-release.md](campaign-release.md). The open items below describe the state when usage paused, not the final release candidate.

Branch: `migration/godot-campaign`, based on `af85238`. User requested a stop near the usage limit. This is an **in-progress campaign preview**, not a completed parity certification. Main/browser runtime and browser tests remain unchanged.

## Implemented

- Breach, Control Room and Blackout reference maps, objectives, spawn positions, briefings, progression, retries and final summary.
- Scout/armored/turret behavior; guard investigation, camera tracking and a single alarm reinforcement.
- Shootable camera/lamp, service-power/light tradeoff, bulkhead obstruction protection, one-use overload, optional intel/cache.
- Success-only campaign decisions, Blackout security consequences, journal carryover, ranks and retry tracking.
- Native settings/persistence, onboarding, journal, abandon confirmation, CSV schema/export, synthesized spatial audio and impact feedback.

The runtime entry scene now uses `scripts/campaign_main.gd`, extending the tested M1 shell in `main.gd`. Native missions are in `mission_data.gd`; session/ranks/preferences/CSV in `campaign_state.gd`; devices in `encounter_systems.gd`; generated audio in `native_audio.gd`.

## Executed validation and current limits

Combined Godot import completed without parser errors before the final small feedback/analytics fixes. The M1 mechanic suite passed 46 checks after isolating the newly introduced shootable devices and updating its intentionally obsolete partial-result assertion. The independent campaign suite has an actual saved report in `godot/tests/campaign-results.json`; see its check count and the independent review for the latest run. Early campaign failures identified a settings pause defect and a test helper that did not recognize the final summary; these were corrected.

A graphical smoke run captured title, Control Room, guard and pause views; those images were inspected and are preserved in `campaign-screenshots/`. This is scripted rendering/input verification, not a manual three-mission playthrough. Original M1 screenshots were preserved separately.

Review also corrected CSV target/detail placement and hit-count ordering. Some final feedback/audio/analytics edits may postdate the most recent full test run. **Before merging**, run final import plus both native suites against the exact final files, finish the independent review, and investigate the ObjectDB instances-leaked-at-exit warning observed in a native run. Do not interpret passing assertions as proof that the cleanup warning is resolved. Final visual/audio review of Breach, Blackout, settings and summary remains desirable.

## Resume commands

From the repository root in PowerShell:

```powershell
$godotBin = 'C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotBin --headless --path godot --editor --import --quit
& $godotBin --headless --path godot --script res://tests/milestone_test.gd
& $godotBin --headless --path godot --script res://tests/campaign_test.gd
& $godotBin --path godot
```

Use `--verbose` on a native run to investigate cleanup warnings. Continue from this branch; do not restart the port. Do not merge/push main until the outstanding verification is complete. The old M1 parity document is a historical snapshot; `campaign-plan.md` and this checkpoint describe the current pass, pending a final parity-table update.

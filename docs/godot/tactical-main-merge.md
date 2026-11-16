# Iron Relay / newer GitHub main integration

The approved Iron Relay build `e64045b` and GitHub main `b72fceb` had diverged from `a6cd31c`. This merge preserves the remote Godot Pages workflow, web export settings, classic JavaScript edition, browser CSV download and Deep Signal operation while adding Iron Relay. It does not replace the remote branch history.

The initial title offers **Deep Signal / Tactical Operation**, **Start Campaign** (the original three missions), and **Tactical Operation / Sector 12** (Iron Relay). Iron Relay retains its separate scene/controller and eleven enemies. Deep Signal retains its eight-enemy layout, objective flow and original actor behavior under renamed `deep_signal_enemy.gd` / `deep_signal_enemy_visual.gd`; its isolated actor test is now `deep_signal_enemy_test.gd`.

Shared shots, weapon presentation, ammunition and pickups use the approved Iron Relay implementation. Both operations use its original Blender Security Shotgun and 4/12 ammunition, 0.85s cadence, 1.7s reload and 8–18m effective-damage falloff. The remote rifle sound, medical pickups, tutorial wrapping, web CSV download and campaign behavior remain supported. The generated web page identifies both operations; its existing source-commit build marker remains intact.

## Fresh combined checks

Executed with Windows Godot **4.7.2.stable.official.ed1daf0bf**, Compatibility renderer:

Gameplay suites completed before the usage interruption; their completed outputs were inspected when resuming. The resumed run repeated editor import/script validation and exercised the web wrapper against a temporary HTML fixture (title, both operation names, classic link and source-commit marker all passed). No gameplay source changed after the passing combined runs.

| Command (`--path godot --script res://tests/…`) | Actual result |
| --- | --- |
| Editor `--headless --editor --import --quit` | Exit 0, no script/import errors |
| `tactical_operation_test.gd` (headless) | Deep Signal 28/28 |
| `deep_signal_enemy_test.gd` (headless) | 14/14 |
| `operation_integration_test.gd` (headless and graphical) | Iron Relay 23/23 in each mode |
| `operation_menu_test.gd` (graphical) | 7/7, including actual Deep Signal button/briefing, Iron Relay scene transitions and original Breach deployment |
| `operation_combat_test.gd` (graphical) | 7/7 controlled live AI checks |
| `shotgun_integration_test.gd` (headless) | 7/7 |
| `tactical_enemy_test.gd` (headless) | 22/22, including actual Iron Relay ramp/stairs |
| `milestone_test.gd` (headless) | 46/46 |
| `campaign_test.gd` (headless) | 51/51 |
| `inventory_test.gd` (headless) | 16/16 |
| `tactical_movement_test.gd` (graphical) | 18/18, including captured mouse handler |

The first Deep Signal run passed 27/28: the shotgun fixture placed its intended target behind the authored ramp patrol, which correctly intercepted the pellets. The fixture now disables unrelated actors' shot layers for the isolated blast/cover/range section. All original assertions remain; the corrected full suite passes 28/28. Retry rebuilds actors/collision normally. The diagnostic was a fixture correction, not a change permitting shots through actors.

Updated `operation-*` gameplay captures in `campaign-screenshots/` use the merged build. Older Deep Signal screenshots and JSON are preserved as historical results; their shotgun appearance predates the newly shared asset. Existing campaign/movement saved reports and captures are also preserved after execution.

The integration owner inspected the conflict resolutions and ran these combined checks. The earlier independent review covers the Iron Relay implementation before this merge; it is not a new independent review of the merge. Scripted route tests isolate AI, and the live combat fixture isolates one stationary shooter. No full human combat playthrough, balance-duration measurement or crowd/performance certification is claimed.

The preserved Pages workflow exports with pinned Godot **4.6.3**. These fresh checks use installed native **4.7.2**; they do not establish a fresh successful web export or hosted playtest. Verify the resulting GitHub Actions deployment and hosted `build-info.json` after pushing. The previous release's web checks remain recorded in [web-release.md](web-release.md). Checkpoint saves and true sight alignment remain deferred.

# Two-weapon inventory milestone

Branch: feature/weapon-inventory, based on completed main ca8fdfc. One agent; native Godot implementation.

## Rules

| Weapon | Magazine | Initial reserve | Damage | Fire interval | Reload | Range | Spread |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pistol | 8 | 40 | 1 | 0.24 s | 0.8 s | 50 m | 0 |
| SMG | 24 | 72 | 1 | 0.09 s | 1.25 s | 35 m | +/-0.035 directional offsets per axis |

The pistol is precise and semi-automatic. The SMG repeats while fire is held, has more visual recoil, spreads shots, and consumes ammunition faster. RMB aiming halves SMG spread. Shared definitions live in weapon_definitions.gd and feed capacity, reserves, damage, timing, range, spread, sound and presentation.

Each mission, new campaign and retry starts with a full pistol and its initial reserve. Inventory and pickups are mission-scoped: weapons/ammo do not carry into the next mission, and both pickups reset on retry. E collects the SMG without automatically equipping it; 1 selects pistol, 2 selects the owned SMG. Switching cancels a reload and preserves both magazines and reserves. Ammo transfers only at reload completion, taking the lesser of missing magazine rounds or available reserve. Switching preserves shot cooldown.

Each mission has one finite supply: +24 pistol reserve and +48 SMG reserve if owned when collected. A supply is consumed once. Fresh attempts always restore sufficient starting ammunition, and the existing complete campaign route checks remain achievable with the pistol. Running out of all ammo can be recovered with a supply or retry.

Pickups use a 1.6 m 3D eye-to-pickup distance and world line-of-sight; intervening solid geometry prevents collection. They are small nonblocking visual pickups. Positions (native meters):
- Breach: SMG (5,0,4), supplies (6,0,4), beside the starting corridor.
- Control Room: SMG (5,0,17), supplies (5,0,15), in maintenance.
- Blackout: SMG (5,0,3), supplies (3,0,5), near the entrance.

HUD shows weapon name, loaded/capacity and reserve; E guidance is shown near available pickups. Existing CSV columns remain unchanged. New weapon_pickup events identify the item in detail; weapon_switched records previous->new. Existing shot events still record active magazine ammo.

## Assets and presentation

The polished pistol .blend and GLB are unchanged. The SMG is original Blender 5.3.0 source under assets/source/security-smg, with its reproducible generator and separate Godot GLB export. The wrapper caches both models to avoid freeing material overrides during a switch; normal depth testing and isolated viewmodel rendering remain. Magazine animation uses each weapon's actual reload duration. The SMG uses a smaller model scale, its own muzzle location, stronger recoil and a distinct original synthesized firing sound.

## Actual verification

Godot 4.7.2 stable on Windows:
- Editor import/parser validation: no errors in inspected output.
- Existing mechanic regression: 46/46, zero failures.
- Existing three-mission campaign suite: 51/51, zero failures; no old assertions changed.
- Tactical suite headless: 17 passed, zero failures; captured mouse handler explicitly SKIPPED.
- Tactical suite graphical: 18 passed, zero failures, including synthetic mouse dispatch through Godot's captured input handler. This verifies handler wiring; a physical mouse was not operated.
- Inventory suite: 16/16 headlessly and 16/16 graphically. Covers finite starting reserves, distance/obstacle pickup rejection, E acquisition, slot action switching, independent ammo, reload cancellation/completion, pause, automatic cadence, semi-auto held input, one-use supplies, empty ammo, retry, mission transition and compatible event logging.
- Inspected graphical [pistol](campaign-screenshots/inventory-pistol.png), [SMG](campaign-screenshots/inventory-smg.png), [reload](campaign-screenshots/inventory-reload.png), [empty](campaign-screenshots/inventory-empty.png) and [retry](campaign-screenshots/inventory-retry.png) captures.
- Historical saved JSON reports are preserved; the counts above describe tests executed for this milestone.

The pitch helper preserves both +/-80 degree limits and uses the existing sensitivity. The headless check tests its math directly; the actual handler retains the capture-mode guard. Graphical input coverage is conditional and reports a skip if capture is unavailable.

## Launch and remaining manual checks

Open godot/project.godot in Godot, F5, Start Campaign, Deploy. Press E near the SMG immediately ahead, then 2; click/Space holds automatic fire, R reloads, and 1 returns to pistol. F5 retries. The standalone movement lab remains scenes/movement_lab.tscn (F6), with pickups outside its separate arena.

Run the focused checks from the repo root with the installed Godot console executable and:
- --headless --path godot --script res://tests/inventory_test.gd
- --headless --path godot --script res://tests/tactical_movement_test.gd
- --path godot --script res://tests/tactical_movement_test.gd (graphical input handler)
- --path godot --script res://tests/inventory_test.gd (rendered inventory capture)

Remaining manual checks: physical mouse/keyboard feel, sound mix and subjective recoil, prolonged ammunition balance, full human campaign completion and other window sizes/drivers. Scripted rendered checks are not a full human playthrough.

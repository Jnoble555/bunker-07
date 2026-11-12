# Armed tactical enemies

The new operation uses `godot/scripts/tactical_enemy.gd`; the original three campaign missions retain `armored_guard.gd` and their prior behavior. Visual construction and animation live separately in `tactical_enemy_visual.gd`. All enemy geometry/materials are original project source. The visible SMG and elongated rifle variant reuse the original `security_smg.glb`; no external assets were introduced.

## Integration contract

- `setup(controller, spawn, spec)` accepts `id`, `role` (`tactical_smg` or `tactical_rifle`), optional `hp` and floor-position `patrol` points.
- Public compatibility fields: `hp`, `id`, `role`, `is_guard`, `attack_windup`, `alert_progress`, `stagger`. `receive_hit(damage_amount = 1)` supports pellet damage and ignores dead actors. Dead actors remain registered for mission statistics but disable collision and visuals.
- Controller provides `active`, `player.camera`, `room`, `enemies`, `has_los`, `damage_player`, `play_sound` and `register_event`. Call `on_noise(player.global_position)` once per player trigger pull; the source is a floor point for navigation.
- The room provides `find_path(from, to) -> PackedVector3Array` and `cover_points: Array[Vector3]`. An empty path stops movement; there is no direct hidden-player fallback. The operation's graph provides capsule-clear, elevation-aware floor points.
- Physics: world layer 1, player 2, enemy 4. Tactical enemies collide with world, player and other enemies. Sight uses actual player eye position. Every fired round checks the nearest world/player/enemy body again, preventing damage through cover and allies.

## Behavior

States are patrol, suspicious/investigate, engage, search, reload, and withdraw when finite reserves are exhausted. Patrol sight has a forward cone. Direct sight accumulates a readable reaction delay; shots/ally contacts provide remembered positions and investigation rather than instant permission to fire. Losing sight freezes the remembered position. A bounded search follows that remembered floor point, scans the area, and returns to patrol. Hidden player movement is never read as a navigation destination.

Nearby allies receive a last-seen position at most once every 2.5 seconds, within 11 m and with a clear inter-ally line of sight. They become suspicious and must establish their own direct sight before engaging. Player shots can be heard within 20 m. Repeated stationary shots do not flood state transitions or restart investigation on every round.

Rifle units prefer roughly 14 m and reachable occluding cover, moving more slowly. SMG units prefer roughly 7 m, close distance when needed, and use cover when damaged or pressed. Cover selection rejects unreachable candidates and requires actual world occlusion from the remembered threat position. Units move to cover, pause briefly, find a reachable exposed peek, and retreat after a burst. Hits and changing threat positions cause reevaluation. These are local cover decisions, not a squad planner or a claim of optimal tactics.

| Role | HP | Moving speed | Reaction | Preparation | Burst | Magazine / reserve | Reload | Damage / round |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SMG | 3 | 2.5 m/s | 0.45 s | 0.45 s | 3 at 0.13 s intervals | 8 / 48 | 1.9 s | 4 |
| Rifle | 4 | 1.65 m/s | 0.65 s | 0.6 s | 2 at 0.26 s intervals | 6 / 30 | 2.4 s | 7 |

Preparation, reload and search have visible world labels. Weapons flash at the muzzle and use the existing original finite sound synthesis. Pause freezes timers, movement, preparation, reload and visuals. A hit staggers the actor and cancels its pending preparation/burst. Retry creates fresh actors; `reset_guard()` also clears all AI clocks, paths, contacts and ammunition state.

The controller captures intended horizontal speed before `move_and_slide`, so a head-on collision that zeros actual velocity still counts as blocked movement. Local ally repulsion, body collision, periodic replanning and reachable lateral yielding reduce stacking and doorway deadlocks. The authored operation has wide doorways; this is not a guarantee for arbitrary one-person passages.

## Verification

`tactical_enemy_test.gd` runs real Godot physics. Its fixture tests reaction/preparation, obstruction added during windup, hidden-position memory, lost-sight search, damage/ray ordering, finite reload and pause, unreachable destinations, cover reachability/occlusion, bounded ally sharing, friendly-fire obstruction, body stacking, blocked-intent accumulation and yielding, stagger/death behavior, and role differences. Additional cases use the actual operation graph and collision geometry for archive ramp and staircase ascent.

The reviewer identified a blocked-clock bug caused by inspecting velocity only after sliding. The intended-speed fix has a focused head-on wall regression. Actual enemy stair traversal also exposed graph nodes on the exact outer stair edge; the level owner moved those nodes inside the physical treads. Slow enemy movement then exposed a short-probe capsule/riser-corner contact issue. The enemy step helper now probes 0.22 m onto the tread with a full-body clearance sweep, preserves the 0.26 m maximum rise, and gives the step a bounded 0.12 s snap/gravity grace. The actual operation ramp and stair regression cases both pass.

Executed final result on Godot `4.7.2.stable.official.ed1daf0bf`, Windows headless: **22/22 passed**, zero failures, exit 0, with no script/runtime errors in the inspected output. This includes the 20 behavior/physics fixture checks and both actual-level elevation traversals.

Run from the repository root with Godot 4.7.2:

```powershell
& 'C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --headless --path godot --script res://tests/tactical_enemy_test.gd
```

The fixture isolates the AI from full-operation progression. Full objective routes, weapon accuracy statistics and graphical operation captures are integration-owner checks. Human tactical difficulty, long sessions, arbitrary narrow passages, and other hardware remain manual checks.

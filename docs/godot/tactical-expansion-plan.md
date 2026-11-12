# Tactical expansion interface contract
Main owns existing campaign/player/UI, weapon definitions, pickup/save/event integration and operation_main.gd. Enemy, authored level and shotgun modules are delegated in disjoint new files. Old campaign uses its original enemy class and three mission definitions.

- Enemy: setup(controller, spawn, spec); hp/id/role/is_guard/attack_windup/alert_progress/stagger; receive_hit(damage=1), on_noise(floor_position), receive_contact(position). World1/player2/enemy4, pausable. No damage before visibility recheck.
- Level: build(), mission_contract() with spawn/bots/objectives/pickups/route_waypoints; find_path(from,to)->PackedVector3Array, cover_points:Array[Vector3], set_access_granted(bool). Objective terminal colliders carry interaction_at metadata if rays end within housing.
- Shared definitions: existing fields plus shotgun pellets/falloff/model/view_scale/supply. Ballistics returns one nearest ray hit/miss per pellet and damage metadata. Integration applies damage and counts at most one accuracy hit per trigger.
- Pickup specs: id smg/shotgun/supply, position, label, optional grants dictionary and health. One-use per attempt, mission-scoped inventory reset.
- Events retain CSV schema. New events use event/detail; no per-pellet increase to trigger-count accuracy.
- Save/resume is stretch work only after core completion; no half-working save UI will be exposed.

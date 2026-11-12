extends RefCounted
## One nearest-surface physics ray per pellet. This module never mutates game state.
## Misses retain direction/distance/damage metadata but have no collider key.

static func pellet_damage(distance: float, definition: Dictionary) -> int:
	if not is_finite(distance) or distance < 0.0:
		return 0
	if distance > float(definition.get("range", 50.0)):
		return 0
	if definition.has("falloff_end") and distance >= float(definition.falloff_end):
		return 0
	return maxi(0, int(definition.get("damage", 1)))

static func cast(world: World3D, origin: Vector3, basis: Basis, exclude: Array[RID], definition: Dictionary, spread_multiplier: float = 1.0) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var count: int = clampi(int(definition.get("pellets", 1)), 1, 32)
	var reach: float = maxf(0.01, float(definition.get("range", 50.0)))
	var spread: float = maxf(0.0, float(definition.get("spread", 0.0)) * spread_multiplier)
	var pattern_rotation: float = randf() * TAU if count > 1 else 0.0
	for pellet in count:
		var offset := Vector2.ZERO
		if spread > 0.0:
			if count == 1:
				# Preserve the existing SMG's square angular jitter.
				offset = Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
			elif pellet > 0:
				# A center pellet plus stratified disk coverage avoids accidental pellet clumps.
				var radius: float = sqrt(float(pellet) / float(count - 1)) * spread
				var angle: float = pattern_rotation + float(pellet) * 2.39996323
				offset = Vector2(cos(angle), sin(angle)) * radius
		var direction: Vector3 = (-basis.z + basis.x * offset.x + basis.y * offset.y).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * reach, 1 | 4 | 8, exclude)
		query.collide_with_areas = true
		query.hit_from_inside = true
		var hit: Dictionary = world.direct_space_state.intersect_ray(query)
		var distance: float = origin.distance_to(hit.position) if not hit.is_empty() else reach
		var damage: int = pellet_damage(distance, definition) if not hit.is_empty() else 0
		if damage > 0 and count > 1 and definition.has("falloff_end"):
			var start: float = float(definition.get("falloff_start", 0.0))
			var end: float = float(definition.falloff_end)
			var fraction: float = 1.0 if distance <= start else clampf((end - distance) / maxf(0.001, end - start), 0.0, 1.0)
			# Integer enemy HP is retained. Distance sheds damaging pellets deterministically.
			if (float(pellet) + 0.5) / float(count) > fraction:
				damage = 0
		hit["hit"] = not hit.is_empty()
		hit["pellet_index"] = pellet
		hit["direction"] = direction
		hit["distance"] = distance
		hit["damage"] = damage
		results.append(hit)
	return results

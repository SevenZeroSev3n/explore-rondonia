class_name TreeScatter
extends RefCounted
## Deterministic tree candidates per map chunk. The same chunk always yields the
## same trees, so chunks can be freed when far and rebuilt when the truck returns.
## Filtering (road clearance, inside the state, not in rivers) is the caller's job.


## Candidate positions for one chunk, in world pixels.
static func candidates(chunk: Vector2i, chunk_size: float, per_chunk: int, world_seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, chunk.x, chunk.y])
	var origin := Vector2(chunk) * chunk_size
	var out: Array[Dictionary] = []
	var n := per_chunk + rng.randi_range(-per_chunk / 3, per_chunk / 3)
	for i in n:
		out.append({
			"pos": (origin + Vector2(rng.randf() * chunk_size, rng.randf() * chunk_size)).round(),
			"angle": rng.randf_range(-PI, PI),
			"keep": rng.randf(),       # rolls for Forest.tree_at / shrub_at
			"species": rng.randf(),
		})
	return out


static func chunk_of(p: Vector2, chunk_size: float) -> Vector2i:
	return Vector2i(floori(p.x / chunk_size), floori(p.y / chunk_size))

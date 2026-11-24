class_name Fauna
extends RefCounted
## Static animals on layer 1 (ADR 0009): scenery planted like trees, never moving.
## Nelore cattle graze in herds in the pastures along BR-364; capybaras rest in
## groups on the riverbanks. Deep forest stays empty (its animals hide).

const SLICES := {"cattle": 13, "capybara": 6}
## Chance a candidate spot holds a group, per habitat.
const CHANCE := {Forest.Habitat.PASTURE: 0.35, Forest.Habitat.RIVERSIDE: 0.3}


## The animals of one candidate spot: [{species, pos, angle}] (empty most of the time).
## keep_roll and size_roll are uniform in [0, 1); the layout is seeded by the centre.
static func group(h: Forest.Habitat, centre: Vector2, keep_roll: float, size_roll: float) -> Array:
	if not CHANCE.has(h) or keep_roll >= CHANCE[h]:
		return []
	var species := "cattle" if h == Forest.Habitat.PASTURE else "capybara"
	var n := 2 + int(size_roll * (4 if species == "cattle" else 3))
	var spread := 40.0 if species == "cattle" else 18.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([int(centre.x), int(centre.y), species])
	var out := []
	var heading := rng.randf_range(-PI, PI)          # a herd mostly faces one way
	for i in n:
		var off := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * spread
		out.append({"species": species, "pos": (centre + off).round(), "angle": heading + rng.randf_range(-0.8, 0.8)})
	return out

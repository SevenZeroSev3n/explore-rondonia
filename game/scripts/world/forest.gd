class_name Forest
extends RefCounted
## What grows where on layer 1. Pure rules, no nodes: the state map measures the
## habitat (distance to road and rivers) and asks which species, if any, stands
## at each candidate spot. Species are real Rondônia trees (art/views/03-forest.md).

enum Habitat { FOREST, RIVERSIDE, PASTURE }

## Slice counts: the contract with tools/build_stacks.py.
const SLICES := {
	"castanheira": 35, "seringueira": 27, "acai": 32, "buriti": 32,
	"ipe": 27, "embauba": 24, "shrub": 8, "babacu": 32, "sumauma": 48,
}

## Relative weights per habitat. Castanheiras are protected by law, so in Rondônia
## they often stand alone in pasture after the forest around them was cleared.
const WEIGHTS := {
	Habitat.FOREST: {"castanheira": 3.0, "seringueira": 4.0, "acai": 3.0, "embauba": 1.0, "ipe": 0.5,
		"buriti": 0.5, "babacu": 1.0, "sumauma": 0.4},
	Habitat.RIVERSIDE: {"buriti": 5.0, "acai": 4.0, "seringueira": 1.0, "embauba": 0.5, "sumauma": 0.5},
	## Babaçu palms take over cleared pastures in Rondônia; ipês are left standing for shade.
	Habitat.PASTURE: {"babacu": 4.0, "embauba": 2.0, "castanheira": 1.0, "ipe": 0.6},
}

## Chance a tree candidate is kept: dense forest, fairly dense riverbanks, sparse pasture.
const DENSITY := {Habitat.FOREST: 0.9, Habitat.RIVERSIDE: 0.8, Habitat.PASTURE: 0.12}
const SHRUB_DENSITY := {Habitat.FOREST: 0.7, Habitat.RIVERSIDE: 0.5, Habitat.PASTURE: 0.0}

const RIVERSIDE_DISTANCE := 93.0     ## px from a river
const PASTURE_DISTANCE := 213.0      ## px from BR-364: the cleared belt along the road

var _noise := FastNoiseLite.new()


func _init(world_seed: int = 364) -> void:
	_noise.seed = world_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.003             # clearings and groves a few hundred px across


static func habitat(road_distance: float, river_distance: float) -> Habitat:
	if river_distance <= RIVERSIDE_DISTANCE:
		return Habitat.RIVERSIDE
	if road_distance <= PASTURE_DISTANCE:
		return Habitat.PASTURE
	return Habitat.FOREST


## 0..1: how wooded this spot is (forest has groves and clearings, never uniform).
func cover(p: Vector2) -> float:
	return clampf(0.75 + _noise.get_noise_2dv(p) * 0.7, 0.0, 1.0)


## Species for a tree candidate, or "" when nothing grows there. keep_roll and
## species_roll are uniform in [0, 1) (deterministic per candidate).
func tree_at(h: Habitat, p: Vector2, keep_roll: float, species_roll: float) -> String:
	var chance: float = DENSITY[h] * (cover(p) if h == Habitat.FOREST else 1.0)
	if keep_roll >= chance:
		return ""
	return pick(WEIGHTS[h], species_roll)


func shrub_at(h: Habitat, p: Vector2, keep_roll: float) -> bool:
	return keep_roll < SHRUB_DENSITY[h] * (cover(p) if h == Habitat.FOREST else 1.0)


## Weighted choice; roll in [0, 1).
static func pick(weights: Dictionary, roll: float) -> String:
	var total := 0.0
	for w in weights.values():
		total += w
	var acc := 0.0
	var target := roll * total
	for name in weights:
		acc += weights[name]
		if target < acc:
			return name
	return weights.keys()[-1]

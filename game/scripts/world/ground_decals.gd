class_name GroundDecals
extends Node2D
## Small flat ground details for one map chunk (grass tufts, flowers, stones; ADR 0009),
## drawn in one _draw call from the atlas made by tools/make_ground.py.

const ATLAS := preload("res://assets/ground/decals.png")
const CELL := 8
## Atlas order, as tools/make_ground.py DECALS.
const NAMES := ["tuft_a", "tuft_b", "tuft_c", "dry_tuft", "flowers_yellow", "flowers_white",
	"flowers_pink", "stone_small", "stone_pair", "leaf_litter"]

## Decal names per habitat with weights (Forest.pick); pasture flowers, forest litter.
const MIX := {
	Forest.Habitat.PASTURE: {"tuft_a": 3.0, "tuft_b": 3.0, "tuft_c": 2.0, "dry_tuft": 2.0,
		"flowers_yellow": 1.0, "flowers_white": 1.0, "flowers_pink": 0.6, "stone_small": 0.8, "stone_pair": 0.4},
	Forest.Habitat.FOREST: {"leaf_litter": 4.0, "tuft_a": 1.5, "tuft_c": 1.5, "stone_small": 0.5},
	Forest.Habitat.RIVERSIDE: {"tuft_b": 3.0, "tuft_c": 2.0, "stone_small": 1.5, "stone_pair": 1.0, "flowers_white": 0.5},
}

var _items: Array = []   ## [position: Vector2, atlas index: int]


func add(pos: Vector2, decal_name: String) -> void:
	_items.append([pos.round(), NAMES.find(decal_name)])


func count() -> int:
	return _items.size()


func _draw() -> void:
	for it in _items:
		var src := Rect2(it[1] * CELL, 0, CELL, CELL)
		draw_texture_rect_region(ATLAS, Rect2(it[0] - Vector2(CELL / 2.0, CELL - 1), Vector2(CELL, CELL)), src)

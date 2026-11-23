extends Node2D
## Placeholder world for the first playable slice: a winding road heading north
## (standing in for BR-364 until the geodata pipeline exists, ADR 0003), pasture,
## and procedurally scattered trees.

const TREE_SHEET := preload("res://assets/stacks/tree/tree_slices.png")
const TREE_SLICES := 26
const ASPHALT_HALF_WIDTH := 13.0
const SHOULDER_HALF_WIDTH := 18.0
const ROAD_LENGTH := 4000.0
const TREE_COUNT := 450
const SEED := 364

var road: PackedVector2Array

@onready var ground: Node2D = $Ground
@onready var entities: Node2D = $Entities
@onready var truck: Truck = $Entities/Truck


func _ready() -> void:
	road = _make_road()
	_draw_ground()
	_scatter_trees()
	truck.position = road[0] + Vector2(0, -20)
	truck.surface_provider = surface_at


func surface_at(pos: Vector2) -> float:
	return RoadGeometry.surface_at_distance(
		RoadGeometry.distance_to_polyline(road, pos), ASPHALT_HALF_WIDTH, SHOULDER_HALF_WIDTH)


func _make_road() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var y := 0.0
	while y > -ROAD_LENGTH:
		pts.append(Vector2(sin(y / 380.0) * 140.0 + sin(y / 97.0) * 18.0, y))
		y -= 40.0
	return pts


func _draw_ground() -> void:
	var dirt := Line2D.new()
	dirt.points = road
	dirt.width = SHOULDER_HALF_WIDTH * 2.0
	dirt.default_color = Color("9c4a2f")
	dirt.joint_mode = Line2D.LINE_JOINT_ROUND
	ground.add_child(dirt)

	var asphalt := Line2D.new()
	asphalt.points = road
	asphalt.width = ASPHALT_HALF_WIDTH * 2.0
	asphalt.default_color = Color("4a4a50")
	asphalt.joint_mode = Line2D.LINE_JOINT_ROUND
	ground.add_child(asphalt)

	var stripe := Line2D.new()
	stripe.points = road
	stripe.width = 1.0
	stripe.default_color = Color("e8c64a")
	ground.add_child(stripe)


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var placed := 0
	var attempts := 0
	while placed < TREE_COUNT and attempts < TREE_COUNT * 10:
		attempts += 1
		var p := Vector2(rng.randf_range(-700.0, 700.0), rng.randf_range(-ROAD_LENGTH, 300.0))
		if RoadGeometry.distance_to_polyline(road, p) < SHOULDER_HALF_WIDTH + 22.0:
			continue
		var tree := SpriteStack.new()
		tree.sheet = TREE_SHEET
		tree.slice_count = TREE_SLICES
		tree.angle = rng.randf_range(-PI, PI)
		tree.position = p.round()
		entities.add_child(tree)
		placed += 1

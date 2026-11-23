extends Node2D
## Layer 1: the whole state, from game/data/geo/state_map.json (ADR 0002/0003).
## North-up; trees are streamed in chunks around the truck.

const TREE_SHEET := preload("res://assets/stacks/tree/tree_slices.png")
const TREE_SLICES := 26
const ASPHALT_HALF_WIDTH := 13.0
const SHOULDER_HALF_WIDTH := 18.0
const ROAD_TREE_CLEARANCE := 44.0
const RIVER_HALF_WIDTH := 3.0
const CHUNK_SIZE := 384.0
const CHUNK_RADIUS := 1          ## chunks kept around the truck's chunk in each direction
const TREES_PER_CHUNK := 18
const WORLD_SEED := 364

const PASTURE := Color("4e7a40")
const OUTSIDE := Color("2f4a2c")
const RIVER := Color("4f86b8")
const DIRT := Color("9c4a2f")
const ASPHALT := Color("4a4a50")
const STRIPE := Color("e8c64a")

var map: StateMapData
var road_index: PolylineIndex
var river_index: PolylineIndex
var _chunks: Dictionary = {}     ## Vector2i -> Array[Node]
var _last_chunk := Vector2i(1 << 30, 1 << 30)

@onready var ground: Node2D = $Ground
@onready var entities: Node2D = $Entities
@onready var truck: Truck = $Entities/Truck


func _ready() -> void:
	RenderingServer.set_default_clear_color(OUTSIDE)
	map = StateMapData.load_file()
	if map == null:
		return
	road_index = PolylineIndex.new([map.road])
	var river_lines: Array = []
	for r in map.rivers:
		river_lines.append(r.points)
	river_index = PolylineIndex.new(river_lines)
	_draw_ground()
	_place_towns()
	truck.surface_provider = surface_at
	truck.bounds_provider = is_inside_state
	truck.position = map.road[0]
	var dir := map.road[1] - map.road[0]
	truck.model.heading = atan2(dir.x, -dir.y)


func _process(_delta: float) -> void:
	if map == null:
		return
	var c := TreeScatter.chunk_of(truck.position, CHUNK_SIZE)
	if c != _last_chunk:
		_last_chunk = c
		_stream_chunks(c)


func surface_at(pos: Vector2) -> float:
	var d := road_index.distance_within(pos, SHOULDER_HALF_WIDTH)
	return RoadGeometry.surface_at_distance(d, ASPHALT_HALF_WIDTH, SHOULDER_HALF_WIDTH)


func is_inside_state(pos: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(pos, map.border)


func _draw_ground() -> void:
	var land := Polygon2D.new()
	land.polygon = map.border
	land.color = PASTURE
	ground.add_child(land)

	for r in map.rivers:
		ground.add_child(_line(r.points, RIVER_HALF_WIDTH * 2.0, RIVER))
	ground.add_child(_line(map.road, SHOULDER_HALF_WIDTH * 2.0, DIRT))
	ground.add_child(_line(map.road, ASPHALT_HALF_WIDTH * 2.0, ASPHALT))
	ground.add_child(_line(map.road, 1.0, STRIPE))


func _line(points: PackedVector2Array, width: float, color: Color) -> Line2D:
	var l := Line2D.new()
	l.points = points
	l.width = width
	l.default_color = color
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	return l


## Placeholder town markers until the stamp and photo systems exist. Town names
## are proper nouns from the map data, the same in both languages.
func _place_towns() -> void:
	for t in map.towns:
		var marker := Node2D.new()
		marker.position = t.pos
		var dot := Polygon2D.new()
		var r := 7.0 if t.stamp else 4.0
		var pts := PackedVector2Array()
		for i in 12:
			pts.append(Vector2.from_angle(TAU * i / 12.0) * r)
		dot.polygon = pts
		dot.color = Color("f2d04a") if t.stamp else Color("e8e4d8")
		marker.add_child(dot)
		var label := Label.new()
		label.text = t.name
		label.position = Vector2(r + 3, -8)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 3)
		marker.add_child(label)
		ground.add_child(marker)


func _stream_chunks(center: Vector2i) -> void:
	var wanted := {}
	for dx in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
		for dy in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
			wanted[center + Vector2i(dx, dy)] = true
	for c in _chunks.keys():
		if not wanted.has(c):
			for n: Node in _chunks[c]:
				n.queue_free()
			_chunks.erase(c)
	for c in wanted:
		if not _chunks.has(c):
			_chunks[c] = _build_chunk(c)


func _build_chunk(c: Vector2i) -> Array[Node]:
	var nodes: Array[Node] = []
	for cand in TreeScatter.candidates(c, CHUNK_SIZE, TREES_PER_CHUNK, WORLD_SEED):
		var p: Vector2 = cand.pos
		if not is_inside_state(p):
			continue
		if road_index.distance_within(p, ROAD_TREE_CLEARANCE) < INF:
			continue
		if river_index.distance_within(p, RIVER_HALF_WIDTH + 8.0) < INF:
			continue
		var tree := SpriteStack.new()
		tree.sheet = TREE_SHEET
		tree.slice_count = TREE_SLICES
		tree.angle = cand.angle
		tree.position = p
		entities.add_child(tree)
		nodes.append(tree)
	return nodes

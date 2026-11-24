class_name Diorama
extends Node2D
## Layer 2 (ADR 0002/0008): a small explorable scene entered from a city. The
## camera turns with Q/E; landmarks come from the place catalog
## (diorama_layout); photos use a ±30° window measured from the camera.

signal exit_requested

const TRAVELER_SCENE := preload("res://scenes/traveler.tscn")
const TRUCK_SHEET := preload("res://assets/stacks/truck/truck_slices.png")
const SIZE := Vector2(747, 480)
const RIVER_EDGE_Y := -160.0
const RAIL_Y := -53.0
const TRUCK_POS := Vector2(53, 187)
const EXIT_RADIUS := 35.0
const TURN_SPEED := 1.8                ## rad/s
## The camera looks a little ahead of the traveler (up on screen), so what you face
## sits in the middle of the viewfinder instead of half out of it.
const LOOK_AHEAD := 53.0
## Slice counts of the sheets in assets/stacks (see tools/make_placeholder_stacks.py).
const SLICES := {"locomotive": 23, "shed": 27, "water_tower": 48}

const GRASS := Color("5d8a48")
const SAND := Color("c9b07a")
const WATER := Color("4f86b8")
const RAIL := Color("6d6a66")
const SLEEPER := Color("5a4330")

@export var diorama_id := "efmm"

var catalog: PlaceCatalog
var hud: Hud
var spots: Array[Dictionary] = []      ## PhotoRules spots, positions in diorama space
var camera: Camera2D
var traveler: Traveler
var _entities: Node2D
var _target_rotation := 0.0


func _ready() -> void:
	if catalog == null:
		catalog = PlaceCatalog.load_dir()
	_build_ground()
	_entities = Node2D.new()
	add_child(_entities)
	_place_truck()
	_place_landmarks()
	traveler = TRAVELER_SCENE.instantiate()
	traveler.position = TRUCK_POS + Vector2(29, 0)
	_entities.add_child(traveler)
	camera = Camera2D.new()
	camera.ignore_rotation = false
	camera.position_smoothing_enabled = true
	camera.position = _camera_target()
	add_child(camera)
	camera.make_current()
	_apply_rotation(0.0)


func _process(delta: float) -> void:
	var turn := Input.get_action_strength("rotate_view_right") - Input.get_action_strength("rotate_view_left")
	_target_rotation += turn * TURN_SPEED * delta
	_apply_rotation(_target_rotation)
	camera.position = _camera_target()
	traveler.view_rotation = camera.rotation
	_sort_by_screen_y()
	if hud:
		hud.set_prompt(tr("EXIT_DIORAMA") if near_truck() else "")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and near_truck():
		get_viewport().set_input_as_handled()
		exit_requested.emit()


func near_truck() -> bool:
	return traveler.position.distance_to(TRUCK_POS) <= EXIT_RADIUS


## Judges a photo through the viewfinder (screen rect) with the current camera.
func take_photo(frame_screen: Rect2) -> Dictionary:
	var to_screen := get_viewport().get_canvas_transform()
	var eye := PhotoRules.eye_bearing_deg(camera.rotation)
	var best := {}
	var best_d := INF
	for s in spots:
		var screen_pos: Vector2 = to_screen * (s.pos as Vector2)
		var r: float = s.radius
		var rect := Rect2(screen_pos - Vector2(r, r), Vector2(r, r) * 2.0)
		if not frame_screen.intersects(rect):
			continue
		var d := screen_pos.distance_to(frame_screen.get_center())
		if d < best_d:
			best_d = d
			best = {
				"spot": s,
				"result": PhotoRules.judge(s, frame_screen.encloses(rect),
					traveler.position.distance_to(s.pos), PhotoRules.bearing_off(s, eye)),
			}
	return best


func _camera_target() -> Vector2:
	var rot := camera.rotation if camera else 0.0
	return traveler.position + Vector2(0, -LOOK_AHEAD).rotated(rot)


func _apply_rotation(r: float) -> void:
	camera.rotation = r
	SpriteStack.set_view_rotation(get_tree(), r)


## With a turning camera Y-sort no longer matches the screen: sort by screen y instead.
func _sort_by_screen_y() -> void:
	for child in _entities.get_children():
		var y := (child as Node2D).position.rotated(-camera.rotation).y
		(child as CanvasItem).z_index = clampi(int(y), -4000, 4000)   # ground is at CANVAS_ITEM_Z_MIN


func _build_ground() -> void:
	var half := SIZE / 2.0
	# Ground sits under everything: entities get z = screen y, which goes negative.
	var ground := Node2D.new()
	ground.z_index = RenderingServer.CANVAS_ITEM_Z_MIN
	add_child(ground)
	var margin := 533.0   # scenery beyond the walls, so turning the view never shows the void
	ground.add_child(_poly([Vector2(-half.x - margin, RIVER_EDGE_Y + 24), Vector2(half.x + margin, RIVER_EDGE_Y + 24),
		Vector2(half.x + margin, half.y + margin), Vector2(-half.x - margin, half.y + margin)], GRASS))
	ground.add_child(_poly([Vector2(-half.x - margin, RIVER_EDGE_Y), Vector2(half.x + margin, RIVER_EDGE_Y),
		Vector2(half.x + margin, RIVER_EDGE_Y + 24), Vector2(-half.x - margin, RIVER_EDGE_Y + 24)], SAND))
	ground.add_child(_poly([Vector2(-half.x - margin, -half.y - margin), Vector2(half.x + margin, -half.y - margin),
		Vector2(half.x + margin, RIVER_EDGE_Y), Vector2(-half.x - margin, RIVER_EDGE_Y)], WATER))
	var x := -half.x
	while x <= half.x:
		var sleeper := Line2D.new()
		sleeper.points = PackedVector2Array([Vector2(x, RAIL_Y - 8), Vector2(x, RAIL_Y + 8)])
		sleeper.width = 3.0
		sleeper.default_color = SLEEPER
		ground.add_child(sleeper)
		x += 11.0
	for dy in [-4.0, 4.0]:
		var rail := Line2D.new()
		rail.points = PackedVector2Array([Vector2(-half.x, RAIL_Y + dy), Vector2(half.x, RAIL_Y + dy)])
		rail.width = 1.0
		rail.default_color = RAIL
		ground.add_child(rail)
	# Walls: the river and the edges of the diorama.
	_wall(Rect2(-half.x, -half.y - 40, SIZE.x, half.y + 40 + RIVER_EDGE_Y + 5))
	_wall(Rect2(-half.x - 40, -half.y, 40, SIZE.y))
	_wall(Rect2(half.x, -half.y, 40, SIZE.y))
	_wall(Rect2(-half.x, half.y, SIZE.x, 40))


func _place_truck() -> void:
	var truck := SpriteStack.new()
	truck.sheet = TRUCK_SHEET
	truck.slice_count = 12
	truck.angle = -PI / 2.0
	truck.position = TRUCK_POS
	_entities.add_child(truck)


func _place_landmarks() -> void:
	for id in catalog.ids_in_diorama(diorama_id):
		var layout := catalog.layout_of(id)
		var pos := Vector2(layout.local_pos[0], layout.local_pos[1])
		spots.append(catalog.spot_for(id, pos, float(layout.get("view_from_deg", 180.0))))
		var stack_name: Variant = layout.get("stack")
		if stack_name == null:
			continue
		var sheet: Texture2D = load("res://assets/stacks/%s/%s_slices.png" % [stack_name, stack_name])
		var offsets: Array = layout.get("instances", [[0, 0]])
		for o in offsets:
			var s := SpriteStack.new()
			s.sheet = sheet
			s.slice_count = SLICES[stack_name]
			s.angle = deg_to_rad(float(layout.get("facing_deg", 0.0)))
			s.position = pos + Vector2(o[0], o[1])
			_entities.add_child(s)
			var body := StaticBody2D.new()
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = 12.0 if offsets.size() > 1 else float(spots[-1].radius) * 0.7
			shape.shape = circle
			body.add_child(shape)
			body.position = s.position
			add_child(body)


func _poly(points: Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(points)
	p.color = color
	return p


func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)
	add_child(body)

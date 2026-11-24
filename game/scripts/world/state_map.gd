extends Node2D
## Layer 1: the whole state, from game/data/geo/state_map.json (ADR 0002/0003).
## North-up; trees are streamed in chunks around the truck.

const ASPHALT_HALF_WIDTH := 13.0
const SHOULDER_HALF_WIDTH := 18.0
const ROAD_TREE_CLEARANCE := 44.0
const RIVER_HALF_WIDTH := 3.0
const CHUNK_SIZE := 384.0
const CHUNK_RADIUS := 1          ## chunks kept around the truck's chunk in each direction
const TREES_PER_CHUNK := 300
const SHRUBS_PER_CHUNK := 130
## Planting and clearing are spread over frames so crossing a chunk border never
## stalls a frame (hundreds of stacks per chunk; the web build is slower than native).
const PLANTS_PER_FRAME := 90
const CLEARS_PER_FRAME := 200
const WORLD_SEED := 364
const STAMP_RADIUS := 70.0
const SPOT_REVEAL_DISTANCE := 500.0   ## secrets show a glint only when you are near
const DIORAMA_SCENE := preload("res://scenes/diorama_efmm.tscn")
const DIORAMA_TOWN := "Porto Velho"
const DIORAMA_ENTER_RADIUS := 110.0

const PASTURE := Color("4e7a40")
const OUTSIDE := Color("2f4a2c")
const RIVER := Color("4f86b8")
const DIRT := Color("9c4a2f")
const ASPHALT := Color("4a4a50")
const STRIPE := Color("e8c64a")

var map: StateMapData
var catalog: PlaceCatalog
var spots: Array[Dictionary] = []     ## PhotoRules spots (catalog rules + map position)
var _spot_markers: Dictionary = {}    ## id -> Node2D
var road_index: PolylineIndex
var river_index: PolylineIndex
var _chunks: Dictionary = {}     ## Vector2i -> Array[Node]
var forest := Forest.new(WORLD_SEED)
var _sheets: Dictionary = {}     ## species -> Texture2D
var _to_plant: Array = []        ## [chunk, candidate, is_shrub], nearest chunks first
var _to_clear: Array[Node] = []
var _last_chunk := Vector2i(1 << 30, 1 << 30)
var diorama: Diorama                  ## the active layer-2 scene, or null on the state map

@onready var ground: Node2D = $Ground
@onready var entities: Node2D = $Entities
@onready var truck: Truck = $Entities/Truck
@onready var hud: Hud = $Hud


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
	catalog = PlaceCatalog.load_dir()
	for s in map.spots:
		if catalog.has(s.id):
			spots.append(catalog.spot_for(s.id, s.pos, s.view_from_deg))
	_place_spot_markers()
	hud.stamp_cities = map.stamp_cities()
	hud.secret_ids = catalog.ids_of_kind("secret")
	hud.landmark_ids = catalog.ids_in_diorama("efmm")
	hud.map_attribution = map.attribution
	SaveStore.passport.stamped.connect(func(_c: String) -> void: check_complete())
	SaveStore.passport.photographed.connect(func(_id: String) -> void: check_complete())
	hud.catalog = catalog
	hud.teleport_requested.connect(teleport_to)
	hud.shutter_pressed.connect(take_photo)
	hud.refresh()
	truck.position = map.road[0]
	truck.model.heading = map.road_heading(0)
	if not SaveStore.has_flag("tutorial_seen"):
		hud.show_tutorial.call_deferred()
	_qa_hooks.call_deferred()


func _process(_delta: float) -> void:
	if map == null:
		return
	for city in Passport.cities_in_reach(map.towns, truck.position, STAMP_RADIUS):
		if SaveStore.passport.stamp(city):
			hud.toast(tr("STAMP_TOAST") % city)
	hud.set_prompt(tr("ENTER_DIORAMA") if near_diorama() else "")
	for id in _spot_markers:
		var m: Node2D = _spot_markers[id]
		m.visible = truck.position.distance_to(m.position) < SPOT_REVEAL_DISTANCE
	var c := TreeScatter.chunk_of(truck.position, CHUNK_SIZE)
	if c != _last_chunk:
		_last_chunk = c
		_stream_chunks(c)
	_work_queues()


func _unhandled_input(event: InputEvent) -> void:
	if diorama == null and event.is_action_pressed("interact") and near_diorama():
		get_viewport().set_input_as_handled()
		enter_diorama()


## QA only, debug web builds: ?open_sheet=<place id> opens that sheet, to check photos
## without playing to them. Release builds (Pages, itch.io) never run this.
func _qa_hooks() -> void:
	if not (OS.is_debug_build() and OS.has_feature("web")):
		return
	var id: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).get('open_sheet')")
	if typeof(id) == TYPE_STRING and catalog.has(id):
		hud.close_tutorial()
		hud.open_sheet(id)


## ADR 0008 ending: 4 stamps + 4 Madeira-Mamoré photos + the 3 secrets. Shown once;
## afterwards the credits stay in the passport panel.
func check_complete() -> bool:
	var photos := catalog.ids_in_diorama("efmm")
	photos.append_array(catalog.ids_of_kind("secret"))
	if not SaveStore.passport.is_complete(map.stamp_cities(), photos):
		return false
	if not SaveStore.has_flag("completion_seen"):
		SaveStore.set_flag("completion_seen")
		hud.show_complete.call_deferred()
	return true


func near_diorama() -> bool:
	var t := map.town(DIORAMA_TOWN)
	return not t.is_empty() and truck.position.distance_to(t.road_pos) <= DIORAMA_ENTER_RADIUS


## Layer 1 -> layer 2: park the state map (hidden, frozen) and open the diorama.
func enter_diorama() -> void:
	if diorama:
		return
	diorama = DIORAMA_SCENE.instantiate()
	diorama.catalog = catalog
	diorama.hud = hud
	diorama.exit_requested.connect(exit_diorama)
	ground.visible = false
	entities.visible = false
	entities.process_mode = Node.PROCESS_MODE_DISABLED
	set_process(false)
	hud.set_photo_mode(false)
	hud.keys_hint = "DIORAMA_KEYS"
	hud.set_prompt("")
	add_sibling(diorama)
	hud.toast(tr("DIORAMA_WELCOME"))
	hud.refresh()


## Layer 2 -> layer 1: back in the truck where it was parked.
func exit_diorama() -> void:
	if diorama == null:
		return
	diorama.queue_free()
	diorama = null
	SpriteStack.set_view_rotation(get_tree(), 0.0)
	ground.visible = true
	entities.visible = true
	entities.process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)
	hud.set_photo_mode(false)
	hud.keys_hint = "HUD_KEYS"
	hud.set_prompt("")
	var cam: Camera2D = truck.get_node("Camera")
	cam.make_current()
	cam.reset_smoothing()
	hud.refresh()


## Judges a photo through the viewfinder (screen rect) on whichever layer is active.
func take_photo(frame_screen: Rect2) -> PhotoRules.Result:
	var spot := {}
	var result := PhotoRules.Result.NOT_IN_FRAME
	if diorama:
		var shot := diorama.take_photo(frame_screen)
		if not shot.is_empty():
			spot = shot.spot
			result = shot.result
	else:
		var inv := get_viewport().get_canvas_transform().affine_inverse()
		var frame := Rect2(inv * frame_screen.position, frame_screen.size / get_viewport().get_canvas_transform().get_scale())
		spot = PhotoRules.pick_spot(spots, frame)
		if not spot.is_empty():
			result = PhotoRules.evaluate(spot, frame, truck.position)
	if spot.is_empty():
		return PhotoRules.Result.NOT_IN_FRAME   # a photo of the landscape: nothing to record
	var title := catalog.name_of(spot.id, I18n.current())
	if result != PhotoRules.Result.OK:
		hud.toast(tr(PhotoRules.hint_key(result)))
	elif SaveStore.passport.add_photo(spot.id):
		hud.open_sheet(spot.id)   # the sheet itself is the reward; no toast underneath it
	else:
		hud.toast(tr("PHOTO_ALREADY") % title)
	return result


func teleport_to(city: String) -> void:
	var t := map.town(city)
	if t.is_empty() or not SaveStore.passport.has_stamp(city):
		return
	truck.position = t.road_pos
	truck.model.speed = 0.0
	truck.model.heading = map.road_heading(t.road_seg)
	truck.get_node("Camera").reset_smoothing()


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
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 3)
		marker.add_child(label)
		ground.add_child(marker)


## Placeholder glint until each secret gets its own sprite stack.
func _place_spot_markers() -> void:
	for s in spots:
		var glint := Node2D.new()
		glint.position = s.pos
		var diamond := Polygon2D.new()
		diamond.polygon = PackedVector2Array([Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0)])
		diamond.color = Color("fff2a8")
		glint.add_child(diamond)
		var pulse := glint.create_tween().set_loops()
		pulse.tween_property(diamond, "scale", Vector2(1.4, 1.4), 0.6)
		pulse.tween_property(diamond, "scale", Vector2.ONE, 0.6)
		glint.visible = false
		entities.add_child(glint)
		_spot_markers[s.id] = glint


func _stream_chunks(center: Vector2i) -> void:
	var wanted := {}
	for dx in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
		for dy in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
			wanted[center + Vector2i(dx, dy)] = true
	for c in _chunks.keys():
		if not wanted.has(c):
			_to_clear.append_array(_chunks[c])
			_chunks.erase(c)
	_to_plant = _to_plant.filter(func(job): return wanted.has(job[0]))
	var fresh: Array = wanted.keys().filter(func(c): return not _chunks.has(c))
	fresh.sort_custom(func(a, b): return (a - center).length_squared() < (b - center).length_squared())
	for c in fresh:
		_chunks[c] = [] as Array[Node]
		for cand in TreeScatter.candidates(c, CHUNK_SIZE, TREES_PER_CHUNK, WORLD_SEED):
			_to_plant.append([c, cand, false])
		for cand in TreeScatter.candidates(c, CHUNK_SIZE, SHRUBS_PER_CHUNK, WORLD_SEED + 1):
			_to_plant.append([c, cand, true])


## Plants and clears a bounded amount each frame.
func _work_queues(plant_budget: int = PLANTS_PER_FRAME) -> void:
	var cleared := 0
	while not _to_clear.is_empty() and cleared < CLEARS_PER_FRAME:
		var n: Node = _to_clear.pop_back()
		if is_instance_valid(n):
			n.queue_free()
		cleared += 1
	var planted := 0
	while not _to_plant.is_empty() and planted < plant_budget:
		var job: Array = _to_plant.pop_front()
		planted += 1
		if not _chunks.has(job[0]):
			continue
		var cand: Dictionary = job[1]
		var h: Variant = _habitat_at(cand.pos)
		if h == null:
			continue
		var species := ""
		if job[2]:
			species = "shrub" if forest.shrub_at(h, cand.pos, cand.keep) else ""
		else:
			species = forest.tree_at(h, cand.pos, cand.keep, cand.species)
		if not species.is_empty():
			_chunks[job[0]].append(_plant(species, cand))


## Builds every queued chunk now (tests and teleports).
func flush_forest() -> void:
	while not _to_plant.is_empty() or not _to_clear.is_empty():
		_work_queues(1 << 30)


## Forest habitat at p, or null where nothing may grow (outside the state, on the
## road and its shoulders, in a river).
func _habitat_at(p: Vector2) -> Variant:
	if not is_inside_state(p):
		return null
	var road_d := road_index.distance_within(p, Forest.PASTURE_DISTANCE)
	if road_d < ROAD_TREE_CLEARANCE:
		return null
	var river_d := river_index.distance_within(p, Forest.RIVERSIDE_DISTANCE)
	if river_d < RIVER_HALF_WIDTH + 8.0:
		return null
	return Forest.habitat(road_d, river_d)


func _plant(species: String, cand: Dictionary) -> SpriteStack:
	if not _sheets.has(species):
		_sheets[species] = load("res://assets/stacks/%s/%s_slices.png" % [species, species])
	var s := SpriteStack.new()
	s.sheet = _sheets[species]
	s.slice_count = Forest.SLICES[species]
	s.angle = cand.angle
	s.position = cand.pos
	entities.add_child(s)
	return s

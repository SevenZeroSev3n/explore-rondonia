extends Node2D
## Layer 1: the whole state, from game/data/geo/state_map.json (ADR 0002/0003).
## North-up; trees are streamed in chunks around the truck.

const ASPHALT_HALF_WIDTH := 22.0
const SHOULDER_HALF_WIDTH := 30.0
const ROAD_TREE_CLEARANCE := 70.0
const RIVER_HALF_WIDTH := 4.0
const CHUNK_SIZE := 512.0
const CHUNK_RADIUS := 1          ## chunks kept around the truck's chunk in each direction
const TREES_PER_CHUNK := 300
const SHRUBS_PER_CHUNK := 130
const DECALS_PER_CHUNK := 260   ## flat ground details (ADR 0009)
const ANIMAL_SPOTS_PER_CHUNK := 10
## Fences (ADR 0009): barbed wire on both sides of BR-364 through the pastures.
const FENCE_OFFSET := 84.0
const FENCE_SPACING := 26.0
const FENCE_TOWN_GAP := 300.0       ## no fences inside towns
const WIRE := Color(0.72, 0.72, 0.7, 0.85)
## Fuel (ADR 0009): stations at the towns, free refills, a tow when the tank runs dry.
const STATION_SETBACK := 64.0
const STATION_CLEARANCE := 72.0     ## nothing grows on the forecourt
const STATION_REFUEL_RADIUS := 70.0
const FILL_RATE := 125.0            ## km of range per second at the pump
const LOW_FUEL := 0.2
const TOW_DELAY := 2.5              ## seconds stopped on an empty tank before the tow
## Planting and clearing are spread over frames so crossing a chunk border never
## stalls a frame (hundreds of stacks per chunk; the web build is slower than native).
const PLANTS_PER_FRAME := 90
const CLEARS_PER_FRAME := 200
const WORLD_SEED := 364
const STAMP_RADIUS := 93.0
const SPOT_REVEAL_DISTANCE := 667.0   ## secrets show a glint only when you are near
const DIORAMA_SCENE := preload("res://scenes/diorama_efmm.tscn")
const DIORAMA_TOWN := "Porto Velho"
const DIORAMA_ENTER_RADIUS := 147.0

const OUTSIDE := Color("2f4a2c")
const RIVER := Color("4f86b8")
const DIRT := Color("9c4a2f")
const ASPHALT := Color("4a4a50")
const STRIPE := Color("e8c64a")
const GROUND_TILE := preload("res://assets/ground/pasture_tile.png")

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
var progress: RoadProgress            ## km along BR-364 (ADR 0009)
var stations: Array[Dictionary] = []  ## FuelStations.from_towns
var tank := FuelTank.new()
var _last_truck_pos := Vector2.ZERO
var _tow_timer := -1.0
var _low_warned := false
var _refuelling := false              ## a real refill is under way (not a top-up of a few metres)

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
	progress = RoadProgress.new(map.road, map.towns[-1].road_km if not map.towns.is_empty() else 0.0)
	stations = FuelStations.from_towns(map.towns, map.road, STATION_SETBACK)
	_preload_sheets()
	_draw_ground()
	_place_towns()
	_place_stations()
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
	_last_truck_pos = truck.position
	hud.setup_trip(map, stations)
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
	_update_fuel(_delta)
	_update_trip_hud()
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
	hud.set_trip_visible(false)
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
	hud.set_trip_visible(true)
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
	_last_truck_pos = truck.position
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
	land.texture = GROUND_TILE                      # no UVs: the tile repeats in world pixels
	land.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.add_child(land)

	for r in map.rivers:
		ground.add_child(_line(r.points, RIVER_HALF_WIDTH * 2.0, RIVER))
	ground.add_child(_line(map.road, SHOULDER_HALF_WIDTH * 2.0, DIRT))
	ground.add_child(_line(map.road, ASPHALT_HALF_WIDTH * 2.0, ASPHALT))
	ground.add_child(_line(map.road, 2.0, STRIPE))


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
		var r := 9.0 if t.stamp else 5.0
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
		_to_plant.append([c, null, "decals"])
		_to_plant.append([c, null, "fauna"])
		_to_plant.append([c, null, "fences"])


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
		if typeof(job[2]) == TYPE_STRING:
			match job[2]:
				"decals": _chunks[job[0]].append(_decals_for(job[0]))
				"fauna": _chunks[job[0]].append_array(_fauna_for(job[0]))
				"fences": _chunks[job[0]].append_array(_fences_for(job[0]))
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
	for st in stations:
		if p.distance_to(st.pos) < STATION_CLEARANCE:
			return null
	var road_d := road_index.distance_within(p, Forest.PASTURE_DISTANCE)
	if road_d < ROAD_TREE_CLEARANCE:
		return null
	var river_d := river_index.distance_within(p, Forest.RIVERSIDE_DISTANCE)
	if river_d < RIVER_HALF_WIDTH + 11.0:
		return null
	return Forest.habitat(road_d, river_d)


## One node with every ground decal of a chunk, under the entities (ADR 0009).
func _decals_for(chunk: Vector2i) -> GroundDecals:
	var d := GroundDecals.new()
	for cand in TreeScatter.candidates(chunk, CHUNK_SIZE, DECALS_PER_CHUNK, WORLD_SEED + 2):
		if not is_inside_state(cand.pos):
			continue
		var road_d := road_index.distance_within(cand.pos, Forest.PASTURE_DISTANCE)
		if road_d < SHOULDER_HALF_WIDTH + 4.0:
			continue
		var river_d := river_index.distance_within(cand.pos, Forest.RIVERSIDE_DISTANCE)
		if river_d < RIVER_HALF_WIDTH + 3.0:
			continue
		d.add(cand.pos, Forest.pick(GroundDecals.MIX[Forest.habitat(road_d, river_d)], cand.species))
	ground.add_child(d)
	return d


func _plant(species: String, cand: Dictionary) -> SpriteStack:
	if not _sheets.has(species):
		_sheets[species] = load("res://assets/stacks/%s/%s_slices.png" % [species, species])
	var s := SpriteStack.new()
	s.sheet = _sheets[species]
	s.slice_count = Forest.SLICES[species]
	s.angle = cand.angle
	s.position = cand.pos
	# A slight per-tree tint so neighbours of one species never look stamped (ADR 0009).
	var f := fposmod(cand.pos.x * 0.1373 + cand.pos.y * 0.3119, 1.0)
	var v := 0.86 + f * 0.14
	s.modulate = Color(v * (0.97 + 0.03 * f), v, v * (1.0 - 0.04 * f))
	entities.add_child(s)
	return s


## Loads every streamed sheet up front: loading one the first time a species shows up
## mid-drive costs a visible hitch.
func _preload_sheets() -> void:
	var names: Array = Forest.SLICES.keys() + Fauna.SLICES.keys() + ["fence_post", "fuel_station"]
	for n in names:
		if not _sheets.has(n):
			_sheets[n] = load("res://assets/stacks/%s/%s_slices.png" % [n, n])


func _stack(stack_name: String, slices: int, pos: Vector2, angle: float) -> SpriteStack:
	if not _sheets.has(stack_name):
		_sheets[stack_name] = load("res://assets/stacks/%s/%s_slices.png" % [stack_name, stack_name])
	var s := SpriteStack.new()
	s.sheet = _sheets[stack_name]
	s.slice_count = slices
	s.angle = angle
	s.position = pos
	entities.add_child(s)
	return s


## Static animals (ADR 0009): Nelore herds in the pastures, capybaras on the riverbanks.
func _fauna_for(chunk: Vector2i) -> Array[Node]:
	var out: Array[Node] = []
	for cand in TreeScatter.candidates(chunk, CHUNK_SIZE, ANIMAL_SPOTS_PER_CHUNK, WORLD_SEED + 3):
		var h: Variant = _habitat_at(cand.pos)
		if h == null:
			continue
		for a in Fauna.group(h, cand.pos, cand.keep, cand.species):
			if _habitat_at(a.pos) == null:
				continue
			if road_index.distance_within(a.pos, FENCE_OFFSET + 10.0) < FENCE_OFFSET + 10.0:
				continue   # behind the fence, never on the verge
			out.append(_stack(a.species, Fauna.SLICES[a.species], a.pos, a.angle))
	return out


## Fence posts with two strands of wire to the next post, in the pasture belt only.
func _fences_for(chunk: Vector2i) -> Array[Node]:
	var out: Array[Node] = []
	var rect := Rect2(Vector2(chunk) * CHUNK_SIZE, Vector2(CHUNK_SIZE, CHUNK_SIZE))
	var near_road := func(q: Vector2) -> float: return road_index.distance_within(q, FENCE_OFFSET)
	for p in Roadside.fence_posts(map.road, rect, FENCE_OFFSET, FENCE_SPACING, near_road):
		if not _fence_ok(p.pos):
			continue
		var post := _stack("fence_post", 10, p.pos, 0.0)
		var next: Vector2 = p.next
		if next.distance_to(p.pos) < FENCE_SPACING * 1.6 and _fence_ok(next):
			for lift in [4.0, 7.0]:
				var wire := Line2D.new()
				wire.points = PackedVector2Array([Vector2(0, -lift), next - p.pos + Vector2(0, -lift)])
				wire.width = 1.0
				wire.default_color = WIRE
				post.add_child(wire)
		out.append(post)
	return out


func _fence_ok(p: Vector2) -> bool:
	if not is_inside_state(p):
		return false
	if river_index.distance_within(p, RIVER_HALF_WIDTH + 24.0) < RIVER_HALF_WIDTH + 24.0:
		return false
	for t in map.towns:
		if p.distance_to(t.road_pos) < FENCE_TOWN_GAP:
			return false
	return true


func _place_stations() -> void:
	for st in stations:
		_stack("fuel_station", 24, st.pos, st.angle)


func _station_near(p: Vector2) -> Dictionary:
	for st in stations:
		if p.distance_to(st.pos) <= STATION_REFUEL_RADIUS:
			return st
	return {}


## Burns fuel with distance, refills at a station when stopped, tows on an empty tank.
func _update_fuel(delta: float) -> void:
	var moved := truck.position.distance_to(_last_truck_pos)
	_last_truck_pos = truck.position
	if moved < 200.0:   # a teleport or a tow is not driving
		tank.burn_km(moved / (map.px_per_m * 1000.0))
	var st := _station_near(truck.position)
	var stopped_at_pump := not st.is_empty() and absf(truck.model.speed) < 6.0
	if stopped_at_pump and tank.fraction() < 0.95:
		_refuelling = true
	if stopped_at_pump and _refuelling:
		tank.fill_step(delta, FILL_RATE)
		if tank.is_full():
			_refuelling = false
			hud.toast(tr("FUEL_FULL") % st.town)
	elif not stopped_at_pump:
		_refuelling = false
	if tank.fraction() > 0.5:
		_low_warned = false
	elif tank.fraction() < LOW_FUEL and not _low_warned and not tank.is_empty():
		_low_warned = true
		var km := progress.km_at(truck.position)
		var ahead := FuelStations.next_ahead(stations, km)
		if ahead.is_empty():
			ahead = FuelStations.nearest(stations, km)
		hud.toast(tr("FUEL_LOW") % [ahead.town, roundi(absf(ahead.road_km - km))])
	truck.engine_on = not tank.is_empty()
	if not tank.is_empty():
		_tow_timer = -1.0
	elif _tow_timer < 0.0:
		_tow_timer = TOW_DELAY
		hud.toast(tr("FUEL_EMPTY"))
	else:
		_tow_timer -= delta
		if _tow_timer <= 0.0:
			tow()


## ADR 0009: the soft setback. A tow truck takes you to the nearest station, tank full.
func tow() -> void:
	var st := FuelStations.nearest(stations, progress.km_at(truck.position))
	if st.is_empty():
		tank.fill()
		return
	truck.position = progress.point_at_km(st.road_km)
	_last_truck_pos = truck.position
	truck.model.speed = 0.0
	truck.model.heading = map.road_heading(map.town(st.town).get("road_seg", 0))
	truck.get_node("Camera").reset_smoothing()
	tank.fill()
	truck.engine_on = true
	_tow_timer = -1.0
	hud.toast(tr("FUEL_TOWED") % st.town)


func _update_trip_hud() -> void:
	var km := progress.km_at(truck.position)
	var next := {}
	for t in map.towns:
		if t.road_km > km + 0.5:
			next = t
			break
	hud.update_trip({
		"kmh": absf(truck.model.kmh()),
		"fuel": tank.fraction(),
		"pos": truck.position,
		"heading": truck.model.heading,
		"km": km,
		"next_town": next.get("name", ""),
		"next_km": maxf(0.0, next.get("road_km", km) - km),
		"end_town": map.towns[-1].name if not map.towns.is_empty() else "",
		"end_km": maxf(0.0, progress.total_km - km),
	})

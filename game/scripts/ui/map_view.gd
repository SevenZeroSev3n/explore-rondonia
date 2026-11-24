class_name MapView
extends Control
## The state map drawn small (ADR 0009): the outline of Rondônia, BR-364, towns, petrol
## stations and the truck. The minimap uses it plain; the full map (M) turns on `detailed`
## for rivers and town names. Everything is drawn in _draw from the map data.

const LAND := Color("2f4a2c")
const EDGE := Color("6f8f5a")
const ROAD := Color("e8c64a")
const RIVER := Color("4f86b8")
const TOWN := Color("e8e4d8")
const STAMP := Color("f2d04a")
const STATION := Color("d8503c")
const PLAYER := Color.WHITE
const LABEL_SIZE := 13   ## small map labels; the HUD text is 18 (ADR 0005)

var map: StateMapData
var stations: Array[Dictionary] = []
var detailed := false
var player := Vector2.ZERO
var heading := 0.0

var _xf := Transform2D.IDENTITY   ## world -> local
var _blink := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit)
	_fit()


func set_player(pos: Vector2, heading_rad: float) -> void:
	player = pos
	heading = heading_rad
	queue_redraw()


func _process(delta: float) -> void:
	_blink = fmod(_blink + delta, 1.0)
	if is_visible_in_tree():
		queue_redraw()


## Scales the state's bounding box into the control, centred, with a small margin.
func _fit() -> void:
	if map == null or map.border.is_empty() or size.x <= 0.0:
		return
	var box := Rect2(map.border[0], Vector2.ZERO)
	for p in map.border:
		box = box.expand(p)
	var k := minf((size.x - 8.0) / box.size.x, (size.y - 8.0) / box.size.y)
	var offset := size / 2.0 - box.get_center() * k
	_xf = Transform2D(0.0, Vector2(k, k), 0.0, offset)
	queue_redraw()


func to_local_map(world: Vector2) -> Vector2:
	return _xf * world


func _draw() -> void:
	if map == null:
		return
	draw_colored_polygon(_xf * map.border, LAND)
	var outline := _xf * map.border
	outline.append(outline[0])
	draw_polyline(outline, EDGE, 1.0)
	if detailed:
		for r in map.rivers:
			draw_polyline(_xf * r.points, RIVER, 1.0)
	draw_polyline(_xf * map.road, ROAD, 2.0 if detailed else 1.0)
	var font := get_theme_default_font()
	for t in map.towns:
		var p := (_xf * (t.road_pos as Vector2)).round()
		var r := 3.0 if t.stamp else 2.0
		if not detailed and not t.stamp:
			continue
		draw_circle(p, r + 1.0, Color.BLACK)
		draw_circle(p, r, STAMP if t.stamp else TOWN)
		if detailed and t.stamp:   # only the passport cities are named: the rest crowd the road
			var text: String = t.name
			var pos := p + Vector2(6, 4)
			draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, 3, Color.BLACK)
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, STAMP if t.stamp else TOWN)
	# Stations stand at the towns, so their marker sits just above-right of the town dot.
	for st in stations:
		var p := (_xf * (st.pos as Vector2)).round() + Vector2(4, -5)
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color.BLACK)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), STATION)
	_draw_player(font)


func _draw_player(_font: Font) -> void:
	var p := (_xf * player).round()
	var fwd := Vector2(sin(heading), -cos(heading))
	var side := Vector2(-fwd.y, fwd.x)
	var s := 5.0 if detailed else 4.0
	var tri := PackedVector2Array([p + fwd * s, p - fwd * s * 0.7 + side * s * 0.7, p - fwd * s * 0.7 - side * s * 0.7])
	draw_colored_polygon(tri, Color.BLACK if _blink > 0.5 else PLAYER)
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color.BLACK, 1.0)

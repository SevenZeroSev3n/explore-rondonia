@tool
class_name SpriteStack
extends Node2D
## Draws a slice sheet as a sprite stack (docs/reference/sprite-stacking-guide.md).
## Sheet: one row, ground slice on the left, art facing up (-Y).

@export var sheet: Texture2D:
	set(v):
		sheet = v
		queue_redraw()
@export var slice_count: int = 1:
	set(v):
		slice_count = maxi(v, 1)
		queue_redraw()
## Screen pixels between slices.
@export var spacing: float = 1.0:
	set(v):
		spacing = v
		queue_redraw()
## Vertical squash that fakes the camera tilt; below 0.6 roofs look paper-thin.
@export_range(0.5, 1.0, 0.05) var squash: float = 0.75:
	set(v):
		squash = v
		queue_redraw()
## Facing in radians; 0 = art facing up (north). Positive turns clockwise.
@export var angle: float = 0.0:
	set(v):
		if is_equal_approx(v, angle):
			return
		angle = v
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	if sheet == null:
		return
	var w := float(sheet.get_width()) / slice_count
	var h := float(sheet.get_height())
	var dest := Rect2(-w / 2.0, -h / 2.0, w, h)
	for z in slice_count:
		var xf := Transform2D(angle, Vector2.ZERO).scaled(Vector2(1.0, squash))
		xf.origin = Vector2(0.0, -roundf(z * spacing))
		draw_set_transform_matrix(xf)
		draw_texture_rect_region(sheet, dest, Rect2(z * w, 0.0, w, h))
	draw_set_transform_matrix(Transform2D.IDENTITY)

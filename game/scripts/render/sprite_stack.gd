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
## Rotation of the view (camera), shared by every stack: dioramas rotate it, the
## north-up state map keeps it at 0 (ADR 0002). Change it through set_view_rotation().
static var view_rotation := 0.0

const GROUP := "sprite_stacks"

## Facing in radians; 0 = art facing up (north). Positive turns clockwise.
@export var angle: float = 0.0:
	set(v):
		if is_equal_approx(v, angle):
			return
		angle = v
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group(GROUP)


## Sets the camera rotation (radians, as Camera2D.rotation) and redraws every stack.
static func set_view_rotation(tree: SceneTree, camera_rotation: float) -> void:
	if is_equal_approx(view_rotation, camera_rotation):
		return
	view_rotation = camera_rotation
	tree.call_group(GROUP, "queue_redraw")


## Local transform of one slice so that, after the camera rotates the canvas by
## -camera_rotation, the slice shows the object turned by (angle - camera_rotation),
## squashed along the SCREEN vertical and lifted straight up on screen.
static func slice_transform(angle: float, camera_rotation: float, squash: float, lift: float) -> Transform2D:
	var undo_view := Transform2D(camera_rotation, Vector2.ZERO)
	var squash_xf := Transform2D(Vector2(1, 0), Vector2(0, squash), Vector2.ZERO)
	var xf := undo_view * squash_xf * Transform2D(angle - camera_rotation, Vector2.ZERO)
	xf.origin = Vector2(0.0, -lift).rotated(camera_rotation)
	return xf


func _draw() -> void:
	if sheet == null:
		return
	var w := float(sheet.get_width()) / slice_count
	var h := float(sheet.get_height())
	var dest := Rect2(-w / 2.0, -h / 2.0, w, h)
	for z in slice_count:
		draw_set_transform_matrix(slice_transform(angle, view_rotation, squash, roundf(z * spacing)))
		draw_texture_rect_region(sheet, dest, Rect2(z * w, 0.0, w, h))
	draw_set_transform_matrix(Transform2D.IDENTITY)

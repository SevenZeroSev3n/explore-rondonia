class_name PhotoRules
extends RefCounted
## When does a photo count? (ADR 0008) The spot must be fully in the frame,
## the viewer close enough, and the viewer standing inside the spot's angle
## window. Pass/fail only, with a hint saying which rule failed.

enum Result { OK, NOT_IN_FRAME, TOO_FAR, WRONG_ANGLE }


## spot: {pos: Vector2, radius: float, max_distance: float, view_from_deg: float, window_half_deg: float}
## frame: the viewfinder rectangle in world coordinates. viewer: where the photographer stands.
static func evaluate(spot: Dictionary, frame: Rect2, viewer: Vector2) -> Result:
	var pos: Vector2 = spot.pos
	var r: float = spot.radius
	var in_frame := frame.encloses(Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0))
	return judge(spot, in_frame, viewer.distance_to(pos), angle_off(spot, viewer))


## The rule itself, once each measurement is known. Layer 1 measures in world space
## (north-up, the viewer is the truck); dioramas measure the frame on screen and the
## angle from the rotating camera (see eye_bearing_deg).
static func judge(spot: Dictionary, in_frame: bool, distance: float, off_deg: float) -> Result:
	if not in_frame:
		return Result.NOT_IN_FRAME
	if distance > spot.max_distance:
		return Result.TOO_FAR
	if off_deg > spot.window_half_deg:
		return Result.WRONG_ANGLE
	return Result.OK


## Compass bearing (0 = north) of the side the camera looks from: the bottom of the
## screen, for a Camera2D rotated by camera_rotation.
static func eye_bearing_deg(camera_rotation: float) -> float:
	var down := Vector2(0, 1).rotated(camera_rotation)
	return fposmod(rad_to_deg(atan2(down.x, -down.y)), 360.0)


static func bearing_off(spot: Dictionary, bearing_deg: float) -> float:
	return absf(wrapf(bearing_deg - spot.view_from_deg, -180.0, 180.0))


## Degrees between where the viewer stands (seen from the spot) and the spot's ideal side.
static func angle_off(spot: Dictionary, viewer: Vector2) -> float:
	var d := viewer - (spot.pos as Vector2)
	if d.length_squared() < 0.0001:
		return 0.0   # standing on it: any angle is fine
	var bearing := rad_to_deg(atan2(d.x, -d.y))
	return absf(wrapf(bearing - spot.view_from_deg, -180.0, 180.0))


## The spot to judge: the one closest to the frame centre that at least overlaps the frame.
static func pick_spot(spots: Array, frame: Rect2) -> Dictionary:
	var best := {}
	var best_d := INF
	var centre := frame.get_center()
	for s in spots:
		var r: float = s.radius
		if not frame.intersects(Rect2((s.pos as Vector2) - Vector2(r, r), Vector2(r, r) * 2.0)):
			continue
		var d := centre.distance_to(s.pos)
		if d < best_d:
			best_d = d
			best = s
	return best


static func hint_key(result: Result) -> String:
	match result:
		Result.NOT_IN_FRAME: return "PHOTO_HINT_FRAME"
		Result.TOO_FAR: return "PHOTO_HINT_CLOSER"
		Result.WRONG_ANGLE: return "PHOTO_HINT_ANGLE"
	return ""

class_name Traveler
extends CharacterBody2D
## The player on foot in a diorama (layer 2, ADR 0008). Moves relative to the
## SCREEN, so "up" stays up however the camera is turned.

const SPEED := 46.0

## Camera rotation to move relative to. Set by the diorama every frame.
var view_rotation := 0.0

@onready var stack: SpriteStack = $Stack


func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left"),
		Input.get_action_strength("brake") - Input.get_action_strength("accelerate"))
	velocity = move_direction(input, view_rotation) * SPEED
	move_and_slide()
	if velocity.length_squared() > 1.0:
		stack.angle = atan2(velocity.x, -velocity.y)
	stack.position = global_position.round() - global_position


## Screen-space input (up = -y) turned into a world direction for a camera rotated by view_rot.
static func move_direction(input: Vector2, view_rot: float) -> Vector2:
	if input.length_squared() < 0.01:
		return Vector2.ZERO
	return input.limit_length(1.0).rotated(view_rot)

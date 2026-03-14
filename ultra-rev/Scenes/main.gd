extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$PlayerWrap/Player.set_meta("fov", 90.0)
	pass # Replace with function body.

extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_instance_valid($Player):
		global_position = $Player.global_position-Vector3(0,0.5,0)

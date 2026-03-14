extends CharacterBody3D


const SPEED = 7.0
const SPRINT_BOOST = 2.0
# Lerp weight for movement acceleration
const SPEED_WEIGHT = 0.1
# Lerp weight for sprint fov stretch
const FOV_STRETCH_WEIGHT = 0.3
# Lerp weight for cam tilt when moving
const CAM_TILT_WEIGHT = 0.05
const JUMP_VELOCITY = 4.5
const SENSITIVITY_CONSTANT = .003

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion = event.screen_relative
		#var target = get_viewport().get_visible_rect().get_center() + motion
		$"Main Camera".rotate_x(-motion.y * SENSITIVITY_CONSTANT)
		#rotate_y(-motion.x * SENSITIVITY_CONSTANT)
		get_parent().rotate_y(-motion.x * SENSITIVITY_CONSTANT)
		$"Main Camera".rotation.x = clamp($"Main Camera".rotation.x, -PI/2, PI/2)


func _process(delta: float) -> void:
	# Fov stretch while sprinting
	if get_meta("sprinting"):
		$"Main Camera".fov = lerp($"Main Camera".fov, get_meta("fov") + 15, FOV_STRETCH_WEIGHT * delta * 120)
	else:
		$"Main Camera".fov = lerp($"Main Camera".fov, get_meta("fov"), FOV_STRETCH_WEIGHT * delta * 120)


func _physics_process(delta: float) -> void:
	# Add the gravity and resets double jump
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		set_meta("doubleJump", true)

	# Handle jump and double jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("ui_accept") and get_meta("doubleJump"):
		velocity.y = JUMP_VELOCITY * 1.25
		set_meta("doubleJump", false)
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Direction points in the movement direction relative to the player
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle Sprinting, scales the forward component of direction by SPRINT_BOOST when holding shift and moving forward
	# Also boosts FOV while sprinting
	if Input.is_action_pressed("sprint") and direction.dot(Vector3.FORWARD) > 0:
		direction += (SPRINT_BOOST - 1) * direction.dot(Vector3.FORWARD) * Vector3.FORWARD
		set_meta("sprinting", true)
	else:
		set_meta("sprinting", false)
	
	# Changing player velocity based on direction, and also handles acceleration
	if direction:
		velocity = velocity.lerp(Vector3(direction.x * SPEED, velocity.y, direction.z * SPEED).rotated(Vector3.UP, get_parent().rotation.y), SPEED_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	else:
		velocity = velocity.lerp(Vector3(0, velocity.y, 0), SPEED_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	
	# Camera lean for side to side movement
	var target = -direction.x * PI/30
	if direction.x:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(get_parent().rotation.x, get_parent().rotation.y, target), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	else:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(get_parent().rotation.x, get_parent().rotation.y, 0), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	
	# Camera lean for front to back movement
	target = direction.z * PI/30
	if direction.z:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(target, get_parent().rotation.y, get_parent().rotation.z), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	else:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(0, get_parent().rotation.y, get_parent().rotation.z), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	
	# Move player then reset wrapper position to the players location
	move_and_slide()
	var pos = global_position
	get_parent().global_position = global_position-Vector3(0,0.5,0)
	global_position = pos

class_name Player
extends CharacterBody3D

@export var FOV : float = 90.0
#var sprinting = false
var double_jump = false

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
	var v_forward = -velocity.rotated(Vector3.UP,-get_parent().rotation.y).z
	# Fov raises exponentially towards +8 when forward velocity approches max sprint speed, 
	# and decreases linearly as backward velocity increases
	var fov_target = FOV + clamp(exp(log(9)*v_forward/14)-1 if v_forward >= 0 else log(9) * v_forward / 14, -15, 15)
	if not is_zero_approx(velocity.z):
		$"Main Camera".fov = lerp($"Main Camera".fov, fov_target, FOV_STRETCH_WEIGHT * delta * 120)
	else:
		$"Main Camera".fov = lerp($"Main Camera".fov, FOV, FOV_STRETCH_WEIGHT * delta * 120)


func _physics_process(delta: float) -> void:
	# Update player movement/velocity
	_player_movement_update(delta)
	if Input.is_action_pressed("grapple"):
		_grapple(delta)
	# Move player then reset wrapper position to the players location
	move_and_slide()
	var pos = global_position
	get_parent().global_position = global_position-Vector3(0,0.5,0)
	global_position = pos

func _player_movement_update(delta: float) -> void:
	# Add the gravity and resets double jump
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		double_jump = true

	# Handle jump and double jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("ui_accept") and double_jump:
		velocity.y = JUMP_VELOCITY * 1.25
		double_jump = false
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Direction points in the movement direction relative to the player
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle Sprinting, scales the forward component of direction by SPRINT_BOOST when holding shift and moving forward
	# Also boosts FOV while sprinting
	if Input.is_action_pressed("sprint") and direction.dot(Vector3.FORWARD) > 0:
		direction += (SPRINT_BOOST - 1) * direction.dot(Vector3.FORWARD) * Vector3.FORWARD
		#sprinting = true
	#else:
		#sprinting = false
	
	# Changing player velocity based on direction, and also handles acceleration
	if direction:
		velocity = velocity.lerp(Vector3(direction.x * SPEED, velocity.y, direction.z * SPEED).rotated(Vector3.UP, get_parent().rotation.y), SPEED_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	else:
		velocity = velocity.lerp(Vector3(0, velocity.y, 0), SPEED_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	
	# Camera lean for side to side movement, maxes at 10 degrees in either direction
	var target = clamp(-direction.x * PI/45, -PI/36, PI/36)
	if direction.x:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(get_parent().rotation.x, get_parent().rotation.y, target), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	else:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(get_parent().rotation.x, get_parent().rotation.y, 0), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	
	# Camera lean for front to back and vertical movement, maxes at 10 degrees for front to back, and 20 degrees for vertical
	target = clamp(direction.z * PI/45, -PI/36, PI/36)
	target += clamp(exp(-velocity.y*log(1+PI/18)/4.5)-1 if velocity.y>0 else -exp(velocity.y*log(1+PI/36)/4.5)+1, -PI/18, PI/18)
	if direction.z or velocity.y:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(target, get_parent().rotation.y, get_parent().rotation.z), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	else:
		get_parent().rotation = get_parent().rotation.lerp(Vector3(0, get_parent().rotation.y, get_parent().rotation.z), CAM_TILT_WEIGHT * delta * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))



func _grapple(delta: float) -> void:
	var space_state : PhysicsDirectSpaceState3D = $"Main Camera".get_world_3d().direct_space_state
	var screen_center : Vector2 = get_viewport().size/2
	var origin : Vector3 = $"Main Camera".project_ray_origin(screen_center)
	var end : Vector3 = origin + $"Main Camera".project_ray_normal(screen_center) * 20
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	var result := space_state.intersect_ray(query)
	#if result["collider"] == StaticBody3D:
		
	

extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.8
@export var jump_velocity: float = 4.0

var _rotation_x: float = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	# Ensure mouse is captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Register movement input mappings if they do not exist
	_ensure_input_action("move_forward", KEY_W)
	_ensure_input_action("move_backward", KEY_S)
	_ensure_input_action("move_left", KEY_A)
	_ensure_input_action("move_right", KEY_D)
	_ensure_input_action("jump", KEY_SPACE)

func _ensure_input_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate character horizontally (yaw)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate head vertically (pitch)
		_rotation_x = clamp(_rotation_x - event.relative.y * mouse_sensitivity, deg_to_rad(-85), deg_to_rad(85))
		head.rotation.x = _rotation_x

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Get input direction and handle movement
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Fall respawn check: if the player falls under -30, teleport them back to the starting position
	if global_position.y < -30.0:
		var spawn_pos: Vector3 = get_meta("spawn_point", Vector3(0, 1.0, 0))
		global_position = spawn_pos
		velocity = Vector3.ZERO

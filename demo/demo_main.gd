extends Node3D

@export var player_scene: PackedScene
@export var auto_spawn_player: bool = true

@onready var generator: DungeonGenerator3D = $DungeonGenerator
@onready var ui_canvas: CanvasLayer = $CanvasLayer
@onready var generate_btn: Button = $CanvasLayer/Control/MenuPanel/MarginContainer/VBoxContainer/GenerateButton
@onready var status_label: Label = $CanvasLayer/Control/MenuPanel/MarginContainer/VBoxContainer/StatusLabel

var _player_instance: CharacterBody3D = null

func _ready() -> void:
	# Clean up any existing instances on startup
	for child in get_children():
		if child is CharacterBody3D:
			child.queue_free()

	generator.generation_completed.connect(_on_dungeon_generated)
	generator.generation_failed.connect(_on_dungeon_failed)
	
	if generate_btn:
		generate_btn.pressed.connect(_on_generate_pressed)
	
	# Automatically generate dungeon on start
	_generate_new_dungeon()

func _on_generate_pressed() -> void:
	_generate_new_dungeon()

func _generate_new_dungeon() -> void:
	if _player_instance:
		_player_instance.queue_free()
		_player_instance = null
	
	# Free cursor during generation
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if status_label:
		status_label.text = "Generating Dungeon..."
		status_label.modulate = Color(1.0, 1.0, 1.0) # White

	generator.generate()

func _on_dungeon_generated(_dungeon_root: Node3D) -> void:
	if status_label:
		status_label.text = "Dungeon Generated successfully! Click viewport to play."
		status_label.modulate = Color(0.2, 0.9, 0.2) # Green
	
	if auto_spawn_player and player_scene:
		_spawn_player()

func _on_dungeon_failed(reason: String) -> void:
	if status_label:
		status_label.text = "Generation Failed: " + reason
		status_label.modulate = Color(0.9, 0.2, 0.2) # Red

func _spawn_player() -> void:
	var spawn_pos := Vector3(0, 1.0, 0)
	
	var active_graph := generator.active_graph
	if active_graph and not active_graph.placements.is_empty():
		var entrance: Dictionary = active_graph.placements[0]
		spawn_pos = entrance.world_transform.origin + Vector3(0, 1.0, 0)
		print("Spawning player at Entrance position: ", spawn_pos)
	else:
		print("No active graph or placements found, spawning at default: ", spawn_pos)

	_player_instance = player_scene.instantiate() as CharacterBody3D
	_player_instance.global_position = spawn_pos
	_player_instance.set_meta("spawn_point", spawn_pos)
	add_child(_player_instance)

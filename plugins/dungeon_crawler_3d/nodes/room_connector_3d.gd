@tool
class_name RoomConnector3D
extends Node3D

@export var connection_type: String = "":
	set(value):
		connection_type = value
		if Engine.is_editor_hint():
			update_gizmos()

@export var is_locked: bool = false:
	set(value):
		is_locked = value
		if Engine.is_editor_hint():
			update_gizmos()

@export var key_id: String = "":
	set(value):
		key_id = value
		if Engine.is_editor_hint():
			update_gizmos()

@export var doorway_scene: PackedScene
@export var blocker_scene: PackedScene


func _get_gizmo_color() -> Color:
	if is_locked:
		return Color.MAGENTA
	match connection_type:
		"":
			return Color.GRAY
		"standard_door":
			return Color.SKY_BLUE
		"large_gate":
			return Color.ORANGE
		_:
			return Color.GREEN_YELLOW


func _validate_property(property: Dictionary) -> void:
	if property.name == "connection_type":
		if connection_type.is_empty():
			property.hint_string = "Must not be empty"


func _ready() -> void:
	if Engine.is_editor_hint():
		update_gizmos()

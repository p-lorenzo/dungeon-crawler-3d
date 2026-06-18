@tool
class_name RoomConnector3D
extends Node3D

@export var connection_type: String = ""


func _get_gizmo_color() -> Color:
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

class_name KeyLockAssignment
extends RefCounted

var connector_index: int = -1
var spawn_point_path: NodePath = NodePath()
var key_id: String = ""


func _init(p_connector_index: int = -1, p_spawn_point_path: NodePath = NodePath(), p_key_id: String = "") -> void:
	connector_index = p_connector_index
	spawn_point_path = p_spawn_point_path
	key_id = p_key_id

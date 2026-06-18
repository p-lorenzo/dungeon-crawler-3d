@tool
extends EditorPlugin

const RoomConnector3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd")
const DungeonGenerator3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd")


func _enter_tree() -> void:
	add_custom_type("RoomConnector3D", "Node3D", RoomConnector3DScript, null)
	add_custom_type("DungeonGenerator3D", "Node3D", DungeonGenerator3DScript, null)
func _exit_tree() -> void:
	remove_custom_type("RoomConnector3D")
	remove_custom_type("DungeonGenerator3D")

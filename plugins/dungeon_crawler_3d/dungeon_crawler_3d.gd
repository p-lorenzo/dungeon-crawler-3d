@tool
extends EditorPlugin

const RoomConnector3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd")
const DungeonGenerator3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd")
const KeySpawnPoint3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/key_spawn_point_3d.gd")
const PropGroup3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/prop_group_3d.gd")


func _enter_tree() -> void:
	add_custom_type("RoomConnector3D", "Node3D", RoomConnector3DScript, null)
	add_custom_type("DungeonGenerator3D", "Node3D", DungeonGenerator3DScript, null)
	add_custom_type("KeySpawnPoint3D", "Node3D", KeySpawnPoint3DScript, null)
	add_custom_type("PropGroup3D", "Node3D", PropGroup3DScript, null)


func _exit_tree() -> void:
	remove_custom_type("RoomConnector3D")
	remove_custom_type("DungeonGenerator3D")
	remove_custom_type("KeySpawnPoint3D")
	remove_custom_type("PropGroup3D")

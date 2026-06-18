@tool
extends EditorPlugin

const RoomConnector3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd")
const DungeonGenerator3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd")


func _enter_tree() -> void:
	add_custom_type("RoomConnector3D", "Node3D", RoomConnector3DScript, null)
	add_custom_type("DungeonGenerator3D", "Node3D", DungeonGenerator3DScript, null)
	add_custom_resource_type("DungeonConfig", "Resource", preload("res://plugins/dungeon_crawler_3d/resources/dungeon_config.gd"), null)
	add_custom_resource_type("RoomData", "Resource", preload("res://plugins/dungeon_crawler_3d/resources/room_data.gd"), null)


func _exit_tree() -> void:
	remove_custom_type("RoomConnector3D")
	remove_custom_type("DungeonGenerator3D")
	remove_custom_resource_type("DungeonConfig")
	remove_custom_resource_type("RoomData")

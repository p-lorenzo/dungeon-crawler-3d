@tool
extends EditorPlugin

const RoomConnectorGizmoPluginScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd")

var _gizmo_plugin: EditorNode3DGizmoPlugin


func _enter_tree() -> void:
	_gizmo_plugin = RoomConnectorGizmoPluginScript.new()
	add_node_3d_gizmo_plugin(_gizmo_plugin)


func _exit_tree() -> void:
	if _gizmo_plugin:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null



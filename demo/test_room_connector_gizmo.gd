@tool
extends SceneTree

const RoomConnectorGizmoPluginScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd")


func _initialize() -> void:
	print("--- STARTING ROOM CONNECTOR GIZMO TESTS ---")
	var success := run_tests()
	if success:
		print("--- ROOM CONNECTOR GIZMO TESTS PASSED ---")
		quit(0)
	else:
		print("--- ROOM CONNECTOR GIZMO TESTS FAILED ---")
		quit(1)


func run_tests() -> bool:
	# 1. Test RoomConnector3D Default Values
	var connector := RoomConnector3D.new()

	if not connector:
		printerr("Test error: Failed to instantiate RoomConnector3D")
		return false

	if not is_equal_approx(connector.aperture_width, 2.0):
		printerr("Verification failure: Default aperture_width is not 2.0 (got %f)" % connector.aperture_width)
		return false

	if not is_equal_approx(connector.aperture_height, 2.5):
		printerr("Verification failure: Default aperture_height is not 2.5 (got %f)" % connector.aperture_height)
		return false

	# 2. Test Setting Positive Values
	connector.aperture_width = 3.5
	connector.aperture_height = 4.0

	if not is_equal_approx(connector.aperture_width, 3.5):
		printerr("Verification failure: Failed to set aperture_width to 3.5 (got %f)" % connector.aperture_width)
		return false

	if not is_equal_approx(connector.aperture_height, 4.0):
		printerr("Verification failure: Failed to set aperture_height to 4.0 (got %f)" % connector.aperture_height)
		return false

	# 3. Test Clamping / Positive Validation Bounds
	connector.aperture_width = 0.0
	connector.aperture_height = -5.0

	if not is_equal_approx(connector.aperture_width, 0.1):
		printerr("Verification failure: aperture_width 0.0 was not clamped to 0.1 (got %f)" % connector.aperture_width)
		return false

	if not is_equal_approx(connector.aperture_height, 0.1):
		printerr("Verification failure: aperture_height -5.0 was not clamped to 0.1 (got %f)" % connector.aperture_height)
		return false

	# 4. Test RoomConnectorGizmoPlugin Integration (editor only)
	if Engine.is_editor_hint():
		var gizmo_plugin = RoomConnectorGizmoPluginScript.new()
		if not gizmo_plugin:
			printerr("Test error: Failed to instantiate RoomConnectorGizmoPlugin")
			return false

		var gizmo_name: String = gizmo_plugin._get_gizmo_name()
		if gizmo_name != "RoomConnector3D":
			printerr("Verification failure: Gizmo name is not 'RoomConnector3D' (got '%s')" % gizmo_name)
			return false

		if not gizmo_plugin._has_gizmo(connector):
			printerr("Verification failure: _has_gizmo(connector) returned false")
			return false

		var dummy_node := Node3D.new()
		if gizmo_plugin._has_gizmo(dummy_node):
			printerr("Verification failure: _has_gizmo() returned true for plain Node3D")
			dummy_node.free()
			return false
		dummy_node.free()
	else:
		print("Skipping RoomConnectorGizmoPlugin instantiation test (runs only under editor hint).")

	connector.free()
	return true


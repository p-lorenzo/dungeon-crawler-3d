@tool
extends EditorNode3DGizmoPlugin


func _init() -> void:
	# Create a vertex-color-enabled material for gizmo drawing
	create_material("main", Color.WHITE, false, false, true)


func _get_gizmo_name() -> String:
	return "RoomConnector3D"


func _has_gizmo(spatial: Node3D) -> bool:
	return spatial is RoomConnector3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	var connector := gizmo.get_node_3d() as RoomConnector3D
	if not connector:
		return

	gizmo.clear()

	var w := connector.aperture_width
	var h := connector.aperture_height
	var color := connector._get_gizmo_color()
	var material := get_material("main", gizmo)

	var lines := PackedVector3Array()
	var half_w := w / 2.0

	# 1. Draw Rectangular Aperture Frame (US1)
	# Floor line
	lines.push_back(Vector3(-half_w, 0.0, 0.0))
	lines.push_back(Vector3(half_w, 0.0, 0.0))

	# Right upright
	lines.push_back(Vector3(half_w, 0.0, 0.0))
	lines.push_back(Vector3(half_w, h, 0.0))

	# Top header
	lines.push_back(Vector3(half_w, h, 0.0))
	lines.push_back(Vector3(-half_w, h, 0.0))

	# Left upright
	lines.push_back(Vector3(-half_w, h, 0.0))
	lines.push_back(Vector3(-half_w, 0.0, 0.0))

	# 2. Draw Exit Arrow pointing along local +Z axis (US2)
	var arrow_start := Vector3(0.0, 0.0, 0.0)
	var arrow_end := Vector3(0.0, 0.0, 1.0)

	# Main arrow shaft
	lines.push_back(arrow_start)
	lines.push_back(arrow_end)

	# Arrowhead fins (backwards at 45 degrees along X and Y axes)
	lines.push_back(arrow_end)
	lines.push_back(Vector3(-0.15, 0.0, 0.85))

	lines.push_back(arrow_end)
	lines.push_back(Vector3(0.15, 0.0, 0.85))

	lines.push_back(arrow_end)
	lines.push_back(Vector3(0.0, 0.15, 0.85))

	lines.push_back(arrow_end)
	lines.push_back(Vector3(0.0, -0.15, 0.85))

	# 3. Add all lines to the gizmo with vertex coloring (US3)
	gizmo.add_lines(lines, material, false, color)

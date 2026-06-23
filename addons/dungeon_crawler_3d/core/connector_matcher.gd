class_name ConnectorMatcher
extends RefCounted


func find_matching_connector(room_scene: PackedScene, target_connector_type: String) -> int:
	var instance: Node = room_scene.instantiate()
	var connector_index: int = -1

	var connectors: Array[Node] = _find_connectors(instance)
	for i: int in range(connectors.size()):
		var connector: RoomConnector3D = connectors[i] as RoomConnector3D
		if connector and connector.connection_type == target_connector_type:
			connector_index = i
			break

	instance.free()
	return connector_index


func get_connectors(room_scene: PackedScene) -> Array[Transform3D]:
	var instance: Node = room_scene.instantiate()
	var transforms: Array[Transform3D] = get_connectors_from_instance(instance)
	instance.free()
	return transforms


func get_connectors_from_instance(node: Node) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	var connectors: Array[Node] = _find_connectors(node)
	for connector: RoomConnector3D in connectors:
		if connector:
			transforms.append(_get_relative_transform(connector, node))
	return transforms


func get_connector_types(room_scene: PackedScene) -> Array[String]:
	var instance: Node = room_scene.instantiate()
	var types: Array[String] = []

	var connectors: Array[Node] = _find_connectors(instance)
	for connector: RoomConnector3D in connectors:
		if connector:
			types.append(connector.connection_type)

	instance.free()
	return types


func compute_alignment_transform(connector_a_world: Transform3D, connector_b_local: Transform3D) -> Transform3D:
	var target_transform: Transform3D = connector_a_world
	var rotation_180: Basis = Basis(Vector3(0, 1, 0), PI)
	target_transform.basis = connector_a_world.basis * rotation_180

	return target_transform * connector_b_local.affine_inverse()


func _find_connectors(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	_find_connectors_recursive(node, result)
	return result


func _find_connectors_recursive(node: Node, result: Array[Node]) -> void:
	if node is RoomConnector3D:
		result.append(node)

	for child: Node in node.get_children():
		_find_connectors_recursive(child, result)


func _get_relative_transform(node: Node3D, root: Node) -> Transform3D:
	var t: Transform3D = Transform3D.IDENTITY
	var curr: Node = node
	while curr and curr != root:
		if curr is Node3D:
			t = curr.transform * t
		curr = curr.get_parent()
	return t

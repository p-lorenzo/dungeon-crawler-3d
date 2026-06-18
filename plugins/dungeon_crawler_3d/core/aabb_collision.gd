class_name AABBManager
extends RefCounted


func compute_aabb(room_scene: PackedScene) -> AABB:
	var instance: Node = room_scene.instantiate()
	var result: AABB = _collect_aabb_recursive(instance, Transform3D.IDENTITY, true)
	instance.free()
	return result


func _collect_aabb_recursive(node: Node, parent_transform: Transform3D, is_root: bool = false) -> AABB:
	var current_transform: Transform3D = parent_transform
	if node is Node3D and not is_root:
		current_transform = parent_transform * node.transform

	var aabb: AABB = AABB()
	var first: bool = true

	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		if mesh:
			var local_aabb: AABB = mesh.get_aabb()
			if local_aabb.has_surface():
				var room_local_aabb: AABB = current_transform * local_aabb
				aabb = room_local_aabb
				first = false

	for child: Node in node.get_children():
		var child_aabb: AABB = _collect_aabb_recursive(child, current_transform, false)
		if child_aabb.has_surface():
			if first:
				aabb = child_aabb
				first = false
			else:
				aabb = aabb.merge(child_aabb)

	return aabb


func check_overlap(candidate: AABB, placed_aabbs: Array[AABB]) -> bool:
	var shrunk_candidate: AABB = candidate.grow(-0.01)
	for existing: AABB in placed_aabbs:
		if shrunk_candidate.intersects(existing):
			return true
	return false

class_name AABBManager
extends RefCounted


func compute_aabb(room_scene: PackedScene) -> AABB:
	var instance: Node = room_scene.instantiate()
	var result: AABB = _collect_aabb_recursive(instance)
	instance.free()
	return result


func _collect_aabb_recursive(node: Node) -> AABB:
	var aabb: AABB = AABB()
	var first: bool = true

	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		if mesh:
			var local_aabb: AABB = mesh.get_aabb()
			if local_aabb.has_surface():
				var world_aabb: AABB = node.global_transform * local_aabb
				aabb = world_aabb
				first = false

	for child: Node in node.get_children():
		var child_aabb: AABB = _collect_aabb_recursive(child)
		if child_aabb.has_surface():
			if first:
				aabb = child_aabb
				first = false
			else:
				aabb = aabb.merge(child_aabb)

	return aabb


func check_overlap(candidate: AABB, placed_aabbs: Array) -> bool:
	for existing: AABB in placed_aabbs:
		if candidate.intersects(existing):
			return true
	return false

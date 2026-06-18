class_name DungeonBuilder
extends RefCounted

var _config: DungeonConfig
var _graph: DungeonGraph
var _aabb_manager: AABBManager
var _matcher: ConnectorMatcher
var _selector: RoomSelector
var _rng: RandomNumberGenerator
var _placed_aabbs: Array[AABB] = []
var _attempts_at_position: int = 0
var _branched_from: Array[int] = []
var failure_reason: String = ""
var partial_success_note: String = ""
var branches_placed: int = 0
var branches_requested: int = 0


func build(config: DungeonConfig) -> DungeonGraph:
	_config = config
	_graph = DungeonGraph.new()
	_aabb_manager = AABBManager.new()
	_matcher = ConnectorMatcher.new()
	_selector = RoomSelector.new()
	_rng = RandomNumberGenerator.new()
	_placed_aabbs.clear()
	_attempts_at_position = 0
	_branched_from.clear()
	failure_reason = ""
	partial_success_note = ""
	branches_placed = 0
	branches_requested = 0

	if _config.random_seed != 0:
		_rng.seed = _config.random_seed
	else:
		_rng.randomize()

	var room_count_hard_cap: int = _config.room_count_max
	if _config.main_path_length > room_count_hard_cap:
		_selector.reset()
		failure_reason = "Main path length (%d) exceeds room count max (%d)" % [_config.main_path_length, room_count_hard_cap]
		return _graph

	var result: bool = _build_main_path()
	if not result:
		_selector.reset()
		failure_reason = "Cannot satisfy main path length"
		return _graph

	if _graph.total_rooms > room_count_hard_cap:
		_selector.reset()
		failure_reason = "Exceeded maximum room count (%d)" % room_count_hard_cap
		return _graph

	_populate_main_path_indices()

	branches_requested = _config.branch_count
	if _config.branch_count > 0:
		var branch_result: bool = _build_branches()
		if not branch_result:
			_selector.reset()
			failure_reason = "Cannot satisfy branch count"
			return _graph

		if _graph.total_rooms > room_count_hard_cap:
			_selector.reset()
			failure_reason = "Branches exceeded maximum room count (%d)" % room_count_hard_cap
			return _graph

	if not _validate_final_path():
		_selector.reset()
		failure_reason = "Generated dungeon has no valid entrance-to-boss path"
		return _graph

	if branches_placed < branches_requested:
		partial_success_note = "Placed %d of %d requested branches (limited by main path rooms)" % [branches_placed, branches_requested]

	if _graph.total_rooms < _config.room_count_min:
		if not partial_success_note.is_empty():
			partial_success_note += "; "
		partial_success_note += "Generated %d rooms, below room_count_min (%d)" % [_graph.total_rooms, _config.room_count_min]

	_selector.reset()
	return _graph


func _build_main_path() -> bool:
	print("=== _build_main_path START ===")
	print("  target_length: ", _config.main_path_length)
	print("  entrance_pool size: ", _config.entrance_pool.size())
	print("  corridor_pool size: ", _config.corridor_pool.size())
	print("  junction_pool size: ", _config.junction_pool.size())
	print("  boss_pool size: ", _config.boss_pool.size())
	print("  max_generation_attempts: ", _config.max_generation_attempts)

	var entrance_data: RoomData = _selector.select_weighted(_config.entrance_pool, _rng)
	if not entrance_data or not entrance_data.room_scene:
		print("  FAIL: no entrance data or scene")
		return false

	var entrance_placement: Dictionary = {
		room_data = entrance_data,
		world_transform = Transform3D.IDENTITY,
		category = RoomData.RoomCategory.ENTRANCE,
		parent_index = -1,
		connector_used = -1
	}

	if not _place_room(entrance_placement):
		return false

	_graph.add_placement(entrance_placement)

	var success: bool = _place_path_node_recursive(1)
	if not success:
		return false

	return _validate_final_path()


func _place_path_node_recursive(depth: int) -> bool:
	var target_length: int = _config.main_path_length
	if depth >= target_length:
		return true

	var is_last: bool = (depth == target_length - 1)
	var prev_idx: int = depth - 1
	var prev_placement: Dictionary = _graph.placements[prev_idx]

	var pool: Array[RoomData]
	if is_last:
		pool = _config.boss_pool
	else:
		var combined: Array[RoomData] = []
		combined.append_array(_config.corridor_pool)
		combined.append_array(_config.junction_pool)
		pool = combined

	if pool.is_empty():
		print("  Recursion depth %d: Pool is empty" % depth)
		return false

	var forward_connector_idx: int = _find_unused_connector(prev_placement, prev_idx)
	if forward_connector_idx < 0:
		print("  Recursion depth %d: No unused connector on room %d" % [depth, prev_idx])
		return false

	var forward_type: String = _get_connector_type(prev_placement.room_data.room_scene, forward_connector_idx)
	if forward_type.is_empty():
		print("  Recursion depth %d: Empty connector type on room %d" % [depth, prev_idx])
		return false

	var working_pool: Array[RoomData] = pool.duplicate()
	var attempts: int = 0

	print("  Recursion depth %d: start trying candidates from pool of size %d" % [depth, working_pool.size()])

	while not working_pool.is_empty() and attempts < _config.max_generation_attempts:
		attempts += 1
		var candidate_idx: int = _selector.select_weighted_index(working_pool, _rng)
		if candidate_idx < 0:
			print("    depth %d: select_weighted_index returned < 0" % depth)
			break

		var candidate: RoomData = working_pool[candidate_idx]
		working_pool.remove_at(candidate_idx)
		print("    depth %d: attempt %d, candidate room: %s" % [depth, attempts, candidate.room_scene.resource_path.get_file()])

		var match_idx: int = _matcher.find_matching_connector(candidate.room_scene, forward_type)
		if match_idx < 0:
			print("      depth %d: candidate %s has no matching connector for type '%s'" % [depth, candidate.room_scene.resource_path.get_file(), forward_type])
			continue

		var prev_connector_world: Transform3D = _get_connector_world_transform(prev_placement, forward_connector_idx)
		var candidate_connector_local: Transform3D = _get_connector_local_transform(candidate.room_scene, match_idx)

		var world_transform: Transform3D = _matcher.compute_alignment_transform(prev_connector_world, candidate_connector_local)
		var room_aabb: AABB = _compute_room_world_aabb(candidate.room_scene, world_transform)

		if _aabb_manager.check_overlap(room_aabb, _placed_aabbs):
			print("      depth %d: candidate %s overlaps with existing placements" % [depth, candidate.room_scene.resource_path.get_file()])
			continue

		var category: int = RoomData.RoomCategory.BOSS if is_last else candidate.category
		var new_placement: Dictionary = {
			room_data = candidate,
			world_transform = world_transform,
			category = category,
			parent_index = prev_idx,
			connector_used = match_idx
		}

		_placed_aabbs.append(room_aabb)
		_graph.add_placement(new_placement)

		var edge: Dictionary = {
			room_a_index = prev_idx,
			room_b_index = _graph.placements.size() - 1,
			connector_a_local = _get_connector_local_transform(prev_placement.room_data.room_scene, forward_connector_idx),
			connector_b_local = candidate_connector_local,
			connection_type = forward_type
		}
		_graph.add_edge(edge)

		print("      depth %d: placed room %s successfully, recursing..." % [depth, candidate.room_scene.resource_path.get_file()])

		# Recurse
		if _place_path_node_recursive(depth + 1):
			return true

		# Backtrack
		print("      depth %d: recursion failed, backtracking room %s" % [depth, candidate.room_scene.resource_path.get_file()])
		_graph.remove_last_placement()
		_placed_aabbs.pop_back()
		_graph.remove_last_edge()

	print("  Recursion depth %d: exhausted all candidates (attempts=%d), returning false" % [depth, attempts])
	return false


func _populate_main_path_indices() -> void:
	_graph.main_path.clear()
	for i: int in range(_graph.placements.size()):
		_graph.main_path.append(i)


func _build_branches() -> bool:
	var target_branch_count: int = _config.branch_count
	var main_path_len: int = _graph.main_path.size()
	var room_count_max: int = _config.room_count_max

	if target_branch_count > main_path_len:
		target_branch_count = main_path_len

	var available_attachment_indices: Array[int] = _graph.main_path.duplicate()

	for branch_idx: int in range(target_branch_count):
		if available_attachment_indices.is_empty():
			break

		if _graph.total_rooms >= room_count_max:
			break

		var depth: int = _rng.randi_range(_config.branch_depth_min, _config.branch_depth_max)
		var remaining: int = room_count_max - _graph.total_rooms
		if depth > remaining:
			depth = remaining

		var placement_success: bool = false
		while not placement_success and not available_attachment_indices.is_empty():
			var attachment_idx: int = _rng.randi() % available_attachment_indices.size()
			var main_room_idx: int = available_attachment_indices[attachment_idx]
			available_attachment_indices.remove_at(attachment_idx)

			placement_success = _build_single_branch(main_room_idx, depth)

		if not placement_success:
			return false

		branches_placed += 1

	return true


func _build_single_branch(attach_index: int, depth: int) -> bool:
	var branch_placement_indices: Array[int] = []
	var success: bool = _place_branch_node_recursive(attach_index, branch_placement_indices, 0, depth)
	if success:
		_graph.branches.append(branch_placement_indices)
		_branched_from.append(attach_index)
		return true
	return false


func _place_branch_node_recursive(current_parent_idx: int, branch_placement_indices: Array[int], step: int, depth: int) -> bool:
	if step >= depth:
		return true

	var is_last: bool = (step == depth - 1)
	var pool: Array[RoomData]
	if is_last:
		pool = _config.dead_end_pool
	else:
		var combined: Array[RoomData] = []
		combined.append_array(_config.corridor_pool)
		combined.append_array(_config.junction_pool)
		pool = combined

	if pool.is_empty():
		return false

	var parent_placement: Dictionary = _graph.placements[current_parent_idx]
	var forward_connector_idx: int = _find_unused_connector(parent_placement, current_parent_idx)
	if forward_connector_idx < 0:
		return false

	var forward_type: String = _get_connector_type(parent_placement.room_data.room_scene, forward_connector_idx)
	if forward_type.is_empty():
		return false

	var working_pool: Array[RoomData] = pool.duplicate()
	var attempts: int = 0

	while not working_pool.is_empty() and attempts < _config.max_generation_attempts:
		attempts += 1
		var candidate_idx: int = _selector.select_weighted_index(working_pool, _rng)
		if candidate_idx < 0:
			break

		var candidate: RoomData = working_pool[candidate_idx]
		working_pool.remove_at(candidate_idx)

		var match_idx: int = _matcher.find_matching_connector(candidate.room_scene, forward_type)
		if match_idx < 0:
			continue

		var prev_connector_world: Transform3D = _get_connector_world_transform(parent_placement, forward_connector_idx)
		var candidate_connector_local: Transform3D = _get_connector_local_transform(candidate.room_scene, match_idx)

		var world_transform: Transform3D = _matcher.compute_alignment_transform(prev_connector_world, candidate_connector_local)
		var room_aabb: AABB = _compute_room_world_aabb(candidate.room_scene, world_transform)

		if _aabb_manager.check_overlap(room_aabb, _placed_aabbs):
			continue

		var category: int = RoomData.RoomCategory.DEAD_END if is_last else candidate.category
		var new_placement: Dictionary = {
			room_data = candidate,
			world_transform = world_transform,
			category = category,
			parent_index = current_parent_idx,
			connector_used = match_idx
		}

		_placed_aabbs.append(room_aabb)
		var new_room_idx: int = _graph.add_placement(new_placement)
		branch_placement_indices.append(new_room_idx)

		var edge: Dictionary = {
			room_a_index = current_parent_idx,
			room_b_index = new_room_idx,
			connector_a_local = _get_connector_local_transform(parent_placement.room_data.room_scene, forward_connector_idx),
			connector_b_local = candidate_connector_local,
			connection_type = forward_type
		}
		_graph.add_edge(edge)

		if _place_branch_node_recursive(new_room_idx, branch_placement_indices, step + 1, depth):
			return true

		# Backtrack
		branch_placement_indices.pop_back()
		_graph.remove_last_placement()
		_placed_aabbs.pop_back()
		_graph.remove_last_edge()

	return false


func _place_room(placement: Dictionary) -> bool:
	var room_data: RoomData = placement.room_data
	if not room_data or not room_data.room_scene:
		return false

	var world_transform: Transform3D = placement.world_transform
	var aabb: AABB = _compute_room_world_aabb(room_data.room_scene, world_transform)
	_placed_aabbs.append(aabb)
	return true


func _find_unused_connector(placement: Dictionary, room_index: int) -> int:
	var room_scene: PackedScene = placement.room_data.room_scene
	var connectors: Array[Transform3D] = _matcher.get_connectors(room_scene)
	var types: Array[String] = _matcher.get_connector_types(room_scene)

	var used_indices: Array[int] = []
	for edge: Dictionary in _graph.edges:
		if edge.room_a_index == room_index:
			var local: Transform3D = edge.connector_a_local
			for i: int in range(connectors.size()):
				if connectors[i].is_equal_approx(local):
					used_indices.append(i)
		elif edge.room_b_index == room_index:
			var local: Transform3D = edge.connector_b_local
			for i: int in range(connectors.size()):
				if connectors[i].is_equal_approx(local):
					used_indices.append(i)

	for i: int in range(connectors.size()):
		if i not in used_indices and not types[i].is_empty():
			return i

	return -1


func _get_connector_type(room_scene: PackedScene, connector_idx: int) -> String:
	var types: Array[String] = _matcher.get_connector_types(room_scene)
	if connector_idx >= 0 and connector_idx < types.size():
		return types[connector_idx]
	return ""


func _get_connector_world_transform(placement: Dictionary, connector_idx: int) -> Transform3D:
	var room_scene: PackedScene = placement.room_data.room_scene
	var local: Transform3D = _get_connector_local_transform(room_scene, connector_idx)
	return placement.world_transform * local


func _get_connector_local_transform(room_scene: PackedScene, connector_idx: int) -> Transform3D:
	var connectors: Array[Transform3D] = _matcher.get_connectors(room_scene)
	if connector_idx >= 0 and connector_idx < connectors.size():
		return connectors[connector_idx]
	return Transform3D.IDENTITY


func _compute_room_world_aabb(room_scene: PackedScene, world_transform: Transform3D) -> AABB:
	var local_aabb: AABB = _compute_scene_aabb(room_scene)
	var corners: Array[Vector3] = _get_aabb_corners(local_aabb)
	var world_aabb: AABB = AABB(world_transform * corners[0], Vector3.ZERO)
	for i: int in range(1, corners.size()):
		world_aabb = world_aabb.expand(world_transform * corners[i])
	return world_aabb


func _compute_scene_aabb(room_scene: PackedScene) -> AABB:
	return _aabb_manager.compute_aabb(room_scene)


func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	return [
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z)
	]


func _validate_final_path() -> bool:
	var validator: PathValidator = PathValidator.new()
	return validator.validate_path(_graph)

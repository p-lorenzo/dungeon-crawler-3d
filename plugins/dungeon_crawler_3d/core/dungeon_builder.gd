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
	var entrance_data: RoomData = _selector.select_weighted(_config.entrance_pool, _rng)
	if not entrance_data or not entrance_data.room_scene:
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

	var target_length: int = _config.main_path_length
	while _graph.placements.size() < target_length:
		_attempts_at_position = 0
		var is_last: bool = (_graph.placements.size() == target_length - 1)
		var success: bool = _place_next_on_path(is_last)

		if success:
			continue

		while not success and _attempts_at_position >= _config.max_generation_attempts:
			if _graph.placements.size() <= 1:
				return false

			_graph.remove_last_placement()
			if not _placed_aabbs.is_empty():
				_placed_aabbs.pop_back()
			if not _graph.edges.is_empty():
				var edge: Dictionary = _graph.remove_last_edge()
				if not edge.is_empty():
					pass

			_attempts_at_position = 0
			is_last = (_graph.placements.size() == target_length - 1)
			success = _place_next_on_path(is_last)

		if not success:
			return false

	return _validate_final_path()


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

		var attachment_idx: int = _rng.randi() % available_attachment_indices.size()
		var main_room_idx: int = available_attachment_indices[attachment_idx]
		available_attachment_indices.remove_at(attachment_idx)

		var depth: int = _rng.randi_range(_config.branch_depth_min, _config.branch_depth_max)
		var remaining: int = room_count_max - _graph.total_rooms
		if depth > remaining:
			depth = remaining

		if not _build_single_branch(main_room_idx, depth):
			return false

		branches_placed += 1

	return true


func _build_single_branch(attach_index: int, depth: int) -> bool:
	var current_parent_idx: int = attach_index
	var branch_placement_indices: Array[int] = []

	for step: int in range(depth):
		_attempts_at_position = 0
		var is_last: bool = (step == depth - 1)
		var success: bool = _place_next_branch_room(current_parent_idx, is_last)

		if success:
			var new_idx: int = _graph.placements.size() - 1
			branch_placement_indices.append(new_idx)
			current_parent_idx = new_idx
			continue

		while not success and _attempts_at_position >= _config.max_generation_attempts:
			if branch_placement_indices.is_empty():
				return false

			_rollback_branch_step(branch_placement_indices)

			if branch_placement_indices.is_empty():
				current_parent_idx = attach_index
			else:
				current_parent_idx = branch_placement_indices[branch_placement_indices.size() - 1]

			_attempts_at_position = 0
			is_last = branch_placement_indices.is_empty() or (branch_placement_indices.size() == depth - 1)
			success = _place_next_branch_room(current_parent_idx, is_last)

		if not success:
			return false

	_graph.branches.append(branch_placement_indices)
	_branched_from.append(attach_index)
	return true


func _rollback_branch_step(branch_indices: Array[int]) -> void:
	var removed_idx: int = branch_indices.pop_back()
	var rollback_placement: Dictionary = _graph.remove_last_placement()
	if not rollback_placement.is_empty():
		if not _placed_aabbs.is_empty():
			_placed_aabbs.pop_back()
		if not _graph.edges.is_empty():
			_graph.remove_last_edge()


func _place_next_branch_room(parent_idx: int, is_last: bool) -> bool:
	var parent_placement: Dictionary = _graph.placements[parent_idx]
	var pool: Array[RoomData]
	if is_last:
		pool = _config.dead_end_pool
	else:
		var combined: Array[RoomData] = []
		combined.append_array(_config.corridor_pool)
		combined.append_array(_config.junction_pool)
		pool = combined

	if pool.is_empty():
		_attempts_at_position = _config.max_generation_attempts
		return false

	var forward_connector_idx: int = _find_unused_connector(parent_placement, parent_idx)
	if forward_connector_idx < 0:
		_attempts_at_position = _config.max_generation_attempts
		return false

	var forward_type: String = _get_connector_type(parent_placement.room_data.room_scene, forward_connector_idx)
	if forward_type.is_empty():
		_attempts_at_position = _config.max_generation_attempts
		return false

	var working_pool: Array[RoomData] = pool.duplicate()
	while not working_pool.is_empty():
		if _attempts_at_position >= _config.max_generation_attempts:
			return false

		_attempts_at_position += 1
		var candidate_idx: int = _selector.select_weighted_index(working_pool, _rng)
		if candidate_idx < 0:
			return false

		var candidate: RoomData = working_pool[candidate_idx]

		var match_idx: int = _matcher.find_matching_connector(candidate.room_scene, forward_type)
		if match_idx < 0:
			working_pool.remove_at(candidate_idx)
			continue

		var prev_connector_world: Transform3D = _get_connector_world_transform(parent_placement, forward_connector_idx)
		var candidate_connector_local: Transform3D = _get_connector_local_transform(candidate.room_scene, match_idx)

		var world_transform: Transform3D = _matcher.compute_alignment_transform(prev_connector_world, candidate_connector_local)
		var room_aabb: AABB = _compute_room_world_aabb(candidate.room_scene, world_transform)

		if _aabb_manager.check_overlap(room_aabb, _placed_aabbs):
			working_pool.remove_at(candidate_idx)
			continue

		var category: int
		if is_last:
			category = RoomData.RoomCategory.DEAD_END
		else:
			category = candidate.category

		var new_placement: Dictionary = {
			room_data = candidate,
			world_transform = world_transform,
			category = category,
			parent_index = parent_idx,
			connector_used = match_idx
		}

		_placed_aabbs.append(room_aabb)
		_graph.add_placement(new_placement)

		var edge: Dictionary = {
			room_a_index = parent_idx,
			room_b_index = _graph.placements.size() - 1,
			connector_a_local = _get_connector_local_transform(parent_placement.room_data.room_scene, forward_connector_idx),
			connector_b_local = candidate_connector_local,
			connection_type = forward_type
		}
		_graph.add_edge(edge)

		return true

	_attempts_at_position = _config.max_generation_attempts
	return false


func _place_next_on_path(is_last: bool) -> bool:
	var prev_idx: int = _graph.placements.size() - 1
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
		_attempts_at_position = _config.max_generation_attempts
		return false

	var forward_connector_idx: int = _find_unused_connector(prev_placement, prev_idx)
	if forward_connector_idx < 0:
		_attempts_at_position = _config.max_generation_attempts
		return false

	var forward_type: String = _get_connector_type(prev_placement.room_data.room_scene, forward_connector_idx)
	if forward_type.is_empty():
		_attempts_at_position = _config.max_generation_attempts
		return false

	var working_pool: Array[RoomData] = pool.duplicate()
	while not working_pool.is_empty():
		if _attempts_at_position >= _config.max_generation_attempts:
			return false

		_attempts_at_position += 1
		var candidate_idx: int = _selector.select_weighted_index(working_pool, _rng)
		if candidate_idx < 0:
			return false

		var candidate: RoomData = working_pool[candidate_idx]

		var match_idx: int = _matcher.find_matching_connector(candidate.room_scene, forward_type)
		if match_idx < 0:
			working_pool.remove_at(candidate_idx)
			continue

		var prev_connector_world: Transform3D = _get_connector_world_transform(prev_placement, forward_connector_idx)
		var candidate_connector_local: Transform3D = _get_connector_local_transform(candidate.room_scene, match_idx)

		var world_transform: Transform3D = _matcher.compute_alignment_transform(prev_connector_world, candidate_connector_local)
		var room_aabb: AABB = _compute_room_world_aabb(candidate.room_scene, world_transform)

		if _aabb_manager.check_overlap(room_aabb, _placed_aabbs):
			working_pool.remove_at(candidate_idx)
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

		return true

	_attempts_at_position = _config.max_generation_attempts
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

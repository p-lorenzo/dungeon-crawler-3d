class_name DungeonBuilder
extends RefCounted

var _config: DungeonConfig
var _graph: DungeonGraph
var _aabb_manager: AABBManager
var _matcher: ConnectorMatcher
var _rng: RandomNumberGenerator
var _placed_aabbs: Array = []
var _attempts_at_position: int = 0


func build(config: DungeonConfig) -> DungeonGraph:
	_config = config
	_graph = DungeonGraph.new()
	_aabb_manager = AABBManager.new()
	_matcher = ConnectorMatcher.new()
	_rng = RandomNumberGenerator.new()
	_placed_aabbs.clear()
	_attempts_at_position = 0

	if _config.random_seed != 0:
		_rng.seed = _config.random_seed
	else:
		_rng.randomize()

	var result: bool = _build_main_path()
	if not result:
		return _graph

	return _graph


func _build_main_path() -> bool:
	var entrance_data: RoomData = _select_from_pool(_config.entrance_pool)
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
				_graph.remove_last_edge()

			_attempts_at_position = 0
			is_last = (_graph.placements.size() == target_length - 1)
			success = _place_next_on_path(is_last)

		if not success:
			return false

	return _validate_final_path()


func _place_next_on_path(is_last: bool) -> bool:
	var prev_idx: int = _graph.placements.size() - 1
	var prev_placement: Dictionary = _graph.placements[prev_idx]
	var pool: Array[RoomData] = _config.boss_pool if is_last else _config.corridor_pool

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

	var shuffled_indices: Array = _shuffled_range(pool.size())
	for candidate_i: int in shuffled_indices:
		if _attempts_at_position >= _config.max_generation_attempts:
			return false

		_attempts_at_position += 1
		var candidate: RoomData = pool[candidate_i]
		if not candidate or not candidate.room_scene:
			continue
		if candidate.spawn_weight <= 0.0:
			continue

		var match_idx: int = _matcher.find_matching_connector(candidate.room_scene, forward_type)
		if match_idx < 0:
			continue

		var prev_connector_world: Transform3D = _get_connector_world_transform(prev_placement, forward_connector_idx)
		var candidate_connector_local: Transform3D = _get_connector_local_transform(candidate.room_scene, match_idx)

		var world_transform: Transform3D = _matcher.compute_alignment_transform(prev_connector_world, candidate_connector_local)
		var room_aabb: AABB = _compute_room_world_aabb(candidate.room_scene, world_transform)

		if _aabb_manager.check_overlap(room_aabb, _placed_aabbs):
			continue

		var category: int = RoomData.RoomCategory.BOSS if is_last else RoomData.RoomCategory.CORRIDOR
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


func _select_from_pool(pool: Array[RoomData]) -> RoomData:
	if pool.is_empty():
		return null

	var valid: Array[RoomData] = []
	for room: RoomData in pool:
		if room and room.room_scene:
			valid.append(room)

	if valid.is_empty():
		return null

	var idx: int = _rng.randi() % valid.size()
	return valid[idx]


func _find_unused_connector(placement: Dictionary, room_index: int) -> int:
	var room_scene: PackedScene = placement.room_data.room_scene
	var connectors: Array[Transform3D] = _matcher.get_connectors(room_scene)
	var types: Array = _matcher.get_connector_types(room_scene)

	var used_indices: Array = []
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
	var types: Array = _matcher.get_connector_types(room_scene)
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
	var corners: Array = _get_aabb_corners(local_aabb)
	var world_aabb: AABB = AABB(world_transform * corners[0], Vector3.ZERO)
	for i: int in range(1, corners.size()):
		world_aabb = world_aabb.expand(world_transform * corners[i])
	return world_aabb


func _compute_scene_aabb(room_scene: PackedScene) -> AABB:
	return _aabb_manager.compute_aabb(room_scene)


func _get_aabb_corners(aabb: AABB) -> Array:
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


func _shuffled_range(size: int) -> Array:
	var indices: Array = []
	for i: int in range(size):
		indices.append(i)

	for i: int in range(size - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var temp = indices[i]
		indices[i] = indices[j]
		indices[j] = temp

	return indices

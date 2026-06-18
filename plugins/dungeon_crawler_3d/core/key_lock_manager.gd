class_name KeyLockManager
extends RefCounted

var _cache: Dictionary = {}


func clear_cache() -> void:
	_cache.clear()


func populate_cache(config: DungeonConfig) -> void:
	var pools: Array[Array] = [
		config.entrance_pool,
		config.boss_pool,
		config.corridor_pool,
		config.junction_pool,
		config.dead_end_pool
	]
	for pool: Array[RoomData] in pools:
		for room_data: RoomData in pool:
			if room_data and room_data.room_scene:
				populate_cache_for_scene(room_data.room_scene)


func populate_cache_for_scene(scene: PackedScene) -> void:
	if not scene or _cache.has(scene):
		return

	var connectors_data: Array[Dictionary] = []
	var spawns_data: Array[Dictionary] = []

	var state: SceneState = scene.get_state()
	for i: int in range(state.get_node_count()):
		var type: String = state.get_node_type(i)
		var node_path: NodePath = state.get_node_path(i)

		var is_connector: bool = (type == "RoomConnector3D")
		var is_spawn: bool = (type == "KeySpawnPoint3D")

		var connection_type: String = ""
		var is_locked: bool = false
		var key_id: String = ""

		for p: int in range(state.get_node_property_count(i)):
			var prop_name: String = state.get_node_property_name(i, p)
			var prop_val: Variant = state.get_node_property_value(i, p)
			if prop_name == "script":
				if prop_val is Script:
					var path: String = prop_val.resource_path
					if path.contains("room_connector_3d.gd"):
						is_connector = true
					elif path.contains("key_spawn_point_3d.gd"):
						is_spawn = true
			elif prop_name == "connection_type":
				connection_type = prop_val
			elif prop_name == "is_locked":
				is_locked = prop_val
			elif prop_name == "key_id":
				key_id = prop_val

		if is_spawn:
			spawns_data.append({
				"path": node_path,
				"key_id": key_id
			})

	var inst: Node = scene.instantiate()
	for child: Node in inst.find_children("*", "RoomConnector3D", true, false):
		var connector := child as RoomConnector3D
		if connector:
			connectors_data.append({
				"transform": _get_relative_transform(connector, inst),
				"connection_type": connector.connection_type,
				"is_locked": connector.is_locked,
				"key_id": connector.key_id
			})

	if spawns_data.is_empty():
		for child: Node in inst.find_children("*", "KeySpawnPoint3D", true, false):
			var spawn := child as KeySpawnPoint3D
			if spawn:
				spawns_data.append({
					"path": inst.get_path_to(spawn),
					"key_id": spawn.key_id
				})

	inst.free()

	_cache[scene] = {
		"connectors": connectors_data,
		"spawn_points": spawns_data
	}


func _get_relative_transform(node: Node3D, root: Node) -> Transform3D:
	var t: Transform3D = Transform3D.IDENTITY
	var curr: Node = node
	while curr and curr != root:
		if curr is Node3D:
			t = curr.transform * t
		curr = curr.get_parent()
	return t


func allocate_keys(graph: DungeonGraph) -> Dictionary:
	var locked_edges: Array[Dictionary] = []
	for edge: Dictionary in graph.edges:
		if _is_edge_locked(graph, edge):
			locked_edges.append(edge)

	if locked_edges.is_empty():
		return {}

	var allocated_assignments: Dictionary = {}
	var allocated_spawn_keys: Dictionary = {}
	var unlocked_edges: Array[Dictionary] = []

	var success: bool = _search_allocation(graph, locked_edges, allocated_assignments, allocated_spawn_keys, unlocked_edges)
	if success:
		return allocated_assignments
	return {}


func _search_allocation(
	graph: DungeonGraph,
	locked_edges: Array[Dictionary],
	allocated_assignments: Dictionary,
	allocated_spawn_keys: Dictionary,
	unlocked_edges: Array[Dictionary]
) -> bool:
	if unlocked_edges.size() == locked_edges.size():
		return _can_reach_boss(graph, unlocked_edges)

	var reachable: Array[int] = _get_reachable_rooms(graph, unlocked_edges)

	var boundary_edges: Array[Dictionary] = []
	for edge: Dictionary in locked_edges:
		if edge in unlocked_edges:
			continue
		var a_reach: bool = edge.room_a_index in reachable
		var b_reach: bool = edge.room_b_index in reachable
		if (a_reach and not b_reach) or (b_reach and not a_reach):
			boundary_edges.append(edge)

	if boundary_edges.is_empty():
		return false

	for edge: Dictionary in boundary_edges:
		var key_id: String = _get_edge_key_id(graph, edge)
		if key_id.is_empty():
			continue

		var candidates: Array[Dictionary] = []
		for room_idx: int in reachable:
			var placement: Dictionary = graph.placements[room_idx]
			var scene_data: Dictionary = _cache.get(placement.room_data.room_scene, {})
			if scene_data.is_empty():
				continue

			var spawn_points: Array = scene_data.get("spawn_points", [])
			for spawn_val: Variant in spawn_points:
				var spawn: Dictionary = spawn_val as Dictionary
				var path: NodePath = spawn.path
				var spawn_key: String = "%d:%s" % [room_idx, String(path)]
				if not allocated_spawn_keys.has(spawn_key):
					candidates.append({
						"room_index": room_idx,
						"spawn_path": path,
						"spawn_key": spawn_key
					})

		if candidates.is_empty():
			continue

		for cand: Dictionary in candidates:
			var room_idx: int = cand.room_index
			var score: float = 0.0

			var is_dead_end: bool = graph.placements[room_idx].category == RoomData.RoomCategory.DEAD_END
			if is_dead_end:
				score += 1000.0

			var dist: int = _get_shortest_path_distance(graph, 0, room_idx, unlocked_edges)
			score += dist * 10.0

			cand["score"] = score

		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return a.score > b.score
		)

		var connector_room_idx: int = -1
		var connector_idx_in_room: int = -1

		var room_a: Dictionary = graph.placements[edge.room_a_index]
		var data_a: Dictionary = _cache.get(room_a.room_data.room_scene, {})
		if not data_a.is_empty():
			var connectors: Array = data_a.get("connectors", [])
			for idx: int in range(connectors.size()):
				var conn: Dictionary = connectors[idx] as Dictionary
				if conn.transform.is_equal_approx(edge.connector_a_local) and conn.is_locked:
					connector_room_idx = edge.room_a_index
					connector_idx_in_room = idx
					break

		if connector_room_idx == -1:
			var room_b: Dictionary = graph.placements[edge.room_b_index]
			var data_b: Dictionary = _cache.get(room_b.room_data.room_scene, {})
			if not data_b.is_empty():
				var connectors: Array = data_b.get("connectors", [])
				for idx: int in range(connectors.size()):
					var conn: Dictionary = connectors[idx] as Dictionary
					if conn.transform.is_equal_approx(edge.connector_b_local) and conn.is_locked:
						connector_room_idx = edge.room_b_index
						connector_idx_in_room = idx
						break

		for cand: Dictionary in candidates:
			allocated_spawn_keys[cand.spawn_key] = true
			var assignment: KeyLockAssignment = KeyLockAssignment.new(connector_idx_in_room, cand.spawn_path, key_id)

			if not allocated_assignments.has(cand.room_index):
				allocated_assignments[cand.room_index] = []
			allocated_assignments[cand.room_index].append(assignment)

			unlocked_edges.append(edge)

			if _search_allocation(graph, locked_edges, allocated_assignments, allocated_spawn_keys, unlocked_edges):
				return true

			unlocked_edges.erase(edge)
			var list: Array = allocated_assignments[cand.room_index]
			list.erase(assignment)
			if list.is_empty():
				allocated_assignments.erase(cand.room_index)
			allocated_spawn_keys.erase(cand.spawn_key)

	return false


func _is_edge_locked(graph: DungeonGraph, edge: Dictionary) -> bool:
	var room_a: Dictionary = graph.placements[edge.room_a_index]
	var data_a: Dictionary = _cache.get(room_a.room_data.room_scene, {})
	if not data_a.is_empty():
		var connectors: Array = data_a.get("connectors", [])
		for conn_val: Variant in connectors:
			var conn: Dictionary = conn_val as Dictionary
			if conn.transform.is_equal_approx(edge.connector_a_local) and conn.is_locked:
				return true

	var room_b: Dictionary = graph.placements[edge.room_b_index]
	var data_b: Dictionary = _cache.get(room_b.room_data.room_scene, {})
	if not data_b.is_empty():
		var connectors: Array = data_b.get("connectors", [])
		for conn_val: Variant in connectors:
			var conn: Dictionary = conn_val as Dictionary
			if conn.transform.is_equal_approx(edge.connector_b_local) and conn.is_locked:
				return true

	return false


func _get_edge_key_id(graph: DungeonGraph, edge: Dictionary) -> String:
	var room_a: Dictionary = graph.placements[edge.room_a_index]
	var data_a: Dictionary = _cache.get(room_a.room_data.room_scene, {})
	if not data_a.is_empty():
		var connectors: Array = data_a.get("connectors", [])
		for conn_val: Variant in connectors:
			var conn: Dictionary = conn_val as Dictionary
			if conn.transform.is_equal_approx(edge.connector_a_local) and conn.is_locked:
				return conn.key_id as String

	var room_b: Dictionary = graph.placements[edge.room_b_index]
	var data_b: Dictionary = _cache.get(room_b.room_data.room_scene, {})
	if not data_b.is_empty():
		var connectors: Array = data_b.get("connectors", [])
		for conn_val: Variant in connectors:
			var conn: Dictionary = conn_val as Dictionary
			if conn.transform.is_equal_approx(edge.connector_b_local) and conn.is_locked:
				return conn.key_id as String

	return ""


func _can_reach_boss(graph: DungeonGraph, unlocked_edges: Array[Dictionary]) -> bool:
	var reachable: Array[int] = _get_reachable_rooms(graph, unlocked_edges)
	var boss_idx: int = -1
	for i: int in range(graph.placements.size()):
		if graph.placements[i].category == RoomData.RoomCategory.BOSS:
			boss_idx = i
			break
	return boss_idx in reachable


func _get_reachable_rooms(graph: DungeonGraph, unlocked_edges: Array[Dictionary]) -> Array[int]:
	var reachable: Array[int] = [0]
	var queue: Array[int] = [0]

	while not queue.is_empty():
		var curr: int = queue.pop_front()
		for edge: Dictionary in graph.edges:
			var neighbor: int = -1
			if edge.room_a_index == curr:
				neighbor = edge.room_b_index
			elif edge.room_b_index == curr:
				neighbor = edge.room_a_index

			if neighbor >= 0 and neighbor not in reachable:
				if not _is_edge_locked(graph, edge) or edge in unlocked_edges:
					reachable.append(neighbor)
					queue.append(neighbor)

	return reachable


func _get_shortest_path_distance(graph: DungeonGraph, from_idx: int, to_idx: int, unlocked_edges: Array[Dictionary]) -> int:
	var visited: Dictionary = {from_idx: 0}
	var queue: Array[int] = [from_idx]

	while not queue.is_empty():
		var curr: int = queue.pop_front()
		var curr_dist: int = visited[curr]
		if curr == to_idx:
			return curr_dist

		for edge: Dictionary in graph.edges:
			var neighbor: int = -1
			if edge.room_a_index == curr:
				neighbor = edge.room_b_index
			elif edge.room_b_index == curr:
				neighbor = edge.room_a_index

			if neighbor >= 0 and neighbor not in visited:
				if not _is_edge_locked(graph, edge) or edge in unlocked_edges:
					visited[neighbor] = curr_dist + 1
					queue.append(neighbor)

	return 999999

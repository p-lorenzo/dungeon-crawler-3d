@tool
extends SceneTree

const RoomConnector3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd")
const KeySpawnPoint3DScript: Script = preload("res://plugins/dungeon_crawler_3d/nodes/key_spawn_point_3d.gd")

func _initialize() -> void:
	print("--- STARTING LOCK & KEY TESTS ---")
	var success := run_tests()
	if success:
		print("--- LOCK & KEY TESTS PASSED ---")
		quit(0)
	else:
		print("--- LOCK & KEY TESTS FAILED ---")
		quit(1)


func create_room_scene(room_name: String, connectors_info: Array[Dictionary], key_spawns: Array[String] = []) -> PackedScene:
	var room := Node3D.new()
	room.name = room_name
	
	# Basic mesh representing the room
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(4, 4, 4)
	mesh_inst.mesh = mesh
	room.add_child(mesh_inst)
	mesh_inst.owner = room

	for c_info in connectors_info:
		# Use RoomConnector3D constructor or script attachment
		var conn := RoomConnector3D.new()
		conn.name = c_info.name
		conn.connection_type = c_info.get("connection_type", "standard_door")
		conn.transform = c_info.transform
		conn.is_locked = c_info.get("is_locked", false)
		conn.key_id = c_info.get("key_id", "")
		room.add_child(conn)
		conn.owner = room
		
	for key_id in key_spawns:
		var spawn := KeySpawnPoint3D.new()
		spawn.name = "KeySpawnPoint_" + key_id
		spawn.key_id = key_id
		room.add_child(spawn)
		spawn.owner = room
		
	var packed := PackedScene.new()
	var err := packed.pack(room)
	if err != OK:
		printerr("Failed to pack room scene: ", room_name)
	room.free()
	return packed


func run_tests() -> bool:
	var entrance_info: Array[Dictionary] = [
		{"name": "Exit", "transform": Transform3D(Basis.IDENTITY, Vector3(0, 0, 2))}
	]
	var corridor_info: Array[Dictionary] = [
		{"name": "Entry", "transform": Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3(0, 0, -2))},
		{"name": "Exit", "transform": Transform3D(Basis.IDENTITY, Vector3(0, 0, 2))}
	]
	# A corridor with a locked exit connector
	var locked_corridor_info: Array[Dictionary] = [
		{"name": "Entry", "transform": Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3(0, 0, -2))},
		{"name": "Exit", "transform": Transform3D(Basis.IDENTITY, Vector3(0, 0, 2)), "is_locked": true, "key_id": "iron_key"}
	]
	# A corridor with a boss locked exit connector
	var boss_locked_corridor_info: Array[Dictionary] = [
		{"name": "Entry", "transform": Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3(0, 0, -2))},
		{"name": "Exit", "transform": Transform3D(Basis.IDENTITY, Vector3(0, 0, 2)), "is_locked": true, "key_id": "boss_key"}
	]
	var dead_end_info: Array[Dictionary] = [
		{"name": "Entry", "transform": Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3(0, 0, -2))}
	]
	var boss_info: Array[Dictionary] = [
		{"name": "Entry", "transform": Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3(0, 0, -2))}
	]

	# Build scenes
	# Scene A: Dead end containing iron key
	var dead_end_with_iron_key := create_room_scene("DeadEndWithIronKey", dead_end_info, ["iron_key"])
	# Scene B: Entrance containing no keys
	var entrance_scene := create_room_scene("EntranceRoom", entrance_info)
	# Scene C: Locked corridor requiring iron key
	var locked_corridor_scene := create_room_scene("LockedCorridorRoom", locked_corridor_info)
	# Scene D: Corridor containing boss key spawn point
	var corridor_with_boss_key := create_room_scene("CorridorWithBossKey", corridor_info, ["boss_key"])
	# Scene E: Locked corridor requiring boss key
	var boss_locked_scene := create_room_scene("BossLockedRoom", boss_locked_corridor_info)
	# Scene F: Boss room
	var boss_scene := create_room_scene("BossRoom", boss_info)
	
	# Set up global configs
	var entrance_data := RoomData.new()
	entrance_data.room_scene = entrance_scene
	entrance_data.category = RoomData.RoomCategory.ENTRANCE
	entrance_data.spawn_weight = 1.0

	var locked_corridor_data := RoomData.new()
	locked_corridor_data.room_scene = locked_corridor_scene
	locked_corridor_data.category = RoomData.RoomCategory.CORRIDOR
	locked_corridor_data.spawn_weight = 1.0

	var boss_locked_data := RoomData.new()
	boss_locked_data.room_scene = boss_locked_scene
	boss_locked_data.category = RoomData.RoomCategory.CORRIDOR
	boss_locked_data.spawn_weight = 1.0

	var corridor_boss_key_data := RoomData.new()
	corridor_boss_key_data.room_scene = corridor_with_boss_key
	corridor_boss_key_data.category = RoomData.RoomCategory.CORRIDOR
	corridor_boss_key_data.spawn_weight = 1.0

	var dead_end_iron_key_data := RoomData.new()
	dead_end_iron_key_data.room_scene = dead_end_with_iron_key
	dead_end_iron_key_data.category = RoomData.RoomCategory.DEAD_END
	dead_end_iron_key_data.spawn_weight = 1.0

	var boss_room_data := RoomData.new()
	boss_room_data.room_scene = boss_scene
	boss_room_data.category = RoomData.RoomCategory.BOSS
	boss_room_data.spawn_weight = 1.0

	# Test 1: Solvable topological allocation (Story 2 & FR-005 & SC-001)
	print("Running Test 1 (Topological Key Allocation)...")
	var config := DungeonConfig.new()
	config.random_seed = 12345
	config.main_path_length = 5
	config.branch_count = 1
	config.branch_depth_min = 1
	config.branch_depth_max = 1
	config.room_count_min = 6
	config.room_count_max = 10
	config.max_generation_attempts = 20

	config.entrance_pool = [entrance_data]
	config.boss_pool = [boss_room_data]
	# The corridor pool has both standard (or lock/key carrying) rooms
	# We want a locked door, then we want to make sure the key is placed in a predecessor room
	# To ensure key can be placed, dead_end_iron_key_data contains the key, and is placed in the branch.
	# Let's verify that the generator successfully runs and matches them.
	config.corridor_pool = [locked_corridor_data, corridor_boss_key_data]
	config.junction_pool = [] # No junctions to keep layout simple
	config.dead_end_pool = [dead_end_iron_key_data]

	var generator := DungeonGenerator3D.new()
	generator.config = config
	root.add_child(generator)

	generator.generate()

	var graph: DungeonGraph = generator.active_graph
	if not graph or graph.placements.is_empty():
		printerr("Test 1 failure: DungeonGenerator failed to produce a layout with lock puzzles")
		generator.queue_free()
		return false

	var dungeon_root: Node3D = generator.get_child(generator.get_child_count() - 1) as Node3D
	if not dungeon_root:
		printerr("Test 1 failure: DungeonLayout root node not found")
		generator.queue_free()
		return false

	# Let's verify assignments
	print("Assignments generated: ", graph.key_lock_assignments)
	if graph.key_lock_assignments.is_empty():
		printerr("Test 1 failure: Key assignments are empty despite having locked doors in the layout")
		generator.queue_free()
		return false

	# Let's trace the graph and verify solvable order.
	# Key "iron_key" must be assigned to a room index that resides BEFORE the locked connector room index in the traversal sequence from entrance (index 0).
	var iron_key_spawn_room_idx := -1
	var iron_door_room_idx := -1

	for room_idx in graph.key_lock_assignments.keys():
		var list: Array = graph.key_lock_assignments[room_idx]
		for assign: KeyLockAssignment in list:
			if assign.key_id == "iron_key":
				iron_key_spawn_room_idx = room_idx

	# Find where the locked connector is in the placements
	for i in range(graph.placements.size()):
		var placement: Dictionary = graph.placements[i]
		var scene: PackedScene = placement.room_data.room_scene
		var state: SceneState = scene.get_state()
		for node_idx in range(state.get_node_count()):
			if state.get_node_type(node_idx) == "RoomConnector3D":
				for p in range(state.get_node_property_count(node_idx)):
					if state.get_node_property_name(node_idx, p) == "is_locked" and state.get_node_property_value(node_idx, p) == true:
						if state.get_node_property_value(node_idx, p + 1) == "iron_key" or state.get_node_property_name(node_idx, p + 1) == "key_id" and state.get_node_property_value(node_idx, p + 1) == "iron_key":
							iron_door_room_idx = i
							break

	print("Iron Key Room Index: ", iron_key_spawn_room_idx)
	print("Iron Door Room Index: ", iron_door_room_idx)

	# Verify that we can reach iron_key_spawn_room_idx from start (0) without crossing the locked door edge
	# Let's find the locked edge in graph
	var locked_edge: Dictionary = {}
	var manager := KeyLockManager.new()
	manager.populate_cache(config)
	for edge: Dictionary in graph.edges:
		if manager._is_edge_locked(graph, edge) and manager._get_edge_key_id(graph, edge) == "iron_key":
			locked_edge = edge
			break

	if locked_edge.is_empty():
		printerr("Test 1 failure: Locked edge for 'iron_key' not found in graph")
		generator.queue_free()
		return false

	# Simple BFS from room 0 to iron_key_spawn_room_idx, forbidding locked_edge
	var visited := {0: true}
	var queue := [0]
	var path_found := false
	while not queue.is_empty():
		var curr: int = queue.pop_front()
		if curr == iron_key_spawn_room_idx:
			path_found = true
			break
		for edge: Dictionary in graph.edges:
			if edge.room_a_index == locked_edge.room_a_index and edge.room_b_index == locked_edge.room_b_index:
				continue # skip locked edge
			var neighbor := -1
			if edge.room_a_index == curr:
				neighbor = edge.room_b_index
			elif edge.room_b_index == curr:
				neighbor = edge.room_a_index
			if neighbor != -1 and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	if not path_found:
		printerr("Test 1 failure: 'iron_key' spawned in a room that is not reachable from the entrance without crossing the locked door! (Soft-lock)")
		generator.queue_free()
		return false

	# Verify 3D Spawning (Story 3)
	# Find Key instance in the SceneTree
	var key_mesh_found := false
	var door_mesh_found := false
	for room_node: Node3D in dungeon_root.get_children():
		# Search for spawned key (fallback MeshInstance3D with SphereMesh)
		for child in room_node.find_children("*", "MeshInstance3D", true, false):
			var mesh_inst := child as MeshInstance3D
			if mesh_inst.mesh is SphereMesh:
				key_mesh_found = true
			elif mesh_inst.mesh is BoxMesh and mesh_inst.mesh.size == Vector3(1.5, 2.5, 0.2):
				door_mesh_found = true

	if not key_mesh_found:
		printerr("Test 1 failure: Key item mesh/actor not spawned in the 3D world")
		generator.queue_free()
		return false

	if not door_mesh_found:
		printerr("Test 1 failure: Locked door mesh/actor not spawned in the 3D world")
		generator.queue_free()
		return false

	generator.queue_free()
	print("Test 1 PASSED.")

	# Test 2: Soft-lock prevention / fallback rollback (FR-008)
	print("Running Test 2 (Unsolvable puzzle configuration rollback)...")
	var unsolvable_config := DungeonConfig.new()
	unsolvable_config.random_seed = 54321
	unsolvable_config.main_path_length = 4
	unsolvable_config.branch_count = 0 # No branches
	unsolvable_config.room_count_min = 4
	unsolvable_config.room_count_max = 5
	unsolvable_config.max_generation_attempts = 5

	unsolvable_config.entrance_pool = [entrance_data]
	unsolvable_config.boss_pool = [boss_room_data]
	# The corridor pool contains locked corridor, but we have NO dead ends or spawn points in the main path.
	# Thus, it is impossible to solve the dungeon. The generator should fail.
	unsolvable_config.corridor_pool = [locked_corridor_data]
	unsolvable_config.dead_end_pool = []

	var unsolvable_generator := DungeonGenerator3D.new()
	unsolvable_generator.config = unsolvable_config
	root.add_child(unsolvable_generator)

	var failed_signal_emitted := [false]
	unsolvable_generator.generation_failed.connect(func(reason: String):
		failed_signal_emitted[0] = true
		print("  Generation failed successfully as expected: ", reason)
	)

	unsolvable_generator.generate()

	if not failed_signal_emitted[0]:
		printerr("Test 2 failure: Unsolvable lock config generated successfully without failing!")
		unsolvable_generator.queue_free()
		return false

	unsolvable_generator.queue_free()
	print("Test 2 PASSED.")

	return true

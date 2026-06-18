@tool
extends SceneTree


func _initialize() -> void:
	print("--- STARTING NAVMESH BAKING TESTS ---")
	# Await one frame to ensure SceneTree is fully active
	await process_frame
	var success := await run_tests()
	if success:
		print("--- NAVMESH BAKING TESTS PASSED ---")
		quit(0)
	else:
		print("--- NAVMESH BAKING TESTS FAILED ---")
		quit(1)


func run_tests() -> bool:
	var config: DungeonConfig = load("res://demo/demo_config.tres")
	if not config:
		printerr("Test error: Failed to load res://demo/demo_config.tres")
		return false

	config.random_seed = 12345

	# Test 1: Fallback for missing/unresolved navigation region (FR-008)
	print("Running Test 1 (Missing Navigation Region Fallback)...")
	var generator1 := DungeonGenerator3D.new()
	generator1.config = config
	root.add_child(generator1)

	var adapter1 := DungeonNavMeshAdapter3D.new()
	adapter1.bake_on_completed = true
	adapter1.use_collision_geometry = false
	adapter1.navigation_layers = 4
	adapter1.bake_async = false # synchronous bake for testing
	generator1.add_child(adapter1)

	# Await a frame to ensure ready is processed and nodes are inside the tree
	await process_frame

	generator1.generate()

	var dungeon_root1: Node3D = generator1.get_child(generator1.get_child_count() - 1) as Node3D
	if not dungeon_root1 or dungeon_root1.name != "DungeonLayout":
		printerr("Test 1 failure: DungeonLayout root node not found")
		generator1.queue_free()
		return false

	# Look for dynamic NavigationRegion3D
	var dynamic_region: NavigationRegion3D = null
	for child in dungeon_root1.get_children():
		if child is NavigationRegion3D:
			dynamic_region = child
			break

	if not dynamic_region:
		printerr("Test 1 failure: Dynamic NavigationRegion3D not created under dungeon layout root")
		generator1.queue_free()
		return false

	if dynamic_region.name != "DungeonNavigationRegion3D":
		printerr("Test 1 failure: Dynamic NavigationRegion3D name is '%s', expected 'DungeonNavigationRegion3D'" % dynamic_region.name)
		generator1.queue_free()
		return false

	if not dynamic_region.navigation_mesh:
		printerr("Test 1 failure: Dynamic NavigationRegion3D has no navigation mesh resource")
		generator1.queue_free()
		return false

	var nav_mesh1: NavigationMesh = dynamic_region.navigation_mesh
	if nav_mesh1.geometry_source_geometry_mode != NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN:
		printerr("Test 1 failure: Geometry source mode is %d, expected SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN (1)" % nav_mesh1.geometry_source_geometry_mode)
		generator1.queue_free()
		return false

	var expected_group1: String = "dungeon_bake_group_" + str(dungeon_root1.get_instance_id())
	if nav_mesh1.geometry_source_group_name != expected_group1:
		printerr("Test 1 failure: Group name is '%s', expected '%s'" % [nav_mesh1.geometry_source_group_name, expected_group1])
		generator1.queue_free()
		return false

	if nav_mesh1.geometry_parsed_geometry_type != NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES:
		printerr("Test 1 failure: Geometry parsed type is %d, expected PARSED_GEOMETRY_MESH_INSTANCES (0)" % nav_mesh1.geometry_parsed_geometry_type)
		generator1.queue_free()
		return false

	if dynamic_region.navigation_layers != 4:
		printerr("Test 1 failure: Navigation layers bitmask is %d, expected 4" % dynamic_region.navigation_layers)
		generator1.queue_free()
		return false

	generator1.queue_free()
	print("Test 1 PASSED.")

	# Test 2: External navigation region (FR-004, FR-005)
	print("Running Test 2 (External Navigation Region)...")
	var generator2 := DungeonGenerator3D.new()
	generator2.config = config
	root.add_child(generator2)

	var external_region := NavigationRegion3D.new()
	external_region.name = "MyExternalNavRegion"
	root.add_child(external_region)

	var adapter2 := DungeonNavMeshAdapter3D.new()
	adapter2.navigation_region = external_region
	adapter2.bake_on_completed = true
	adapter2.use_collision_geometry = true # Use collisions
	adapter2.navigation_layers = 2
	adapter2.bake_async = false
	generator2.add_child(adapter2)

	# Await a frame to ensure ready is processed and nodes are inside the tree
	await process_frame

	generator2.generate()

	var dungeon_root2: Node3D = generator2.get_child(generator2.get_child_count() - 1) as Node3D
	if not dungeon_root2:
		printerr("Test 2 failure: DungeonLayout root node not found")
		generator2.queue_free()
		external_region.queue_free()
		return false

	if not external_region.navigation_mesh:
		printerr("Test 2 failure: External region navigation mesh resource is missing")
		generator2.queue_free()
		external_region.queue_free()
		return false

	var nav_mesh2: NavigationMesh = external_region.navigation_mesh
	if nav_mesh2.geometry_source_geometry_mode != NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN:
		printerr("Test 2 failure: Geometry source mode is %d, expected SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN (1)" % nav_mesh2.geometry_source_geometry_mode)
		generator2.queue_free()
		external_region.queue_free()
		return false

	var expected_group2: String = "dungeon_bake_group_" + str(dungeon_root2.get_instance_id())
	if nav_mesh2.geometry_source_group_name != expected_group2:
		printerr("Test 2 failure: Group name is '%s', expected '%s'" % [nav_mesh2.geometry_source_group_name, expected_group2])
		generator2.queue_free()
		external_region.queue_free()
		return false

	if nav_mesh2.geometry_parsed_geometry_type != NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS:
		printerr("Test 2 failure: Geometry parsed type is %d, expected PARSED_GEOMETRY_STATIC_COLLIDERS (1)" % nav_mesh2.geometry_parsed_geometry_type)
		generator2.queue_free()
		external_region.queue_free()
		return false

	if external_region.navigation_layers != 2:
		printerr("Test 2 failure: Navigation layers bitmask is %d, expected 2" % external_region.navigation_layers)
		generator2.queue_free()
		external_region.queue_free()
		return false

	generator2.queue_free()
	external_region.queue_free()
	print("Test 2 PASSED.")

	return true

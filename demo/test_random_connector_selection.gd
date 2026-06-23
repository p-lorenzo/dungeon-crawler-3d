@tool
extends SceneTree


func _initialize() -> void:
	print("--- STARTING RANDOM CONNECTOR SELECTION TESTS ---")
	var success := run_tests()
	if success:
		print("--- RANDOM CONNECTOR SELECTION TESTS PASSED ---")
		quit(0)
	else:
		print("--- RANDOM CONNECTOR SELECTION TESTS FAILED ---")
		quit(1)


func run_tests() -> bool:
	var config: DungeonConfig = load("res://demo/demo_config.tres")
	if not config:
		printerr("Test error: Failed to load res://demo/demo_config.tres")
		return false

	# We configure branch depth and length to allow winding path generation
	config.main_path_length = 8
	config.branch_count = 2

	# 1. Run Generation with Seed A
	config.random_seed = 456789
	var generator_a := DungeonGenerator3D.new()
	generator_a.config = config
	root.add_child(generator_a)
	generator_a.generate()

	var graph_a: DungeonGraph = generator_a.active_graph
	if not graph_a or graph_a.placements.is_empty():
		printerr("Test error: Generator A produced no active graph or placements")
		generator_a.free()
		return false

	# 2. Run Generation with Seed A again (reproducibility check)
	var generator_a_dup := DungeonGenerator3D.new()
	generator_a_dup.config = config
	root.add_child(generator_a_dup)
	generator_a_dup.generate()

	var graph_a_dup: DungeonGraph = generator_a_dup.active_graph
	if not graph_a_dup or graph_a_dup.placements.size() != graph_a.placements.size():
		printerr("Verification failure: Duplicate run with same seed produced different room count")
		generator_a.free()
		generator_a_dup.free()
		return false

	# Verify placements are identical (reproducibility check)
	for i in range(graph_a.placements.size()):
		var p1: Dictionary = graph_a.placements[i]
		var p2: Dictionary = graph_a_dup.placements[i]
		if p1.room_data.room_scene != p2.room_data.room_scene:
			printerr("Verification failure: Room scene mismatch at index %d" % i)
			generator_a.free()
			generator_a_dup.free()
			return false
		if not p1.world_transform.is_equal_approx(p2.world_transform):
			printerr("Verification failure: Room transform mismatch at index %d" % i)
			generator_a.free()
			generator_a_dup.free()
			return false

	# 3. Run Generation with Seed B (variability check)
	config.random_seed = 987654
	var generator_b := DungeonGenerator3D.new()
	generator_b.config = config
	root.add_child(generator_b)
	generator_b.generate()

	var graph_b: DungeonGraph = generator_b.active_graph
	var transforms_differ := false
	if graph_b and graph_b.placements.size() == graph_a.placements.size():
		for i in range(graph_a.placements.size()):
			var p_a: Dictionary = graph_a.placements[i]
			var p_b: Dictionary = graph_b.placements[i]
			if not p_a.world_transform.is_equal_approx(p_b.world_transform):
				transforms_differ = true
				break
	else:
		transforms_differ = true

	if not transforms_differ:
		printerr("Verification failure: Different seeds produced identical layout")
		generator_a.free()
		generator_a_dup.free()
		generator_b.free()
		return false

	# 4. Verify Winding / Non-collinear paths
	var winding_a := check_is_winding(graph_a.placements)
	var winding_b := check_is_winding(graph_b.placements)

	if not winding_a and not winding_b:
		printerr("Verification failure: Layouts are completely straight (non-winding)")
		generator_a.free()
		generator_a_dup.free()
		generator_b.free()
		return false

	print("Winding layout verified: Seed A is winding: %s, Seed B is winding: %s" % [winding_a, winding_b])

	generator_a.free()
	generator_a_dup.free()
	generator_b.free()
	return true


# Helper function to check if the path has turns (is not collinear)
func check_is_winding(placements: Array) -> bool:
	if placements.size() < 3:
		return false

	for i in range(placements.size() - 2):
		var p0: Vector3 = placements[i].world_transform.origin
		var p1: Vector3 = placements[i+1].world_transform.origin
		var p2: Vector3 = placements[i+2].world_transform.origin

		var v1 := p1 - p0
		var v2 := p2 - p0

		# Check 2D cross product on XZ plane (since Y height is flat)
		var cross_y := v1.x * v2.z - v1.z * v2.x
		if abs(cross_y) > 0.1:
			return true # Non-collinear turn found!

	return false

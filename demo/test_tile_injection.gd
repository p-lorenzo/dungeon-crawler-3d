@tool
extends SceneTree

const TileInjectionRuleScript = preload("res://plugins/dungeon_crawler_3d/resources/tile_injection_rule.gd")

func _initialize() -> void:
	print("--- STARTING TILE INJECTION TESTS ---")
	var success := run_tests()
	if success:
		print("--- TILE INJECTION TESTS PASSED ---")
		quit(0)
	else:
		print("--- TILE INJECTION TESTS FAILED ---")
		quit(1)


func run_tests() -> bool:
	var base_config: DungeonConfig = load("res://demo/demo_config.tres")
	if not base_config:
		printerr("Test error: Failed to load res://demo/demo_config.tres")
		return false

	var special_room_scene: PackedScene = load("res://demo/rooms/junction.tscn")
	if not special_room_scene:
		printerr("Test error: Failed to load junction.tscn")
		return false
	
	var special_room_data := RoomData.new()
	special_room_data.room_scene = special_room_scene
	special_room_data.spawn_weight = 1.0
	special_room_data.category = RoomData.RoomCategory.JUNCTION

	# Test 1: Inject unique room on main path (P1)
	print("Running Test 1 (Inject unique room on main path)...")
	var config := base_config.duplicate()
	config.random_seed = 12345
	config.main_path_length = 8
	config.branch_count = 0
	config.room_count_min = 8
	config.room_count_max = 20
	config.injected_tiles.clear()

	var rule := TileInjectionRuleScript.new()
	rule.room_data = special_room_data
	rule.min_path_percentage = 0.4
	rule.max_path_percentage = 0.6
	rule.placement_target = 0 # MAIN_PATH
	rule.is_required = true
	config.injected_tiles.append(rule)

	var generator := DungeonGenerator3D.new()
	generator.config = config
	root.add_child(generator)
	generator.generate()

	if not generator.active_graph:
		printerr("Test 1 failure: Generator failed to build dungeon layout")
		generator.queue_free()
		return false

	var graph: DungeonGraph = generator.active_graph
	var special_room_placed := false
	var special_room_depth := -1

	for i in range(graph.main_path.size()):
		var idx: int = graph.main_path[i]
		var placement: Dictionary = graph.placements[idx]
		if placement.room_data == special_room_data:
			special_room_placed = true
			special_room_depth = i
			break

	if not special_room_placed:
		printerr("Test 1 failure: Special room was not placed on the main path")
		generator.queue_free()
		return false

	print("  Special room placed at main path depth: %d" % special_room_depth)
	if special_room_depth != 3 and special_room_depth != 4:
		printerr("Test 1 failure: Special room placed at depth %d, which is outside range 3-4 (p=0.428 to 0.571)" % special_room_depth)
		generator.queue_free()
		return false

	generator.queue_free()

	# Test 2: Acceptance Scenario 1
	print("Running Test 2 (Acceptance Scenario 1)...")
	var config2 := base_config.duplicate()
	config2.random_seed = 98765
	config2.main_path_length = 10
	config2.branch_count = 0
	config2.room_count_min = 10
	config2.room_count_max = 20
	config2.injected_tiles.clear()

	var rule2 := TileInjectionRuleScript.new()
	rule2.room_data = special_room_data
	rule2.min_path_percentage = 0.3
	rule2.max_path_percentage = 0.5
	rule2.placement_target = 0 # MAIN_PATH
	rule2.is_required = true
	config2.injected_tiles.append(rule2)

	var generator2 := DungeonGenerator3D.new()
	generator2.config = config2
	root.add_child(generator2)
	generator2.generate()

	if not generator2.active_graph:
		printerr("Test 2 failure: Generator failed to build dungeon layout")
		generator2.queue_free()
		return false

	var graph2: DungeonGraph = generator2.active_graph
	var special_placed2 := false
	var special_depth2 := -1
	for i in range(graph2.main_path.size()):
		var idx: int = graph2.main_path[i]
		if graph2.placements[idx].room_data == special_room_data:
			special_placed2 = true
			special_depth2 = i
			break

	if not special_placed2:
		printerr("Test 2 failure: Special room was not placed")
		generator2.queue_free()
		return false

	print("  Special room placed at depth: %d" % special_depth2)
	if special_depth2 < 3 or special_depth2 > 5:
		printerr("Test 2 failure: Special room placed at depth %d, expected between 3 and 5" % special_depth2)
		generator2.queue_free()
		return false

	generator2.queue_free()

	# Test 3: Required injection failure and retry (P2)
	print("Running Test 3 (Required injection failure with incompatible connectors)...")
	var incompatible_room_scene := load("res://demo/blocker.tscn")
	var incompatible_room_data := RoomData.new()
	incompatible_room_data.room_scene = incompatible_room_scene
	incompatible_room_data.spawn_weight = 1.0
	incompatible_room_data.category = RoomData.RoomCategory.CORRIDOR

	var config3 := base_config.duplicate()
	config3.random_seed = 4444
	config3.max_generation_attempts = 3
	config3.injected_tiles.clear()

	var rule3 := TileInjectionRuleScript.new()
	rule3.room_data = incompatible_room_data
	rule3.min_path_percentage = 0.2
	rule3.max_path_percentage = 0.8
	rule3.placement_target = 0 # MAIN_PATH
	rule3.is_required = true
	config3.injected_tiles.append(rule3)

	var generator3 := DungeonGenerator3D.new()
	generator3.config = config3
	root.add_child(generator3)

	var signal_state := {
		"failed_signal_emitted": false,
		"error_reason": ""
	}
	generator3.generation_failed.connect(func(reason: String):
		signal_state.failed_signal_emitted = true
		signal_state.error_reason = reason
	)

	print("  Before generate() - failed_signal_emitted: ", signal_state.failed_signal_emitted)
	generator3.generate()
	print("  After generate() - failed_signal_emitted: ", signal_state.failed_signal_emitted)
	if generator3.active_graph:
		print("  active_graph placements size: ", generator3.active_graph.placements.size())
	else:
		print("  active_graph is null")

	if not signal_state.failed_signal_emitted:
		printerr("Test 3 failure: Incompatible required injection should have failed generation but it succeeded or did not emit generation_failed")
		generator3.queue_free()
		return false

	print("  Generation failed cleanly as expected. Reason: ", signal_state.error_reason)
	generator3.queue_free()

	# Test 4: Inject on branch (P3)
	print("Running Test 4 (Inject on branch)...")
	var config4 := base_config.duplicate()
	config4.random_seed = 7777
	config4.main_path_length = 5
	config4.branch_count = 2
	config4.branch_depth_min = 3
	config4.branch_depth_max = 3
	config4.room_count_min = 5
	config4.room_count_max = 20
	config4.injected_tiles.clear()

	var rule4 := TileInjectionRuleScript.new()
	rule4.room_data = special_room_data
	rule4.min_path_percentage = 0.5
	rule4.max_path_percentage = 1.0
	rule4.placement_target = 1 # BRANCH
	rule4.is_required = true
	config4.injected_tiles.append(rule4)

	var generator4 := DungeonGenerator3D.new()
	generator4.config = config4
	root.add_child(generator4)
	generator4.generate()

	if not generator4.active_graph:
		printerr("Test 4 failure: Generator failed to build dungeon layout")
		generator4.queue_free()
		return false

	var graph4: DungeonGraph = generator4.active_graph
	var special_on_main := false
	var special_on_branch := false

	for idx in graph4.main_path:
		if graph4.placements[idx].room_data == special_room_data:
			special_on_main = true

	for branch in graph4.branches:
		for idx in branch:
			if graph4.placements[idx].room_data == special_room_data:
				special_on_branch = true

	if special_on_main:
		printerr("Test 4 failure: Special room injected on main path, but targeted BRANCH")
		generator4.queue_free()
		return false

	if not special_on_branch:
		printerr("Test 4 failure: Special room was not injected on any branch path")
		generator4.queue_free()
		return false

	print("  Special room successfully injected on a branch path and NOT on main path.")
	generator4.queue_free()

	return true

@tool
extends SceneTree


func _initialize() -> void:
	print("--- STARTING PROP RANDOMIZER TESTS ---")
	var success := run_tests()
	if success:
		print("--- PROP RANDOMIZER TESTS PASSED ---")
		quit(0)
	else:
		print("--- PROP RANDOMIZER TESTS FAILED ---")
		quit(1)


func run_tests() -> bool:
	var prop_a_scene := load("res://demo/prop_a.tscn") as PackedScene
	var prop_b_scene := load("res://demo/prop_b.tscn") as PackedScene
	if not prop_a_scene or not prop_b_scene:
		printerr("Test error: Failed to load prop_a or prop_b scene")
		return false

	# Test 1: Weighted selection (100% A, 0% B)
	print("Running Test 1 (Weighted selection 100% A)...")
	var group_a := PropGroup3D.new()
	group_a.prop_pool = [prop_a_scene, prop_b_scene]
	group_a.weights = [10.0, 0.0]
	group_a.spawn_chance = 1.0
	group_a.prop_category = "test_prop"

	var config := DungeonConfig.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var manager := DungeonPropManager.new(config, rng)
	for i in range(100):
		var selected := manager.evaluate_prop_group(group_a)
		if not selected:
			printerr("Test 1 failure: prop did not spawn")
			return false
		var inst: Node = selected.instantiate()
		var is_a := (inst.name == "PropA")
		inst.queue_free()
		if not is_a:
			printerr("Test 1 failure: expected PropA, got PropB")
			return false

	# Test 2: Weighted selection (0% A, 100% B)
	print("Running Test 2 (Weighted selection 100% B)...")
	var group_b := PropGroup3D.new()
	group_b.prop_pool = [prop_a_scene, prop_b_scene]
	group_b.weights = [0.0, 10.0]
	group_b.spawn_chance = 1.0
	group_b.prop_category = "test_prop"

	for i in range(100):
		var selected := manager.evaluate_prop_group(group_b)
		if not selected:
			printerr("Test 2 failure: prop did not spawn")
			return false
		var inst: Node = selected.instantiate()
		var is_b := (inst.name == "PropB")
		inst.queue_free()
		if not is_b:
			printerr("Test 2 failure: expected PropB, got PropA")
			return false

	# Test 3: Weight mismatch fallback (uniform selection)
	print("Running Test 3 (Weight mismatch fallback)...")
	var group_mismatch := PropGroup3D.new()
	group_mismatch.prop_pool = [prop_a_scene, prop_b_scene]
	group_mismatch.weights = [1.0] # Mismatched size!
	group_mismatch.spawn_chance = 1.0
	group_mismatch.prop_category = "test_prop"

	var spawn_a_count := 0
	var spawn_b_count := 0
	for i in range(200):
		var selected := manager.evaluate_prop_group(group_mismatch)
		if not selected:
			printerr("Test 3 failure: prop did not spawn")
			return false
		var inst: Node = selected.instantiate()
		if inst.name == "PropA":
			spawn_a_count += 1
		elif inst.name == "PropB":
			spawn_b_count += 1
		inst.queue_free()

	print("  Uniform fallback counts: PropA=%d, PropB=%d" % [spawn_a_count, spawn_b_count])
	if spawn_a_count == 0 or spawn_b_count == 0:
		printerr("Test 3 failure: mismatched weights did not fall back to uniform selection")
		return false

	# Test 4: Global limit clamping
	print("Running Test 4 (Global limit clamping)...")
	var limit_config := DungeonConfig.new()
	limit_config.global_prop_limits = {"chest": 2}
	
	var limit_manager := DungeonPropManager.new(limit_config, rng)
	var chest_group := PropGroup3D.new()
	chest_group.prop_pool = [prop_a_scene]
	chest_group.spawn_chance = 1.0
	chest_group.prop_category = "chest"

	# Evaluate 5 times
	var spawned_scenes: Array[PackedScene] = []
	for i in range(5):
		var selected := limit_manager.evaluate_prop_group(chest_group)
		if selected:
			spawned_scenes.append(selected)

	if spawned_scenes.size() != 2:
		printerr("Test 4 failure: expected exactly 2 chests spawned, got %d" % spawned_scenes.size())
		return false

	# Test 5: Seed consistency (determinism)
	print("Running Test 5 (Seed consistency / Determinism)...")
	var group_rand := PropGroup3D.new()
	group_rand.prop_pool = [prop_a_scene, prop_b_scene]
	group_rand.weights = [1.0, 1.0]
	group_rand.spawn_chance = 0.5
	group_rand.prop_category = "random_prop"

	var seed_val := 987654
	
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = seed_val
	var manager1 := DungeonPropManager.new(config, rng1)
	var results1: Array[String] = []
	for i in range(100):
		var selected := manager1.evaluate_prop_group(group_rand)
		if selected:
			var inst: Node = selected.instantiate()
			results1.append(inst.name)
			inst.queue_free()
		else:
			results1.append("none")

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = seed_val
	var manager2 := DungeonPropManager.new(config, rng2)
	var results2: Array[String] = []
	for i in range(100):
		var selected := manager2.evaluate_prop_group(group_rand)
		if selected:
			var inst: Node = selected.instantiate()
			results2.append(inst.name)
			inst.queue_free()
		else:
			results2.append("none")

	for i in range(100):
		if results1[i] != results2[i]:
			printerr("Test 5 failure: inconsistent results with same seed at index %d (%s vs %s)" % [i, results1[i], results2[i]])
			return false

	# Test 6: In-context generation check
	print("Running Test 6 (In-context generation check)...")
	var source_scene: PackedScene = load("res://demo/rooms/corridor.tscn")
	if not source_scene:
		printerr("Test error: Failed to load res://demo/rooms/corridor.tscn")
		return false

	var instance := source_scene.instantiate() as Node3D
	var test_prop_group := PropGroup3D.new()
	test_prop_group.name = "TestPropGroupNode"
	test_prop_group.prop_category = "chest"
	test_prop_group.spawn_chance = 1.0
	test_prop_group.prop_pool = [prop_a_scene]
	instance.add_child(test_prop_group)
	test_prop_group.owner = instance

	var custom_packed := PackedScene.new()
	var err := custom_packed.pack(instance)
	instance.queue_free()
	if err != OK:
		printerr("Test error: Failed to pack custom room scene")
		return false

	# Set up generator
	var gen_config: DungeonConfig = load("res://demo/demo_config.tres").duplicate()
	gen_config.random_seed = 9999
	gen_config.global_prop_limits = {"chest": 1}
	
	# Replace corridors in pool with our custom packed scene
	var custom_room_data := RoomData.new()
	custom_room_data.room_scene = custom_packed
	custom_room_data.spawn_weight = 1.0
	custom_room_data.category = RoomData.RoomCategory.CORRIDOR

	gen_config.corridor_pool = [custom_room_data]

	var generator := DungeonGenerator3D.new()
	generator.config = gen_config
	root.add_child(generator)
	generator.generate()

	var dungeon_root: Node3D = generator.get_child(0) as Node3D
	if not dungeon_root:
		printerr("Test 6 failure: Failed to get DungeonLayout root")
		return false

	var chests_found := 0
	var unspawned_groups_found := 0
	var freed_groups_found := 0
	
	# Find all instantiated rooms
	for room: Node3D in dungeon_root.get_children():
		# Check for test prop groups
		for child in room.find_children("TestPropGroupNode", "PropGroup3D", true, false):
			var pg := child as PropGroup3D
			if pg:
				if pg.is_queued_for_deletion():
					freed_groups_found += 1
				elif pg.get_child_count() > 0:
					var prop_child = pg.get_child(0)
					if prop_child and prop_child.name == "PropA":
						chests_found += 1
				else:
					unspawned_groups_found += 1

	generator.queue_free()

	print("  Chests spawned in dungeon: %d" % chests_found)
	if chests_found != 1:
		printerr("Test 6 failure: expected exactly 1 chest spawned in dungeon, found %d" % chests_found)
		return false

	print("All tests passed.")
	return true

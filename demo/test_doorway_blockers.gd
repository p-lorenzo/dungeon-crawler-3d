@tool
extends SceneTree


func _initialize() -> void:
	print("--- STARTING DOORWAY BLOCKERS TESTS ---")
	var success := run_tests()
	if success:
		print("--- DOORWAY BLOCKERS TESTS PASSED ---")
		quit(0)
	else:
		print("--- DOORWAY BLOCKERS TESTS FAILED ---")
		quit(1)


func run_tests() -> bool:
	var config: DungeonConfig = load("res://demo/demo_config.tres")
	if not config:
		printerr("Test error: Failed to load res://demo/demo_config.tres")
		return false

	# Ensure we have a reproducible seed
	config.random_seed = 123456

	var generator := DungeonGenerator3D.new()
	generator.config = config
	
	# Add generator to scene tree so _ready works if needed
	root.add_child(generator)

	generator.generate()

	if not generator.active_graph:
		printerr("Test error: Generator failed to produce active_graph")
		return false

	var graph: DungeonGraph = generator.active_graph
	var dungeon_root: Node3D = generator.get_child(0) as Node3D
	if not dungeon_root or dungeon_root.name != "DungeonLayout":
		printerr("Test error: DungeonLayout root node not found or not Node3D")
		return false

	var room_count: int = graph.placements.size()
	if room_count == 0:
		printerr("Test error: Graph placements are empty")
		return false

	var room_nodes: Array[Node] = dungeon_root.get_children()
	if room_nodes.size() != room_count:
		printerr("Test error: Instantiated room count (%d) does not match graph placements (%d)" % [room_nodes.size(), room_count])
		return false

	for i: int in range(room_count):
		var room_node := room_nodes[i] as Node3D
		if not room_node:
			printerr("Test error: Room node %d is not a Node3D" % i)
			return false

		# Scan for RoomConnector3D children
		var connectors: Array[Node] = []
		_find_connectors_recursive(room_node, connectors)

		for connector: RoomConnector3D in connectors:
			var local_transform: Transform3D = _get_relative_transform(connector, room_node)
			var edge: Dictionary = graph.get_edge_for_connector(i, local_transform)

			if edge.is_empty():
				# Connector leads to void -> Must have exactly 1 child, which is a blocker
				if connector.get_child_count() != 1:
					printerr("Verification failure: Connector %s in room %d (%s) leads to void but has %d children (expected 1 Blocker)" % [connector.name, i, room_node.name, connector.get_child_count()])
					return false
				var child := connector.get_child(0) as Node3D
				if not child or child.name != "Blocker":
					printerr("Verification failure: Unused connector %s in room %d should have a child named 'Blocker', found '%s'" % [connector.name, i, child.name if child else "null"])
					return false
				if not child.transform.is_equal_approx(Transform3D.IDENTITY):
					printerr("Verification failure: Blocker transform in room %d is not identity" % i)
					return false
			else:
				# Active connection
				var room_a: int = edge.room_a_index
				var room_b: int = edge.room_b_index
				var lower_index: int = min(room_a, room_b)

				if i == lower_index:
					# Lower room index -> Must have doorway scene child
					# Note: if it's locked, it may have two children: Doorway and the locked door placeholder/mesh
					var doorway_found := false
					for c: Node in connector.get_children():
						if c.name == "Doorway":
							doorway_found = true
							var doorway_node := c as Node3D
							if not doorway_node.transform.is_equal_approx(Transform3D.IDENTITY):
								printerr("Verification failure: Doorway transform in room %d is not identity" % i)
								return false
					if not doorway_found:
						printerr("Verification failure: Active connector %s in lower-index room %d (%s) does not have 'Doorway' child" % [connector.name, i, room_node.name])
						return false
				else:
					# Higher room index -> Must NOT have doorway scene child (remains empty or only has locked door placeholder if locked)
					for c: Node in connector.get_children():
						if c.name == "Doorway":
							printerr("Verification failure: Active connector %s in higher-index room %d (%s) has duplicate 'Doorway' child" % [connector.name, i, room_node.name])
							return false

	print("Verification details:")
	print("  - Rooms generated: %d" % room_count)
	print("  - All unused connectors successfully spawned Blocker walls.")
	print("  - All active connectors successfully spawned Doorways (only on lower-index room, avoiding overlaps).")
	print("  - Blocker and Doorway transforms successfully inherit connector transforms.")

	generator.queue_free()
	return true


func _find_connectors_recursive(node: Node, result: Array[Node]) -> void:
	if node is RoomConnector3D:
		result.append(node)
	for child: Node in node.get_children():
		_find_connectors_recursive(child, result)


func _get_relative_transform(node: Node3D, root: Node) -> Transform3D:
	var t: Transform3D = Transform3D.IDENTITY
	var curr: Node = node
	while curr and curr != root:
		if curr is Node3D:
			t = curr.transform * t
		curr = curr.get_parent()
	return t

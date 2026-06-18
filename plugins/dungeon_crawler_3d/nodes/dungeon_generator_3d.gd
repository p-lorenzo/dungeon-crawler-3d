@tool
class_name DungeonGenerator3D
extends Node3D

signal generation_completed(dungeon_root: Node3D)
signal generation_failed(reason: String)
signal generation_note(note: String)

@export_category("Configuration")
@export var config: DungeonConfig:
	set(value):
		config = value

@export_category("Actions")
@export var _generate_button: bool:
	set(value):
		if value:
			generate()
			_generate_button = false

@export var _clear_button: bool:
	set(value):
		if value:
			clear()
			_clear_button = false

var _dungeon_root: Node3D
var active_graph: DungeonGraph


func generate() -> void:
	if not config:
		generation_failed.emit("No configuration assigned")
		return

	clear()

	if config.entrance_pool.is_empty():
		generation_failed.emit("No entrance room configured")
		return

	if config.boss_pool.is_empty():
		generation_failed.emit("No boss room configured")
		return

	if config.corridor_pool.is_empty() and config.junction_pool.is_empty() and config.main_path_length > 2:
		generation_failed.emit("No corridor or junction rooms configured for main path")
		return

	if config.branch_count > 0:
		if config.dead_end_pool.is_empty():
			generation_failed.emit("No dead-end rooms configured for branches")
			return

		var has_branch_pool: bool = not config.corridor_pool.is_empty() or not config.junction_pool.is_empty()
		if not has_branch_pool:
			generation_failed.emit("No corridor or junction rooms configured for branch paths")
			return

	if not _validate_all_scenes():
		return

	var min_rooms_for_topology: int = config.main_path_length + config.branch_count * config.branch_depth_min
	if min_rooms_for_topology < config.room_count_min:
		generation_note.emit("Topology may fall short of room_count_min (%d); minimum rooms for topology: %d" % [config.room_count_min, min_rooms_for_topology])

	var builder: DungeonBuilder = DungeonBuilder.new()
	var graph: DungeonGraph = builder.build(config)
	active_graph = graph

	if graph.placements.is_empty():
		var reason: String = builder.failure_reason
		if reason.is_empty():
			reason = "Failed to generate dungeon layout"
		generation_failed.emit(reason)
		return

	var validator: PathValidator = PathValidator.new()
	if not validator.validate_path(graph):
		generation_failed.emit(builder.failure_reason)
		return

	_generate_dungeon_root()
	_instantiate_rooms(graph)

	if not builder.partial_success_note.is_empty():
		generation_note.emit(builder.partial_success_note)

	generation_completed.emit(_dungeon_root)


func clear() -> void:
	active_graph = null
	if _dungeon_root:
		if is_instance_valid(_dungeon_root):
			_dungeon_root.queue_free()
		_dungeon_root = null

	for child: Node in get_children():
		if child != _dungeon_root and not _is_persistent_child(child):
			child.queue_free()


func _is_persistent_child(node: Node) -> bool:
	return false


func _generate_dungeon_root() -> void:
	if _dungeon_root and is_instance_valid(_dungeon_root):
		_dungeon_root.queue_free()

	_dungeon_root = Node3D.new()
	_dungeon_root.name = "DungeonLayout"
	add_child(_dungeon_root)

	if Engine.is_editor_hint():
		_dungeon_root.owner = get_tree().edited_scene_root


func _instantiate_rooms(graph: DungeonGraph) -> void:
	for i: int in range(graph.placements.size()):
		var placement: Dictionary = graph.placements[i]
		var room_data: RoomData = placement.room_data
		var world_transform: Transform3D = placement.world_transform
		var category: int = placement.category

		var room_instance: Node3D = room_data.room_scene.instantiate()
		room_instance.transform = world_transform
		room_instance.name = _room_name(room_data, category, _dungeon_root.get_child_count())

		# Hook for locked doors and doorway/blocker templates inside the room
		for child in room_instance.find_children("*", "RoomConnector3D", true, false):
			var connector := child as RoomConnector3D
			if connector:
				_spawn_doorway_or_blocker(connector, i, graph, room_instance)
				if connector.is_locked:
					_spawn_locked_door(connector)

		# Hook for key spawning if assigned to this room placement
		if graph.key_lock_assignments.has(i):
			var assignments: Array = graph.key_lock_assignments[i]
			for assignment: KeyLockAssignment in assignments:
				_spawn_key_item(room_instance, assignment)

		_dungeon_root.add_child(room_instance)

		if Engine.is_editor_hint():
			room_instance.owner = get_tree().edited_scene_root


func _spawn_doorway_or_blocker(connector: RoomConnector3D, room_index: int, graph: DungeonGraph, room_instance: Node3D) -> void:
	var local_transform: Transform3D = _get_relative_transform(connector, room_instance)
	var edge: Dictionary = graph.get_edge_for_connector(room_index, local_transform)

	if edge.is_empty():
		# Connector is unused (leads to void) -> Spawn Blocker
		if connector.blocker_scene:
			var blocker_instance: Node3D = connector.blocker_scene.instantiate() as Node3D
			blocker_instance.transform = Transform3D.IDENTITY
			connector.add_child(blocker_instance)
			if Engine.is_editor_hint():
				blocker_instance.owner = get_tree().edited_scene_root
		else:
			push_warning("DungeonGenerator: Blocker scene is missing/null on connector '%s' in room index %d" % [connector.name, room_index])
	else:
		# Connector is active -> Spawn Doorway (Only on the room with lower index to prevent duplicates)
		var lower_index: int = min(edge.room_a_index, edge.room_b_index)
		if room_index == lower_index:
			if connector.doorway_scene:
				var doorway_instance: Node3D = connector.doorway_scene.instantiate() as Node3D
				doorway_instance.transform = Transform3D.IDENTITY
				connector.add_child(doorway_instance)
				if Engine.is_editor_hint():
					doorway_instance.owner = get_tree().edited_scene_root
			else:
				push_warning("DungeonGenerator: Doorway scene is missing/null on connector '%s' in room index %d" % [connector.name, room_index])


func _get_relative_transform(node: Node3D, root: Node) -> Transform3D:
	var t: Transform3D = Transform3D.IDENTITY
	var curr: Node = node
	while curr and curr != root:
		if curr is Node3D:
			t = curr.transform * t
		curr = curr.get_parent()
	return t


func _spawn_locked_door(connector: RoomConnector3D) -> void:
	var key_id: String = connector.key_id
	var door_scene: PackedScene = null
	if config and config.locked_door_scenes.has(key_id):
		door_scene = config.locked_door_scenes[key_id]

	if door_scene:
		var door_instance: Node3D = door_scene.instantiate()
		connector.add_child(door_instance)
		if Engine.is_editor_hint():
			door_instance.owner = get_tree().edited_scene_root
	else:
		# Fallback: Spawn a visible placeholder (e.g. a red/magenta BoxMesh)
		var mesh_instance := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(1.5, 2.5, 0.2)
		mesh_instance.mesh = box_mesh

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.MAGENTA
		mesh_instance.material_override = mat

		connector.add_child(mesh_instance)
		if Engine.is_editor_hint():
			mesh_instance.owner = get_tree().edited_scene_root


func _spawn_key_item(room_instance: Node3D, assignment: KeyLockAssignment) -> void:
	var spawn_point_node = room_instance.get_node_or_null(assignment.spawn_point_path)
	if not spawn_point_node:
		return

	var key_id: String = assignment.key_id
	var key_scene: PackedScene = null
	if config and config.key_scenes.has(key_id):
		key_scene = config.key_scenes[key_id]

	if key_scene:
		var key_instance: Node3D = key_scene.instantiate()
		spawn_point_node.add_child(key_instance)
		if Engine.is_editor_hint():
			key_instance.owner = get_tree().edited_scene_root
	else:
		# Fallback: Spawn a visible placeholder (e.g. a small magenta sphere)
		var mesh_instance := MeshInstance3D.new()
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = 0.2
		sphere_mesh.height = 0.4
		mesh_instance.mesh = sphere_mesh

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.MAGENTA
		mesh_instance.material_override = mat

		spawn_point_node.add_child(mesh_instance)
		if Engine.is_editor_hint():
			mesh_instance.owner = get_tree().edited_scene_root



func _room_name(room_data: RoomData, category: int, index: int) -> String:
	var category_name: String = ""
	match category:
		RoomData.RoomCategory.ENTRANCE:
			category_name = "Entrance"
		RoomData.RoomCategory.BOSS:
			category_name = "Boss"
		RoomData.RoomCategory.CORRIDOR:
			category_name = "Corridor"
		RoomData.RoomCategory.JUNCTION:
			category_name = "Junction"
		RoomData.RoomCategory.DEAD_END:
			category_name = "DeadEnd"

	return "%s_%d" % [category_name, index]


func _validate_all_scenes() -> bool:
	var pools: Dictionary = {
		"entrance": config.entrance_pool,
		"boss": config.boss_pool,
		"corridor": config.corridor_pool,
		"junction": config.junction_pool,
		"dead_end": config.dead_end_pool
	}

	var matcher: ConnectorMatcher = ConnectorMatcher.new()

	for pool_name: String in pools:
		var pool: Array[RoomData] = pools[pool_name]
		for room_data: RoomData in pool:
			if not room_data:
				continue
			if not room_data.room_scene:
				generation_failed.emit("Missing PackedScene reference in %s pool" % pool_name)
				return false

			var connector_count: int = matcher.get_connectors(room_data.room_scene).size()
			if connector_count == 0:
				print_rich("[color=yellow]DungeonGenerator: Room in %s pool has 0 connectors[/color]" % pool_name)
			if pool_name == "dead_end" and connector_count < 1:
				generation_failed.emit("Dead-end room in pool has no connectors")
				return false

	return true

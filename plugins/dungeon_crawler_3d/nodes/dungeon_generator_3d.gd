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

	var builder: DungeonBuilder = DungeonBuilder.new()
	var graph: DungeonGraph = builder.build(config)

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
	for placement: Dictionary in graph.placements:
		var room_data: RoomData = placement.room_data
		var world_transform: Transform3D = placement.world_transform
		var category: int = placement.category

		var room_instance: Node3D = room_data.room_scene.instantiate()
		room_instance.transform = world_transform
		room_instance.name = _room_name(room_data, category, _dungeon_root.get_child_count())

		_dungeon_root.add_child(room_instance)

		if Engine.is_editor_hint():
			room_instance.owner = get_tree().edited_scene_root


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

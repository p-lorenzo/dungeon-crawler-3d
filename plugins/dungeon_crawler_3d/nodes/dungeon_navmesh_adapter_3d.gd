@tool
class_name DungeonNavMeshAdapter3D
extends Node

@export var navigation_region: NavigationRegion3D
@export var bake_on_completed: bool = true
@export var use_collision_geometry: bool = false
@export_flags_3d_navigation var navigation_layers: int = 1
@export var bake_async: bool = true

var _connected_generator: DungeonGenerator3D = null


func _ready() -> void:
	_update_connection()


func _enter_tree() -> void:
	_update_connection()


func _exit_tree() -> void:
	_disconnect_from_generator()


func _update_connection() -> void:
	_disconnect_from_generator()
	
	# Try to find a DungeonGenerator3D in ancestors
	var node: Node = get_parent()
	var generator: DungeonGenerator3D = null
	while node:
		if node is DungeonGenerator3D:
			generator = node
			break
		node = node.get_parent()
	
	# If not found in ancestors, search the scene tree
	if not generator and is_inside_tree():
		var root_node: Node = null
		if Engine.is_editor_hint():
			if get_tree() and get_tree().edited_scene_root:
				root_node = get_tree().edited_scene_root
		else:
			if get_tree() and get_tree().current_scene:
				root_node = get_tree().current_scene
		
		if root_node:
			generator = _find_generator_recursive(root_node)
	
	if generator:
		_connected_generator = generator
		if not _connected_generator.generation_completed.is_connected(_on_generation_completed):
			_connected_generator.generation_completed.connect(_on_generation_completed)


func _disconnect_from_generator() -> void:
	if _connected_generator and is_instance_valid(_connected_generator):
		if _connected_generator.generation_completed.is_connected(_on_generation_completed):
			_connected_generator.generation_completed.disconnect(_on_generation_completed)
	_connected_generator = null


func _find_generator_recursive(node: Node) -> DungeonGenerator3D:
	if node is DungeonGenerator3D:
		return node
	for child in node.get_children():
		var found := _find_generator_recursive(child)
		if found:
			return found
	return null


func _on_generation_completed(dungeon_root: Node3D) -> void:
	if not bake_on_completed:
		return
	
	var target_region: NavigationRegion3D = navigation_region
	
	# FR-008: Handle missing or unresolved navigation region references
	if not target_region or not is_instance_valid(target_region):
		# Check if we already created a dynamic navigation region under dungeon_root
		for child in dungeon_root.get_children():
			if child is NavigationRegion3D and child.name == "DungeonNavigationRegion3D":
				target_region = child
				break
		
		if not target_region:
			target_region = NavigationRegion3D.new()
			target_region.name = "DungeonNavigationRegion3D"
			dungeon_root.add_child(target_region)
			if Engine.is_editor_hint() and dungeon_root.get_tree():
				target_region.owner = dungeon_root.get_tree().edited_scene_root
	
	# Ensure there is a NavigationMesh resource
	if not target_region.navigation_mesh:
		target_region.navigation_mesh = NavigationMesh.new()
	
	var nav_mesh: NavigationMesh = target_region.navigation_mesh
	
	# FR-004: Update the parsing source to target the generated dungeon's root node
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	
	var group_name: String = "dungeon_bake_group_" + str(dungeon_root.get_instance_id())
	nav_mesh.geometry_source_group_name = group_name
	
	# Add dungeon_root to the group so it and its children are parsed
	if not dungeon_root.is_in_group(group_name):
		dungeon_root.add_to_group(group_name)
	
	# FR-003/004/005: Parse geometry source setting (collision vs mesh)
	if use_collision_geometry:
		nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	else:
		nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	
	# Set the navigation layers on the target region
	target_region.navigation_layers = navigation_layers
	
	# FR-006 & FR-007: Handle async vs sync baking
	var use_async: bool = bake_async
	# Editor-time baking under @tool MUST run synchronously
	if Engine.is_editor_hint():
		use_async = false
	
	# Trigger the bake
	target_region.bake_navigation_mesh(use_async)

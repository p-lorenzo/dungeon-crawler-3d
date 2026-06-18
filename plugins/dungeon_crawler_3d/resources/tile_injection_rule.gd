@tool
class_name TileInjectionRule
extends Resource

enum PlacementTarget {
	MAIN_PATH = 0,
	BRANCH = 1,
	ANYWHERE = 2
}

@export var room_data: RoomData
@export var min_path_percentage: float = 0.0
@export var max_path_percentage: float = 1.0
@export var placement_target: PlacementTarget = PlacementTarget.MAIN_PATH
@export var is_required: bool = false

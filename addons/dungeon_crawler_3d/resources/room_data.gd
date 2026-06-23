@tool
class_name RoomData
extends Resource

enum RoomCategory {
	ENTRANCE = 0,
	BOSS = 1,
	CORRIDOR = 2,
	JUNCTION = 3,
	DEAD_END = 4
}

@export var room_scene: PackedScene
@export var spawn_weight: float = 1.0
@export var category: int = RoomCategory.CORRIDOR

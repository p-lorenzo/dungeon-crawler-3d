@tool
class_name DungeonConfig
extends Resource

@export_category("Topology")
@export var main_path_length: int = 5:
	set(value):
		main_path_length = maxi(value, 1)
@export var branch_count: int = 2:
	set(value):
		branch_count = maxi(value, 0)
@export var branch_depth_min: int = 1:
	set(value):
		branch_depth_min = maxi(value, 0)
@export var branch_depth_max: int = 3:
	set(value):
		branch_depth_max = maxi(value, branch_depth_min)

@export_category("Constraints")
@export var room_count_min: int = 3:
	set(value):
		room_count_min = maxi(value, 1)
@export var room_count_max: int = 50:
	set(value):
		room_count_max = maxi(value, room_count_min)
@export var random_seed: int = 0
@export var max_generation_attempts: int = 10:
	set(value):
		max_generation_attempts = maxi(value, 1)

@export_category("Room Pools")
@export var entrance_pool: Array[RoomData] = []
@export var boss_pool: Array[RoomData] = []
@export var corridor_pool: Array[RoomData] = []
@export var junction_pool: Array[RoomData] = []
@export var dead_end_pool: Array[RoomData] = []

@export_category("Lock & Key")
@export var key_scenes: Dictionary = {} # String (key_id) -> PackedScene
@export var locked_door_scenes: Dictionary = {} # String (key_id) -> PackedScene

@export_category("Props")
@export var global_prop_limits: Dictionary = {} # String (category) -> int (limit)

@export_category("Tile Injection")
@export var injected_tiles: Array[TileInjectionRule] = []




class_name PathValidator
extends RefCounted


func validate_path(graph: DungeonGraph) -> bool:
	if graph.placements.is_empty():
		return false

	var entrance_idx: int = 0
	var boss_idx: int = _find_boss_index(graph)
	if boss_idx < 0:
		return false

	var path: Array = graph.get_path(entrance_idx, boss_idx)
	return not path.is_empty()


func _find_boss_index(graph: DungeonGraph) -> int:
	for i: int in range(graph.placements.size() - 1, -1, -1):
		var placement: Dictionary = graph.placements[i]
		var category: int = placement.get("category", -1)
		if category == RoomData.RoomCategory.BOSS:
			return i
	return -1

class_name DungeonGraph
extends RefCounted

var placements: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var main_path: Array[int] = []
var branches: Array[Array] = []
var total_rooms: int = 0
var key_lock_assignments: Dictionary = {}


func add_placement(placement: Dictionary) -> int:
	var index: int = placements.size()
	placements.append(placement)
	total_rooms = placements.size()
	return index


func add_edge(edge: Dictionary) -> void:
	edges.append(edge)


func remove_last_placement() -> Dictionary:
	if placements.is_empty():
		return {}
	var removed: Dictionary = placements.pop_back()
	total_rooms = placements.size()
	return removed


func remove_last_edge() -> Dictionary:
	if edges.is_empty():
		return {}
	var removed: Dictionary = edges.pop_back()
	return removed


func get_path(from_index: int, to_index: int) -> Array[int]:
	var visited: Array[int] = []
	var queue: Array[int] = [from_index]
	var came_from: Dictionary = {from_index: -1}

	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == to_index:
			return _reconstruct_path(came_from, from_index, to_index)

		visited.append(current)
		for edge: Dictionary in edges:
			var neighbor: int = -1
			if edge.room_a_index == current:
				neighbor = edge.room_b_index
			elif edge.room_b_index == current:
				neighbor = edge.room_a_index

			if neighbor >= 0 and neighbor not in visited and neighbor not in queue:
				queue.append(neighbor)
				came_from[neighbor] = current

	return []


func _reconstruct_path(came_from: Dictionary, from_idx: int, to_idx: int) -> Array[int]:
	var path: Array[int] = [to_idx]
	var current: int = to_idx
	while current != from_idx:
		current = came_from.get(current, -1)
		if current < 0:
			return []
		path.push_front(current)
	return path


func clear() -> void:
	placements.clear()
	edges.clear()
	main_path.clear()
	branches.clear()
	total_rooms = 0
	key_lock_assignments.clear()

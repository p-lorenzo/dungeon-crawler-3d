class_name RoomSelector
extends RefCounted

const COOLDOWN_FACTOR: float = 0.5
const RECENT_QUEUE_SIZE: int = 3
const MIN_ADJUSTED_WEIGHT: float = 0.01

var _recent_queue: Array[RoomData] = []


func select_weighted(pool: Array[RoomData], rng: RandomNumberGenerator) -> RoomData:
	var valid: Array[Dictionary] = _build_valid_candidates(pool)
	if valid.is_empty():
		return null

	var total_weight: float = 0.0
	for entry: Dictionary in valid:
		total_weight += entry.adjusted_weight

	if total_weight <= 0.0:
		return null

	var random_value: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for entry: Dictionary in valid:
		cumulative += entry.adjusted_weight
		if random_value <= cumulative:
			var selected: RoomData = entry.room_data
			_add_to_recent(selected)
			return selected

	return valid[valid.size() - 1].room_data


func select_weighted_index(pool: Array[RoomData], rng: RandomNumberGenerator) -> int:
	var valid: Array[Dictionary] = _build_valid_candidates(pool)
	if valid.is_empty():
		return -1

	var total_weight: float = 0.0
	for entry: Dictionary in valid:
		total_weight += entry.adjusted_weight

	if total_weight <= 0.0:
		return -1

	var random_value: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for entry: Dictionary in valid:
		cumulative += entry.adjusted_weight
		if random_value <= cumulative:
			var selected: RoomData = entry.room_data
			_add_to_recent(selected)
			return entry.index

	return valid[valid.size() - 1].index


func _build_valid_candidates(pool: Array[RoomData]) -> Array[Dictionary]:
	var valid: Array[Dictionary] = []
	for i: int in range(pool.size()):
		var room: RoomData = pool[i]
		if not room or not room.room_scene:
			continue
		if room.spawn_weight <= 0.0:
			continue

		var adjusted_weight: float = room.spawn_weight
		if _recent_queue.has(room):
			adjusted_weight = room.spawn_weight * (1.0 - COOLDOWN_FACTOR)
			if adjusted_weight < MIN_ADJUSTED_WEIGHT:
				adjusted_weight = MIN_ADJUSTED_WEIGHT

		valid.append({
			room_data = room,
			index = i,
			adjusted_weight = adjusted_weight
		})

	return valid


func _add_to_recent(room_data: RoomData) -> void:
	_recent_queue.push_back(room_data)
	while _recent_queue.size() > RECENT_QUEUE_SIZE:
		_recent_queue.pop_front()


func reset() -> void:
	_recent_queue.clear()

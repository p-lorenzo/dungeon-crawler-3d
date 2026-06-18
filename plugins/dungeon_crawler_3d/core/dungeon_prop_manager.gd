class_name DungeonPropManager
extends RefCounted

var config: DungeonConfig
var rng: RandomNumberGenerator
var spawned_counts: Dictionary = {} # String (category) -> int


func _init(p_config: DungeonConfig, p_rng: RandomNumberGenerator) -> void:
	config = p_config
	rng = p_rng
	spawned_counts.clear()


## Evaluates a PropGroup3D to determine if a prop should spawn and which one.
## If eligible, increments the category spawn count and returns the selected scene.
## Otherwise, returns null.
func evaluate_prop_group(prop_group: PropGroup3D) -> PackedScene:
	if not prop_group:
		return null
	
	if prop_group.prop_pool.is_empty():
		return null

	var category: String = prop_group.prop_category

	# Check global limit first if category is configured
	if not category.is_empty() and config and config.global_prop_limits.has(category):
		var limit: int = config.global_prop_limits[category]
		var current_count: int = spawned_counts.get(category, 0)
		if current_count >= limit:
			return null

	# Spawn chance check
	if prop_group.spawn_chance <= 0.0:
		return null
	if prop_group.spawn_chance < 1.0:
		if rng.randf() > prop_group.spawn_chance:
			return null

	# Select scene
	var selected_scene: PackedScene = _select_weighted(prop_group)
	if not selected_scene:
		return null

	# If we spawned it, update counts
	if not category.is_empty():
		spawned_counts[category] = spawned_counts.get(category, 0) + 1

	return selected_scene


func _select_weighted(prop_group: PropGroup3D) -> PackedScene:
	var pool: Array[PackedScene] = prop_group.prop_pool
	var weights: Array[float] = prop_group.weights

	if pool.is_empty():
		return null

	var use_uniform := false
	if weights.size() != pool.size():
		use_uniform = true
		push_warning("PropGroup3D weight mismatch: pool size is %d, weights size is %d. Falling back to uniform distribution." % [pool.size(), weights.size()])

	if use_uniform:
		var idx: int = rng.randi() % pool.size()
		return pool[idx]

	var total_weight: float = 0.0
	for w: float in weights:
		total_weight += w

	if total_weight <= 0.0:
		# If all weights are 0, fallback to uniform
		var idx: int = rng.randi() % pool.size()
		return pool[idx]

	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for i: int in range(pool.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return pool[i]

	return pool[pool.size() - 1]

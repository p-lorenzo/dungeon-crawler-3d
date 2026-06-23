extends SceneTree

func _init() -> void:
	print("--- STARTING PLAYER CONTROLLER STRUCTURE TESTS ---")
	
	var player_scene_path := "res://demo/player/player.tscn"
	if not FileAccess.file_exists(player_scene_path):
		printerr("ERROR: player.tscn does not exist at ", player_scene_path)
		quit(1)
		return

	var scene := load(player_scene_path) as PackedScene
	if not scene:
		printerr("ERROR: Failed to load player.tscn")
		quit(1)
		return

	var instance := scene.instantiate()
	if not instance:
		printerr("ERROR: Failed to instantiate player.tscn")
		quit(1)
		return

	if not instance is CharacterBody3D:
		printerr("ERROR: Player root node is not CharacterBody3D. Got: ", instance.get_class())
		instance.queue_free()
		quit(1)
		return

	var has_col := false
	for child in instance.get_children():
		if child is CollisionShape3D:
			has_col = true
			break
	if not has_col:
		printerr("ERROR: player.tscn does not have a CollisionShape3D child node")
		instance.queue_free()
		quit(1)
		return

	var head := instance.get_node_or_null("Head")
	if not head:
		printerr("ERROR: player.tscn is missing 'Head' child node")
		instance.queue_free()
		quit(1)
		return
	
	var camera := head.get_node_or_null("Camera3D")
	if not camera or not camera is Camera3D:
		printerr("ERROR: player.tscn is missing 'Camera3D' child node under Head")
		instance.queue_free()
		quit(1)
		return

	instance.queue_free()
	print("--- PLAYER CONTROLLER STRUCTURE TESTS PASSED ---")
	quit(0)

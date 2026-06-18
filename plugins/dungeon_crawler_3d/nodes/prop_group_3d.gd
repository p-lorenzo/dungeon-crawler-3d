@tool
class_name PropGroup3D
extends Node3D

@export var prop_category: String = ""
@export_range(0.0, 1.0) var spawn_chance: float = 1.0
@export var prop_pool: Array[PackedScene] = []
@export var weights: Array[float] = []

extends Node3D

var current_level: int = 1
var last_level: int = 1

# Preload all your level scenes
var level_scenes := {
	1: preload("res://game/levels/level1.tscn")
	#2: preload("res://game/levels/level2.tscn")
}

func _ready() -> void:
	if OS.has_feature("web"):
		get_node("../DirectionalLight3D").light_energy = 0.8
	_load_level(current_level)

func _on_finished_level_next_level() -> void:
	current_level += 1
	get_child(0).queue_free()
	if current_level <= last_level:
		_load_level(current_level)
	else:
		print("All levels complete!")


func _load_level(level: int) -> void:
	$"../Ui".counting = true
	$"../ball".reset_bunny()
	if level_scenes.has(level):
		var level_instance = level_scenes[level].instantiate()
		add_child(level_instance)
	else:
		print("Error: Level %d not found in level_scenes!" % level)

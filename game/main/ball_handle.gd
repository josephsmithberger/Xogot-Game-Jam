extends Node3D

signal new_level

func _next_level(level: int) -> void:
	new_level.emit()



func _on_finished_level_next_level() -> void:
	get_child(0).queue_free()

	var ball_scene := preload("res://game/main/ball.tscn")
	var ball_instance := ball_scene.instantiate()
	add_child(ball_instance)
	print("did")

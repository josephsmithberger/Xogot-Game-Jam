extends Node3D

signal new_level

func _next_level(level: int) -> void:
	new_level.emit()

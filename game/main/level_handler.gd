extends Node3D




func _on_ball_next_level(level: int) -> void:
	print("Congrats! Onto level " + str(level) + "!")
	get_child(0).process_mode = Node.PROCESS_MODE_DISABLED

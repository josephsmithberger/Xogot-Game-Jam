extends Node
@onready var timer : Timer = $Timer
@onready var label :Label = $Control/CenterContainer/Label
@onready var finished_screen

func _process(delta: float) -> void:
	label.text = "Time" + str(timer.time_left)
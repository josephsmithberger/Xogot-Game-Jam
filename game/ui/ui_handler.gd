extends Node

var elapsed_time: float = 0.0
@onready var label: Label = $Control/CenterContainer/Label
@onready var finished_screen: Control = $finished_level
var counting:bool = true

func _ready() -> void:
	elapsed_time = 0.0
	finished_screen.visible = false

func _process(delta: float) -> void:
	if counting:
		elapsed_time += delta
		label.text = "Time: %.2f" % elapsed_time

func _on_ball_next_level(level: int) -> void:
	counting = false
	finished_screen.finished_level("%.2f" % elapsed_time)
	finished_screen.visible = true
	elapsed_time = 0.0

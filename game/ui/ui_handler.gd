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





func _on_finished_level_next_level() -> void:
	elapsed_time = 0.0


func _on_node_3d_new_level() -> void:
	counting = false
	finished_screen.finished_level("%.2f" % elapsed_time)
	finished_screen.visible = true

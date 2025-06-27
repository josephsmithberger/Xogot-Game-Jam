extends Control
@onready var label : Label = $CenterContainer/VBoxContainer/Label
var initial_text : String
signal play_anim

func _ready() -> void:
	initial_text = label.text
	hide()

func finished_level(time:String):
	label.text = initial_text + time + " seconds!"

func _on_button_pressed() -> void:
	anim()

func anim():
	hide()
	modulate.a = 1.0
	play_anim.emit()


func _on_ball_next_level(level: int) -> void:
	show()

extends Control
@onready var label : Label = $CenterContainer/VBoxContainer/Label
var initial_text : String
signal next_level

func _ready() -> void:
	initial_text = label.text
	hide()

func finished_level(timer_score:String):
	print(timer_score)
	label.text = initial_text + timer_score + " seconds!"

func _on_button_pressed() -> void:
	anim()

func anim():
	hide()
	next_level.emit()


func _on_ball_next_level(level: int) -> void:
	show()

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and Input.is_action_just_pressed("debug"):
		anim()

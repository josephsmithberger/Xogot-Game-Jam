extends Control
@onready var label : Label = $CenterContainer/VBoxContainer/Label
var initial_text : String
signal next_level
var current_level:float = 1
var leaderboard : String
func _ready() -> void:
	initial_text = label.text
	hide()

func finished_level(timer_score:String):
	print(timer_score)
	label.text = initial_text + timer_score + " seconds!"
	leaderboard = "level"+str(current_level)

func _on_button_pressed() -> void:
	anim()
	current_level += 1

func anim():
	hide()
	next_level.emit()




func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and Input.is_action_just_pressed("debug"):
		anim()


func _on_node_3d_new_level() -> void:
	show()

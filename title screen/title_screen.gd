extends Control

@onready var btn = $CenterContainer/Button
@onready var spinner = $CenterContainer/LoadingSpinner
var thread: Thread

func _ready() -> void:
	spinner.visible = false
	btn.visible = true

func _on_button_pressed() -> void:
	btn.disabled = true
	btn.visible = false
	spinner.visible = true
	
	# Create thread and start it with a Callable
	thread = Thread.new()
	thread.start(_thread_load_scene)

func _thread_load_scene() -> void:
	# This runs on a separate thread
	var scene_path = "res://game/main/game_scene.tscn"
	var packed_scene = ResourceLoader.load(scene_path)
	
	# You can't directly call methods from another thread
	# Use call_deferred to execute on the main thread
	call_deferred("_on_scene_loaded", packed_scene)

func _on_scene_loaded(packed_scene: PackedScene) -> void:
	# Always wait for threads to finish
	thread.wait_to_finish()
	
	spinner.visible = false
	get_tree().change_scene_to_packed(packed_scene)

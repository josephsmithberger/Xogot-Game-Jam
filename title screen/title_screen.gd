extends Control

@onready var btn = $CenterContainer/VBoxContainer/Start
@onready var spinner = $CenterContainer/LoadingSpinner
var scene_path = "res://game/intro/intro.tscn"
var loading_done = false
var loading_started = false

func _ready() -> void:
	spinner.visible = false
	btn.visible = true
	if OS.has_feature("web"):
		$"CenterContainer/VBoxContainer/Request Motion".show()
	else:
		$"CenterContainer/VBoxContainer/Request Motion".hide()

func _on_button_pressed() -> void:
	btn.disabled = true
	btn.visible = false
	spinner.visible = true
	
	# Start the loading process
	loading_started = true
	ResourceLoader.load_threaded_request(scene_path)
	set_process(true)

func _process(delta: float) -> void:
	if not loading_started:
		return
		
	# Check the load status
	var status = ResourceLoader.load_threaded_get_status(scene_path)
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			# Loading is complete, switch to the new scene
			var packed_scene = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(packed_scene)
			loading_done = true
			set_process(false)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Still loading, continue waiting
			pass
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			# Invalid resource
			print("Error: Invalid resource path")
			_reset_ui()
			set_process(false)
		ResourceLoader.THREAD_LOAD_FAILED:
			# Loading failed
			print("Error: Failed to load resource")
			_reset_ui()
			set_process(false)

func _reset_ui() -> void:
	spinner.visible = false
	btn.visible = true
	btn.disabled = false
	loading_started = false


func _on_request_motion_pressed() -> void:
	WebInputHelper.request_sensors()

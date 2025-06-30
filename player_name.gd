extends Control

var main_game_scene: String = "res://game/main/game_scene.tscn"
var is_loading = false

func _ready() -> void:
	begin_loading()

func begin_loading():
	# Hide editable elements when loading and show loading screen
	$CenterContainer/VBoxContainer.hide()
	$CenterContainer/Label.show()
	
	# Start background loading
	ResourceLoader.load_threaded_request(main_game_scene)
	is_loading = true
	set_process(true)

func _process(delta):
	if not is_loading:
		return
		
	var status = ResourceLoader.load_threaded_get_status(main_game_scene)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		# Loading complete
		var scene = ResourceLoader.load_threaded_get(main_game_scene)
		get_tree().change_scene_to_packed(scene)
		is_loading = false
		set_process(false)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		# Loading error
		push_error("Scene loading failed")
		is_loading = false
		set_process(false)

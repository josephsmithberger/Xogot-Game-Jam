extends Button

func _ready() -> void:
	if OS.has_feature("web"):
		show()
	else:
		hide()

func _on_pressed() -> void:
	WebInputHelper.request_sensors()
	$"../../../Level".calibrate_motion_controls()

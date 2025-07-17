extends Button

func _ready() -> void:
	if OS.has_feature("web"):
		show()
	else:
		hide()

func _on_pressed() -> void:
	if OS.has_feature("web"):
		WebInputHelper.permission_callbacks.append(_calibrate_callback.unbind(1))
		WebInputHelper.request_permission()
		WebInputHelper.setup()
	# Calibrate immediately for native or after permission
	$"../../../Level".calibrate_motion_controls()

func _calibrate_callback() -> void:
	var timer := Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.start(0.1)
	await timer.timeout
	$"../../../Level".calibrate_motion_controls()

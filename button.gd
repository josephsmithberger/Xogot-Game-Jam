extends Button


func _on_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("requestMotionPermission()")

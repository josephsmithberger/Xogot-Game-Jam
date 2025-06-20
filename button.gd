extends Button


func _on_pressed() -> void:
	# On some browsers (like Safari on iOS 13+), we need to explicitly
	# request permission from the user to access motion data.
	# This must be triggered by a user action, like a button press.
	if OS.has_feature("web"):
		JavaScriptBridge.eval("requestMotionPermission()")

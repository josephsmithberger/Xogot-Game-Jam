extends MeshInstance3D

var latest_beta: float = 0.0
var latest_gamma: float = 0.0
var latest_alpha: float = 0.0

# This function will be called from JavaScript with gyroscope data.
func update_rotation_from_js(beta: float, gamma: float, alpha: float) -> void:
	# Store the latest values received from JavaScript.
	latest_beta = beta
	latest_gamma = gamma
	latest_alpha = alpha

# Called when the node enters the scene tree.
func _ready() -> void:
	# Check if the game is running in a web browser.
	if OS.has_feature("web"):
		# Create a Callable that points to our update_rotation_from_js function.
		var callable = Callable(self, "update_rotation_from_js")
		# Create a JavaScript callback object from our Godot Callable.
		var js_callback = JavaScriptBridge.create_callback(callable)
		# Call the 'initializeGyroListener' function in the HTML shell,
		# passing our JavaScript callback object as an argument.
		JavaScriptBridge.eval("initializeGyroListener(%s)" % js_callback)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# The values from the browser are in degrees. Godot uses radians for rotation.
	# DeviceOrientationEvent axes:
	# beta: rotation around x-axis
	# gamma: rotation around y-axis
	# alpha: rotation around z-axis
	# Note: You may need to swap or negate axes for your desired orientation.
	rotation.x = deg_to_rad(latest_beta)
	rotation.y = deg_to_rad(latest_gamma)
	rotation.z = deg_to_rad(latest_alpha)

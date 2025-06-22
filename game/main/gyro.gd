extends Node3D

var initial_gravity = Vector3()
var initial_basis = Basis()
var initialized = false

func _ready():
	await get_tree().create_timer(0.5).timeout
	
	# Get initial gravity based on platform
	if OS.has_feature("web"):
		initial_gravity = WebInputHelper.get_gravity()
	else:
		initial_gravity = Input.get_gravity()
		
	initial_basis = self.basis
	initialized = true

func _process(delta):
	if not initialized:
		return
	
	_handle_controls(delta)
	
	var current_gravity = Vector3()
	if OS.has_feature("web"):
		current_gravity = WebInputHelper.get_gravity()
	else:
		current_gravity = Input.get_gravity()
	
	# Ensure gravity vectors are not zero before proceeding
	if initial_gravity.length() == 0 or current_gravity.length() == 0:
		return  # Skip this frame if gravity is invalid
	
	var from = Quaternion(Vector3.UP, -initial_gravity.normalized())
	var to = Quaternion(Vector3.UP, -current_gravity.normalized())
	
	var rotation = from.inverse() * to
	self.basis = initial_basis * Basis(rotation)


func _handle_controls(delta):
	# This function will be implemented later
	# It will handle keyboard input for rotation control
	pass

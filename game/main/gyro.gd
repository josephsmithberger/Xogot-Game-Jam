# This script controls a Node3D based on device motion or keyboard input.
# It's designed for a physics puzzle game where you tilt the world.
extends Node3D

# Use @export to create editable properties in the Godot Inspector.
@export_group("Sensitivity")
@export var motion_sensitivity: float = 1.5
@export var keyboard_sensitivity: float = 2.0

# We'll store the initial state when the game starts.
var initial_gravity := Vector3.ZERO
var initial_basis := Basis()
var initialized := false

# --- Godot Lifecycle Functions ---

func _ready():
	# Wait a brief moment for sensor data to stabilize, especially on web.
	await get_tree().create_timer(0.2).timeout
	
	# Get the initial gravity vector to use as a "zero point" or calibration.
	initial_gravity = _get_current_gravity()
	
	# If we successfully get a gravity vector, we can initialize.
	if initial_gravity.length() > 0:
		# Store the starting orientation of the board from the editor.
		initial_basis = self.basis
		initialized = true
	else:
		# If gravity isn't available (e.g., on a desktop without sensors),
		# we log a warning and can rely on keyboard input alone.
		push_warning("Motion controls could not be initialized: Gravity vector not found.")

func _process(delta):
	# Calculate the rotation from motion controls.
	var motion_rotation = _get_motion_rotation()
	
	# Calculate rotation from keyboard input.
	var keyboard_rotation = _get_keyboard_rotation(delta)

	# Combine the rotations. We start with the board's initial orientation,
	# apply the tilt from the device's motion, and then add any
	# keyboard rotation on top of that.
	# The .inverse() fixes the "inverted controls" problem.
	self.basis = initial_basis * Basis(motion_rotation.inverse() * keyboard_rotation)


# --- Helper Functions ---

func _get_current_gravity() -> Vector3:
	"""Fetches the gravity vector based on the platform (web or native)."""
	if OS.has_feature("web"):
		# Assumes you have a WebInputHelper autoload script.
		return WebInputHelper.get_gravity()
	else:
		return Input.get_gravity()

func _get_motion_rotation() -> Quaternion:
	"""
	Calculates the rotational difference from the initial calibrated gravity
	to the current gravity.
	"""
	if not initialized:
		return Quaternion.IDENTITY

	var current_gravity = _get_current_gravity()

	# If the gravity vector is zero, we can't calculate a rotation.
	if current_gravity.length() == 0:
		return Quaternion.IDENTITY

	# --- Robust Rotation Calculation ---
	# To find the rotation between the starting 'down' and the current 'down',
	# we find the axis and angle between the two vectors. This is more
	# reliable than the previous implementation.
	var vec_from = initial_gravity.normalized()
	var vec_to = current_gravity.normalized()
	
	var rotation_axis = vec_from.cross(vec_to)
	var rotation_angle = vec_from.angle_to(vec_to)
	
	# Handle the edge case where the vectors are nearly parallel.
	if rotation_axis.length_squared() < 0.0001:
		return Quaternion.IDENTITY # No rotation needed.

	# Apply sensitivity to the motion.
	rotation_angle *= motion_sensitivity
	
	return Quaternion(rotation_axis.normalized(), rotation_angle)

func _get_keyboard_rotation(delta: float) -> Quaternion:
	"""Calculates rotation based on keyboard input for the current frame."""
	var angular_velocity := Vector3.ZERO

	# Define input based on desired rotation axis.
	# For a tilting board, you typically pitch on X and roll on Z.
	# Assumes you have these actions set up in Project > Input Map.
	var input_right = Input.get_action_strength("rotate_right") - Input.get_action_strength("rotate_left")
	var input_down = Input.get_action_strength("rotate_down") - Input.get_action_strength("rotate_up")
	
	# Roll around the Z axis
	angular_velocity.z = input_right
	# Pitch around the X axis
	angular_velocity.x = input_down
	
	if angular_velocity.length() == 0:
		return Quaternion.IDENTITY

	# Apply sensitivity and frame-rate independence (delta).
	var rotation_angle = angular_velocity.length() * keyboard_sensitivity * delta
	var rotation_axis = angular_velocity.normalized()

	return Quaternion(rotation_axis, rotation_angle)

# This script controls a Node3D based on device motion (accelerometer) or keyboard input.
# v3: Refactored to use the accelerometer exclusively for motion controls, ensuring
#     consistency between native and web platforms.
extends Node3D

# --- Sensitivity and Control Parameters ---

@export_group("Motion Controls")
@export var motion_sensitivity: float = 1.5

@export_group("Keyboard Controls")
@export_range(1, 15) var keyboard_tilt_speed: float = 6.0
@export_range(5, 45) var keyboard_max_tilt_angle: float = 20.0

# --- State Variables ---

# Stores the initial accelerometer state for motion control calibration.
# When the device is held still, the accelerometer measures the force of gravity,
# giving us a reliable "up" vector.
var initial_acceleration := Vector3.ZERO
var initial_basis := Basis()
var initialized := false

# Stores the current keyboard tilt state for smooth interpolation.
var current_keyboard_tilt := Vector2.ZERO

# --- Godot Lifecycle Functions ---

func _ready():
	# Wait a brief moment for sensor data to stabilize before calibrating.
	await get_tree().create_timer(0.2).timeout
	
	initial_acceleration = _get_current_acceleration()
	if initial_acceleration.length() > 0:
		initial_basis = self.basis
		initialized = true
	else:
		push_warning("Motion controls could not be initialized: Accelerometer data not found.")

func _process(delta: float):
	# Calculate the rotation from motion controls (accelerometer).
	var motion_rotation = _get_motion_rotation()
	
	# Update and get the smoothed rotation from keyboard input.
	var keyboard_rotation = _update_and_get_keyboard_rotation(delta)

	# Combine the rotations. The final orientation starts from the initial basis,
	# is adjusted by the device's motion, and then has keyboard tilt applied.
	# The .inverse() on the motion rotation creates a "window" effect, where tilting
	# the device right makes the view look right. Without it, controls would be inverted.
	self.basis = initial_basis * Basis(motion_rotation.inverse() * keyboard_rotation)


# --- Helper Functions ---

func _get_current_acceleration() -> Vector3:
	"""
	Fetches the accelerometer vector based on the platform. This provides a
	consistent source of data for tilt, unlike the gravity sensor which isn't
	always available, especially on the web.
	"""
	if OS.has_feature("web"):
		# The WebInputHelper autoload is expected to be configured for web builds.
		return WebInputHelper.get_accelerometer()
	else:
		return Input.get_accelerometer()

func _get_motion_rotation() -> Quaternion:
	"""
	Calculates the rotational difference from the initial calibrated
	acceleration vector to the current one.
	"""
	if not initialized:
		return Quaternion.IDENTITY

	var current_acceleration = _get_current_acceleration()
	if current_acceleration.length() == 0:
		return Quaternion.IDENTITY

	# We find the rotation that transforms the initial "up" vector (from calibration)
	# to the current "up" vector.
	var vec_from = initial_acceleration.normalized()
	var vec_to = current_acceleration.normalized()
	
	# To find the rotation, we need an axis and an angle.
	var rotation_axis = vec_from.cross(vec_to)
	var rotation_angle = vec_from.angle_to(vec_to)
	
	# If the axis is zero (vectors are parallel), there's no rotation.
	if rotation_axis.length_squared() < 0.0001:
		return Quaternion.IDENTITY

	# Apply sensitivity to the rotation amount.
	rotation_angle *= motion_sensitivity
	
	# Create and return the final quaternion for this frame's motion.
	return Quaternion(rotation_axis.normalized(), rotation_angle)

func _update_and_get_keyboard_rotation(delta: float) -> Quaternion:
	"""
	Calculates a smoothed keyboard rotation by interpolating towards a
	target tilt. This creates a feeling of acceleration and inertia.
	"""
	# 1. Determine the Target Tilt based on player input.
	var target_tilt := Vector2.ZERO
	target_tilt.x = Input.get_action_strength("rotate_down") - Input.get_action_strength("rotate_up")
	target_tilt.y = Input.get_action_strength("rotate_right") - Input.get_action_strength("rotate_left")
	
	# 2. Smoothly Interpolate the Current Tilt towards the Target.
	current_keyboard_tilt = lerp(current_keyboard_tilt, target_tilt, delta * keyboard_tilt_speed)

	# 3. Convert the Smoothed Tilt into a Rotation Quaternion.
	var max_angle_rad = deg_to_rad(keyboard_max_tilt_angle)
	
	# Calculate pitch (up/down rotation around the local X-axis)
	var pitch_angle = current_keyboard_tilt.x * max_angle_rad
	var pitch_rot = Quaternion(Vector3.RIGHT, pitch_angle)
	
	# Calculate roll (left/right rotation around the local Z-axis)
	var roll_angle = current_keyboard_tilt.y * max_angle_rad
	var roll_rot = Quaternion(Vector3.FORWARD, roll_angle)
	
	# Combine pitch and roll. The order (roll * pitch) feels natural for this kind of control.
	return roll_rot * pitch_rot

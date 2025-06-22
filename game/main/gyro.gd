# This script controls a Node3D based on device motion or keyboard input.
# Refactored to use accelerometer data consistently across platforms.
extends Node3D

# --- Sensitivity and Control Parameters ---

@export_group("Motion Controls")
@export var motion_sensitivity: float = 1.5
@export var smoothing_factor: float = 0.2  # Lower = smoother but more delay

@export_group("Keyboard Controls")
@export_range(1, 15) var keyboard_tilt_speed: float = 6.0
@export_range(5, 45) var keyboard_max_tilt_angle: float = 20.0

# --- State Variables ---

# Stores the initial state for motion control calibration
var initial_accel := Vector3.ZERO
var initial_basis := Basis()
var initialized := false

# For smoothing accelerometer data
var smoothed_accel := Vector3.ZERO

# Stores the current keyboard tilt state for smooth interpolation
var current_keyboard_tilt := Vector2.ZERO

# --- Godot Lifecycle Functions ---

func _ready():
	# Wait a brief moment for sensor data to stabilize
	await get_tree().create_timer(0.2).timeout
	
	initial_accel = _get_current_accel()
	if initial_accel.length() > 0:
		initial_basis = self.basis
		smoothed_accel = initial_accel
		initialized = true
	else:
		push_warning("Motion controls could not be initialized: Accelerometer data not found.")

func _process(delta: float):
	# Calculate the rotation from motion controls
	var motion_rotation = _get_motion_rotation(delta)
	
	# Update and get the smoothed rotation from keyboard input
	var keyboard_rotation = _update_and_get_keyboard_rotation(delta)

	# Combine the rotations
	self.basis = initial_basis * Basis(motion_rotation.inverse() * keyboard_rotation)

# --- Helper Functions ---

func _get_current_accel() -> Vector3:
	"""Fetches the accelerometer vector based on the platform."""
	if OS.has_feature("web"):
		return WebInputHelper.get_accelerometer()
	else:
		return Input.get_accelerometer()

func _get_motion_rotation(delta: float) -> Quaternion:
	"""
	Calculates the rotational difference from the initial calibrated accelerometer
	to the current accelerometer reading with smoothing.
	"""
	if not initialized:
		return Quaternion.IDENTITY

	var current_accel = _get_current_accel()
	if current_accel.length() == 0:
		return Quaternion.IDENTITY
	
	# Apply smoothing to reduce jitter
	smoothed_accel = smoothed_accel.lerp(current_accel, smoothing_factor)
	
	var vec_from = initial_accel.normalized()
	var vec_to = smoothed_accel.normalized()
	
	var rotation_axis = vec_from.cross(vec_to)
	var rotation_angle = vec_from.angle_to(vec_to)
	
	if rotation_axis.length_squared() < 0.0001:
		return Quaternion.IDENTITY

	rotation_angle *= motion_sensitivity
	return Quaternion(rotation_axis.normalized(), rotation_angle)

func _update_and_get_keyboard_rotation(delta: float) -> Quaternion:
	"""
	Calculates a smoothed keyboard rotation by interpolating towards a
	target tilt. This creates a feeling of acceleration and inertia.
	"""
	# 1. Determine the Target Tilt based on player input
	var target_tilt := Vector2.ZERO
	target_tilt.x = Input.get_action_strength("rotate_down") - Input.get_action_strength("rotate_up")
	target_tilt.y = Input.get_action_strength("rotate_right") - Input.get_action_strength("rotate_left")
	
	# 2. Smoothly Interpolate the Current Tilt towards the Target
	current_keyboard_tilt = lerp(current_keyboard_tilt, target_tilt, delta * keyboard_tilt_speed)

	# 3. Convert the Smoothed Tilt into a Rotation Quaternion
	var max_angle_rad = deg_to_rad(keyboard_max_tilt_angle)
	
	# Calculate the pitch (up/down rotation around X-axis)
	var pitch_angle = current_keyboard_tilt.x * max_angle_rad
	var pitch_rot = Quaternion(Vector3.RIGHT, pitch_angle)
	
	# Calculate the roll (left/right rotation around Z-axis)
	var roll_angle = current_keyboard_tilt.y * max_angle_rad
	var roll_rot = Quaternion(Vector3.FORWARD, roll_angle)
	
	# Combine the pitch and roll rotations
	return roll_rot * pitch_rot

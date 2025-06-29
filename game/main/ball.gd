extends RigidBody3D

@export var wall_threshold: float = 0.3 # Adjust to allow for steeper slopes
@export var impact_speed_threshold: float = 2.0 # Minimum speed to trigger sound
@onready var origin: Vector3             = position
@onready var audio: AudioStreamPlayer3D  = $AudioStreamPlayer3D
var current_level: int                    = 1

signal next_level(level: int)

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 6
	next_level.connect(get_parent()._next_level)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var contact_count = state.get_contact_count()
	if contact_count == 0:
		return
	var speed = state.get_linear_velocity().length()
	if speed < impact_speed_threshold:
		return
	for i in range(contact_count):
		var normal: Vector3 = state.get_contact_local_normal(i)
		if abs(normal.y) < wall_threshold:
			if not audio.playing:
				audio.play()
			break

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.name == "bounds":
		linear_velocity = Vector3.ZERO
		reset_bunny()

func _on_area_3d_area_entered(area: Area3D) -> void:
	match area.name:
		"goal":
			current_level += 1
			area.monitoring = false
			next_level.emit(current_level)
			reset_bunny()
		"death":
			reset_bunny()

func reset_bunny() -> void:
	linear_velocity = Vector3.ZERO
	position = origin

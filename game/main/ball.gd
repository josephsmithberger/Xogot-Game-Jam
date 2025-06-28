extends RigidBody3D
@onready var orgin : Vector3 = position
var current_level:int = 1
signal next_level(level: int)

func _ready() -> void:
	next_level.connect(get_parent()._next_level)

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.name == "bounds":
		linear_velocity = Vector3.ZERO
		reset_bunny()


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.name == "goal":
		current_level += 1
		area.monitoring = false
		next_level.emit(current_level)
		reset_bunny()
	elif area.name == "death":
		reset_bunny()


func reset_bunny():
	linear_velocity = Vector3.ZERO
	position = orgin

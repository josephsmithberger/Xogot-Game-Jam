extends RigidBody3D
@onready var orgin : Vector3 = position
var current_level:int = 1
signal next_level(level: int)

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.name == "bounds":
		linear_velocity = Vector3.ZERO
		position = orgin


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.name == "goal":
		current_level += 1
		next_level.emit(current_level)
		

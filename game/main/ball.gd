extends RigidBody3D
@onready var orgin : Vector3 = position

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.name == "bounds":
		position = orgin

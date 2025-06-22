extends RigidBody3D
@onready var orgin : Vector3 = position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.name == "bounds":
		position = orgin

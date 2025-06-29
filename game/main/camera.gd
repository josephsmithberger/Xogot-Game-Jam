extends Camera3D
@onready var ball : RigidBody3D = $"../Node3D".get_child(0)
var follow_speed := 2

func _physics_process(delta: float) -> void:
	if ball:
		position.x = lerp(position.x, ball.position.x, follow_speed * delta)
		position.z = lerp(position.z, ball.position.z, follow_speed * delta)

func _process(delta: float) -> void:
	if not ball:
		ball = $"../Node3D".get_child(0)

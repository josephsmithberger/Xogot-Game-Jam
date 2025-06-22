extends Camera3D
@onready var ball : RigidBody3D = $"../ball"
var follow_speed := 2

func _physics_process(delta: float) -> void:
	position.x = lerp(position.x, ball.position.x, follow_speed * delta)
	position.z = lerp(position.z, ball.position.z, follow_speed * delta)

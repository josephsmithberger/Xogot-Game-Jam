extends Camera3D
@onready var ball : RigidBody3D = $"../ball"
var follow_speed := 0.3

func _physics_process(delta: float) -> void:
	position.x = 0.8 * lerp(position.x, ball.position.x, follow_speed * delta)
	position.z = 0.8 * lerp(position.z, ball.position.z, follow_speed * delta)

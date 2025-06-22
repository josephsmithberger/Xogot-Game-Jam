extends Camera3D
@onready var ball : RigidBody3D = $"../ball"

func _ready() -> void:
	print(ball)
	
func _process(delta: float) -> void:
	position.x = ball.x
	position.z = ball.z

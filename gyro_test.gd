extends MeshInstance3D

# Called every frame
func _process(delta: float) -> void:
	var gyro_rotation: Vector3 = Input.get_accelerometer()
	rotation = gyro_rotation

extends Node3D

func _process(delta):
	# Get the gravity vector from the device
	var gravity = Input.get_gravity()
	# Calculate the rotation from the gravity vector
	var up = -gravity.normalized()
	var basis = Basis()
	basis.y = up
	basis.x = basis.y.cross(Vector3.FORWARD).normalized()
	basis.z = basis.x.cross(basis.y).normalized()
	# Set the node's rotation to match the device orientation
	self.basis = basis

extends Node3D

var initial_gravity = Vector3()
var initial_basis = Basis()
var initialized = false

func _ready():
    # Give a short delay to get a stable reading
    await get_tree().create_timer(0.5).timeout
    initial_gravity = Input.get_gravity()
    initial_basis = self.basis
    initialized = true

func _process(delta):
    if not initialized:
        return
        
    # Get the current gravity vector
    var current_gravity = Input.get_gravity()
    
    # Create quaternions for initial and current orientations
    var from = Quaternion(Vector3.UP, -initial_gravity.normalized())
    var to = Quaternion(Vector3.UP, -current_gravity.normalized())
    
    # Calculate the relative rotation
    var rotation = from.inverse() * to
    
    # Apply the rotation to the initial basis
    self.basis = initial_basis * Basis(rotation)
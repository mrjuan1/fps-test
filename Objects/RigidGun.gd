extends RigidBody3D

func _ready() -> void:
	var force: Vector3 = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * randf_range(100.0, 300.0)
	if force.y < 0.0:
		force.y = 0.0
	apply_force(force)

	angular_velocity = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * randf_range(PI, PI * 5.0)

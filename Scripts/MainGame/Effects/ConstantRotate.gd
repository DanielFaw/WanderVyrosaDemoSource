extends Spatial

export var rotation_speed:float = 1.0


func _process(delta: float):
	self.rotate(transform.basis.y.normalized(),deg2rad(rotation_speed) * delta)
	pass
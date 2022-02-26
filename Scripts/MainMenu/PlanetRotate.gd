extends Spatial

export var speed:float = 20.0

func _process(delta):

	rotate_y(delta* speed/10.0)
	pass
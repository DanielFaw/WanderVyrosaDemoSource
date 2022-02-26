extends Node

export var wait_time:float = 0.0

export(Array,NodePath) var particle_paths

func _ready():
	yield(get_tree(),"idle_frame")

	for path in particle_paths:
		get_node(path).set_one_shot(true)
		get_node(path).set_emitting(true)
		pass

	pass

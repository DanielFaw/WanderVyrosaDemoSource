extends Node

export var destruction_time:float = 1.0

func _ready():
	yield(get_tree().create_timer(destruction_time),"timeout")
	self.queue_free()
	pass

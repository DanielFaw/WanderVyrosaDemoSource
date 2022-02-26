extends Spatial


func _ready():
	var _null = $Timer.connect("timeout",self,"timeout")
	$Particles.emitting = true
	pass

func timeout():
	self.queue_free()
	pass
	
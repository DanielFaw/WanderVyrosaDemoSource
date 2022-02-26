extends TextureRect

export var rotation_speed:float = 5

func _ready():
	pass


func _process(delta):

	rect_rotation += rotation_speed * delta
	
	pass
extends TextureButton

var button_planet_id = -1


export(Array,Resource) var planet_button_icons
export(Array,Resource) var planet_button_pressed_icons

signal planet_button_pressed(button_planet_id)


func _init():
	var _connection =  connect("pressed",self,"EmitPressed")
	pass

func EmitPressed():
	self.emit_signal("planet_button_pressed",button_planet_id)
	pass

func SetData(planet_id,texture_id_to_set = 0):
	button_planet_id = planet_id
	texture_normal = planet_button_icons[texture_id_to_set]
	texture_pressed = planet_button_pressed_icons[texture_id_to_set]
	pass

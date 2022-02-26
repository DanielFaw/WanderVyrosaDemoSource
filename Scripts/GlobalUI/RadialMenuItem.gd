extends Node


export var icon_path:NodePath

var icon_texture:Texture
var icon:TextureRect

func _ready():
	icon = get_node(icon_path)
	
	if(icon_texture != null):
		icon.texture = icon_texture
		pass
	pass

func SetIcon(texture):
	icon_texture = texture
	pass

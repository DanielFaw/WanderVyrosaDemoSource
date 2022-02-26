extends Node


export var multiplayer_options_path:NodePath

var multiplayer_options:Control

func _ready():
	multiplayer_options = get_node(multiplayer_options_path)
	var _null = InputState.connect("inputStateChanged",self,"_OnInputStateChange")
	pass


func OnClick():
	multiplayer_options.visible = !multiplayer_options.visible
	pass

func _exit_tree():
	if(InputState.is_connected("inputStateChanged",self,"_OnInputStateChange")):
		InputState.disconnect("inputStateChanged",self,"_OnInputStateChange")

func _OnInputStateChange(newState):

	if(newState == 0):
		multiplayer_options.visible = false
	pass

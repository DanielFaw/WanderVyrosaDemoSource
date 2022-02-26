extends Button



export var _serverOptionsPath:NodePath

var _serverOptions:Control

func _ready():
	_serverOptions = get_node(_serverOptionsPath)
	var _null = InputState.connect("inputStateChanged",self,"_OnInputStateChange")
	pass

func _on_ServerOptionsButton_pressed() -> void:
	#Open up the server options
	_serverOptions.visible = !_serverOptions.visible
	get_node("../../../..").visible = false
	
	
	
	pass # Replace with function body.


func _exit_tree():
	if(InputState.is_connected("inputStateChanged",self,"_OnInputStateChange")):
		InputState.disconnect("inputStateChanged",self,"_OnInputStateChange")

func _OnInputStateChange(newState):

	if(newState == 0):
		_serverOptions.visible = false
	pass

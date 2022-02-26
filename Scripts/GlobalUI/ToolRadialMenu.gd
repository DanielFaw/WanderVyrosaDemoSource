extends "res://Scripts/GlobalUI/RadialMenuController.gd"


func _ready():
	SceneResources.GetResource("Multitool").SetRadialMenu(self)
	var _con_result = SceneResources.GetResource("Multitool").connect("muiti_tool_selecting",self,"_OpenMenu")
	_con_result = SceneResources.GetResource("Multitool").connect("multi_tool_menu_closed",self,"_CloseMenu")
	pass


func _input(event: InputEvent):
	._input(event)
	pass
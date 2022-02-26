extends Control

export var settings_menu_path:NodePath
var settings_menu:Node

var exit_confirm:Node


# Called when the node enters the scene tree for the first time.
func _ready():

	self.visible = false
	# Setup signal connections
	var _connection_result = InputState.connect("escape_key_pressed",self,"EscapePressed")
	settings_menu = get_node(settings_menu_path)
	_connection_result = settings_menu.connect("settings_closed",self,"CloseSettings")

	exit_confirm = get_node("ExitConfirmation")
	pass # Replace with function body.

func _exit_tree():
	if(InputState.is_connected("escape_key_pressed",self,"EscapePressed")):
		InputState.disconnect("escape_key_pressed",self,"EscapePressed")
		pass
	if(settings_menu.is_connected("settings_closed",self,"CloseSettings")):
		settings_menu.disconnect("settings_closed",self,"CloseSettings")
		pass

func ResumeButtonPressed():
	InputState.ChangeInputState("ALL")
	self.visible = false
	pass

func ExitButtonPressed():
	#TODO: Popup confirmation window
	exit_confirm.visible = true
	pass

# Exit to the main menu
func ExitConfirmed():
	exit_confirm.visible = false
	# Make sure the scene has been unpaused
	get_tree().paused = false
	SceneManager.LoadScene("mainMenu")
	pass

func ExitDenied():
	#TODO: Just close the confirmation window
	exit_confirm.visible = false
	pass

func OpenSettings():
	settings_menu.OpenSettings()
	settings_menu.visible = true
	self.visible = false
	pass

func CloseSettings():
	settings_menu.visible = false
	self.visible = true
	pass


# A callback for when the escape key is pressed (from InputState.gd)
#   Controlling when the pause menu is shown
func EscapePressed():
	# Open Pause menu
	if(InputState.GetCurrentInputState() == "UI_CONTROL"):
		self.visible = true
		InputState.SetCursorModifierActiveState(true)
		return

	# Close Pause menu
	elif(InputState.GetCurrentInputState() == "ALL"):
		self.visible = false
		settings_menu.visible = false
		return
	pass

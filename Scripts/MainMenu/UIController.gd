extends Node

export var credits_path:NodePath

func _ready():
	InputState.ToggleCursor(true)
	InputState.SetCursorModifierActiveState(true)
	InputState.ToggleEscapeExit(true)
	get_node(credits_path).visible = false

	pass

func _exit_tree():
	InputState.ToggleCursor(false)
	InputState.SetCursorModifierActiveState(false)
	InputState.ToggleEscapeExit(false)
	pass


func OpenCredits():
	get_node(credits_path).visible = true

	pass

func CloseCredits():
	get_node(credits_path).visible = false
	pass


func Play():
	#print("Playing Game")
	SceneManager.LoadScene("homeShip");
	pass

func Exit():
	get_tree().quit();
	pass

extends Node
enum INPUT_STATE {ALL, UI_CONTROL, MOUSE_ONLY}
""" STATE DESCRIPTION
	ALL: 			All player input (mouse and keyboard) is active and applied to the player 
	UI_CONTROL:		Input is captured, but IS NOT applied to player or camera movement
	MOUSE_ONLY: 	Only mouse input is applied (idk what we'd use this for currently, maybe a cinematic cutscene?)
"""
# Is the cursor currently captured
var is_cursor_captured = false

var is_escape_disabled = false

var is_cursor_visible = false

var current_state = INPUT_STATE.ALL

var game_paused = false

var current_cursor_position:Vector2 = Vector2.ZERO

# Allows modification of triggers of mouse cursor capture if TRUE
var is_cursor_capture_modifier_active = false

signal inputStateChanged(newState)
signal cursorToggled(isCursorShowing)
signal escape_key_pressed()


func _ready():
	ToggleCursor(false)
	# Dont pause this script when the scene is paused
	pause_mode = Node.PAUSE_MODE_PROCESS
	pass

# Change the current input state we are in
func ChangeInputState(new_input_state:String):

	match(new_input_state):
		"ALL":
			current_state = INPUT_STATE.ALL
			get_tree().paused = false
			ToggleCursor(false)
			pass
		"UI_CONTROL":
			current_state = INPUT_STATE.UI_CONTROL
			ToggleCursor(true)
			pass
		"MOUSE_ONLY":
			current_state = INPUT_STATE.MOUSE_ONLY
			pass
		_:
			print("INPUT STATE: " + new_input_state + " DOES NOT EXIST")
			print_stack()

	emit_signal("inputStateChanged",current_state)

	pass

# Get the current cursor state
func GetCursorCaptured():
	return is_cursor_captured
	pass

	
func GetCursorModifierActiveState():
	return is_cursor_capture_modifier_active
	pass

func GetIsGamePaused():
	return game_paused
	pass

func GetCursorVisible():
	return is_cursor_visible
	pass

func SetCursorModifierActiveState(new_state):
	is_cursor_capture_modifier_active = new_state
	pass


func GetCursorPosition():
	return current_cursor_position
	pass


# Disable the exit on escape (i.e in main menu)
func ToggleEscapeExit(is_disabled:bool):
	is_escape_disabled = is_disabled
	pass


func GetCurrentInputState():
	match(current_state):
		INPUT_STATE.ALL:
			return "ALL"
			pass
		INPUT_STATE.UI_CONTROL:
			return "UI_CONTROL"
			pass
		INPUT_STATE.MOUSE_ONLY:
			return "MOUSE_ONLY"
			pass
	pass

func _input(event):
	Debug.Report("CursorState","Cursor Captured: " + str(is_cursor_captured))
	
	#if(!is_cursor_capture_modifier_active):
	#	# Change mouse cursor state if window is clicked or ESCAPE is pressed
	#	if(event is InputEventMouseButton):
	#		if(event.button_index == BUTTON_LEFT && event.pressed && current_state != INPUT_STATE.UI_CONTROL):
	#			#ToggleCursor(false)
	#			pass
	#		pass
	#	pass
	#pass
		
	# This will probably be made into a pause
	if(event is InputEventKey):

		# If escape is pressed
		if(event.scancode == KEY_ESCAPE && event.pressed && !is_escape_disabled):
			if(current_state == INPUT_STATE.ALL):
				ChangeInputState("UI_CONTROL")
				get_tree().paused = true
				game_paused = true
				emit_signal("escape_key_pressed")
				return
			elif(current_state == INPUT_STATE.UI_CONTROL):
				ChangeInputState("ALL")
				get_tree().paused = false
				game_paused = false
				emit_signal("escape_key_pressed")
				return
			pass

	# Track cursor position
	if event is InputEventMouseMotion:
		current_cursor_position =  get_viewport().get_mouse_position()
		pass
	pass

#Shows/Hides the cursor and locks it to the center of the screen accordingly
func ToggleCursor(var cursor_free:bool,var is_cursor_visible=true):
	if(cursor_free):
		if(is_cursor_visible):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			is_cursor_visible = true
			pass
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			is_cursor_visible = false
			pass
		is_cursor_captured = false
		pass
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		is_cursor_captured = true
		is_cursor_visible = false
		pass

	emit_signal("cursorToggled", is_cursor_captured)
	pass
	

extends Spatial

enum MULTITOOL_MODE {NONE,BUILD,SCAN,ANALYZE}

signal multi_tool_toggled(is_active)
signal multi_tool_menu_closed
signal muiti_tool_selecting

var current_camera

var ground_col_mask = 0b00000000000000000001

var current_mouse_world_pos

var time_since_open:float = 0.0

var multitool_radial_menu

var tool_button_held:bool =  false
var tool_menu_opened:bool = false

# The amount of time (in seconds) the button needs to be held to bring up the mode selection menu
var menu_hold_time:float = 0.3

var hold_time_elapsed:float = 0.0

var multitool_active:bool = false
var current_multitool_mode = MULTITOOL_MODE.BUILD


# Can the multiool even be activated
var multitool_enabled = true

func _init():
	SceneResources.RegisterResource("Multitool",self)
	pass
	

func SetMultitoolEnabled(is_enabled):
	multitool_enabled = is_enabled
	pass

# Have radial menu "self report" to set this (for function connections)
func SetRadialMenu(radial_menu):
	multitool_radial_menu = radial_menu
	var _connection_result = multitool_radial_menu.connect("selection_changed",self,"SetMode")
	pass


func _process(delta: float):

	if(!multitool_enabled):
		return

	# Open multitool initially
	if(Input.is_action_just_pressed("toggle_build_mode") && !multitool_active ):
		ActivateMultitool(current_multitool_mode)
		tool_button_held = true
		multitool_active = true
		current_camera = get_viewport().get_camera()

		# Track once to initialize/update data
		TrackWorldMousePos()

		emit_signal("multi_tool_toggled",true)
		hold_time_elapsed = 0.0
		time_since_open = 0.0
		return
		pass

	
	if(multitool_active):
		# Track position continuiously 
		TrackWorldMousePos()
		time_since_open += delta

		## Allow player to rotate camera if needed in build mode
		#if(Input.is_action_pressed("tool_camera_rotate")):
		#	InputState.ToggleCursor(false)
		#	pass
		#elif(Input.is_action_just_released("tool_camera_rotate")):
		#	InputState.ToggleCursor(true,false)
		#	pass

		# Close the tool menu, but dont disable the tool yet
		if(Input.is_action_just_released("toggle_build_mode") && tool_menu_opened):
			# Close multitool
			emit_signal("multi_tool_menu_closed")
			InputState.ToggleCursor(false)
			hold_time_elapsed = 0.0
			tool_menu_opened = false
			return
			pass

		# Close the menu and disable the tool
		# 	Note: Time check is added to make sure the tool wasn't activated then immediately deactivated
		elif(Input.is_action_just_released("toggle_build_mode") && !tool_menu_opened && time_since_open > 0.25):
			# Close multitool
			InputState.ToggleCursor(false)
			tool_button_held = false
			multitool_active = false
			DeactivateMultitool()
			emit_signal("multi_tool_toggled",false)
			hold_time_elapsed = 0.0
			return
			pass

		# Check for button hold and open menu
		elif(tool_button_held && Input.is_action_pressed("toggle_build_mode") && !tool_menu_opened):
			hold_time_elapsed += delta
			if(hold_time_elapsed > menu_hold_time && multitool_active):
				emit_signal("muiti_tool_selecting")
				InputState.ToggleCursor(true,false)
				tool_menu_opened = true
				hold_time_elapsed = 0.0
				pass
			return
		pass
	pass

# Activate the multitool in *multitool_mode* mode
func ActivateMultitool(multitool_mode):
	#InputState.ToggleCursor(true,false)
	InputState.SetCursorModifierActiveState(true)
	#print(InputState.GetCursorModifierActiveState())
	
	match(multitool_mode):
		1:
			SceneResources.GetResource("BuildingController")._ToggleBuildMode(true)
			SceneResources.GetResource("ScanningController").SetScanModeState(false)
			pass
		2:
			SceneResources.GetResource("BuildingController")._ToggleBuildMode(false)
			SceneResources.GetResource("ScanningController").SetScanModeState(true)
			pass
		_:
		
			#SceneResources.GetResource("BuildingController")._ToggleBuildMode(false)
			#SceneResources.GetResource("ScanningController").SetScanModeState(false)
			pass

	pass

func GetWorldMousePositionMultitool():
	return current_mouse_world_pos
	pass

# Track the mouse position in world space using the planet as the collision check
func TrackWorldMousePos():
	var frompos = current_camera.project_ray_origin(get_viewport().get_mouse_position())
	var toPos =  current_camera.project_ray_normal(get_viewport().get_mouse_position()) * 100.0
	
	var space_state = get_world().direct_space_state
	var rayCollisionInfo = space_state.intersect_ray(frompos,toPos,[],ground_col_mask,true,false)

	if(rayCollisionInfo.size() != 0):
		current_mouse_world_pos = rayCollisionInfo.position
		pass

	pass

func DeactivateMultitool():
	InputState.SetCursorModifierActiveState(false)
	SceneResources.GetResource("BuildingController")._ToggleBuildMode(false)
	SceneResources.GetResource("ScanningController").SetScanModeState(false)
	pass


# Set the new multitool mode
func SetMode(new_mode):
	# TODO: Set to different modes 
	# TODO: Ethan - Will probably need to update other controllers (scanner, build, etc) to take a bool determining if the controller is active
	
	match(new_mode):
		"Build":
			current_multitool_mode = MULTITOOL_MODE.BUILD
			pass
		"Scan":
			current_multitool_mode = MULTITOOL_MODE.SCAN
			pass
		_:
			#current_multitool_mode = MULTITOOL_MODE.NONE
			pass

	# Change the current multitool mode
	ActivateMultitool(current_multitool_mode)
	
	pass

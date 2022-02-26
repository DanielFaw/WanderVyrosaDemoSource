extends Spatial

export var scanning_marker_path:NodePath
var scanning_marker
var ground_col_mask = 0b00000000000000100001
var vein_col_mask = 0b00000000000000100000

var current_scanning_pos = Vector3.ZERO
var current_local_up = Vector3.ZERO
var currently_scanned_vein = null
var hovered_vein = null


# Marker References
var pulse_node
var marker_audio_node
var marker_info_display


var is_active:bool = false

# The currently active camera for the scene
var current_camera

func _init():
	SceneResources.RegisterResource("ScanningController",self)
	pass

func _ready():
	scanning_marker = get_node(scanning_marker_path)
	pulse_node = scanning_marker.get_node("Marker/Pulse")
	marker_audio_node = scanning_marker.get_node("ScanningAlert")
	marker_info_display = scanning_marker.get_node("VeinPopup")
	pulse_node.visible = false
	pass

func _process(_delta: float):
	if(!is_active):
		if(marker_audio_node.playing):
			marker_audio_node.playing = false
			pass
		return

	# Check if we can scan an place markers
	PositionMarker()
	LookForScannable()

	if(Input.is_action_pressed("player_action") && hovered_vein != null):
		ScanVein()
		if(marker_audio_node.playing):
			marker_audio_node.playing = false
			pass
		pass
	elif(Input.is_action_just_released("player_action")):
		StopScanning()
	pass

# Set the scan marker position
func PositionMarker():
	# Allow placement of prefab
	# Calculate raycast points based on position
	var frompos = current_camera.project_ray_origin(get_viewport().get_mouse_position())
	var toPos =  current_camera.project_ray_normal(get_viewport().get_mouse_position()) * 100.0
	
	var space_state = get_world().direct_space_state
	var rayCollisionInfo = space_state.intersect_ray(frompos,toPos,[],ground_col_mask,true,false)

	# If we have a collision, align the object
	if(rayCollisionInfo.size() != 0):
		current_local_up = Utilities.CalculateGravityDirection(rayCollisionInfo.position)
		scanning_marker.global_transform.origin = rayCollisionInfo.position + current_local_up * 0.1
		scanning_marker.global_transform = Utilities.AlignWithNormal(scanning_marker.global_transform,current_local_up)
		current_scanning_pos = rayCollisionInfo.position
		pass
	pass

# Raycast to see if we are over a scannable vein
func LookForScannable():

	# TODO: Add raycast to check for scannable objects
	var frompos = current_scanning_pos + current_local_up * 2.0
	var toPos =  current_scanning_pos - current_local_up * 2.0

	var space_state = get_world().direct_space_state
	var rayCollisionInfo = space_state.intersect_ray(frompos,toPos,[],vein_col_mask,true,false)

	# If there is a collision, align the object
	if(rayCollisionInfo.size() != 0):
		hovered_vein = rayCollisionInfo.collider.get_owner().get_owner()
		pulse_node.visible = true
		if(!marker_audio_node.playing):
			marker_audio_node.playing = true
			pass
		pass
	else:
		hovered_vein = null
		pulse_node.visible = false
		marker_audio_node.playing = false
		marker_info_display.visible = false
		StopScanning()
		pass
	pass

# Disable all scanning effects
func StopScanning():
	if(currently_scanned_vein != null):
		currently_scanned_vein.SetScanning(false)
		currently_scanned_vein = null
		marker_info_display.visible = false
		pass

# Scan the currently hovered vein of ore
func ScanVein():
	if(currently_scanned_vein != hovered_vein):
		if(currently_scanned_vein != null):
			currently_scanned_vein.SetScanning(false)
			pass
		currently_scanned_vein = hovered_vein
		hovered_vein.SetScanning(true)

		# Set and display the vein data
		marker_info_display.SetDisplayData(hovered_vein.GetVeinInfo())
		marker_info_display.visible = true
		pass
	pass

# Set the state of the current mode
func SetScanModeState(is_scanner_active):
	is_active = is_scanner_active

	scanning_marker.visible = is_active
	
	InputState.SetCursorModifierActiveState(is_active)
	current_camera = get_viewport().get_camera()
	pass

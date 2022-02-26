extends Spatial

#----EXPORTS-----------------

# Mouse X sensitivity 
var horiz_sensitivity = 0.01
var vert_sensitivity = 0.01


var horiz_sensitivity_bounds:Vector2 = Vector2(0.1,100.0)
var vert_sensitivity_bounds:Vector2 = Vector2(0.1,100.0)

var max_delta_time = 6.944444



# Min Z angle
export var min_z_angle:float
# Max Z angle
export var max_z_angle:float

# How fast we move towards the target
export var move_speed:float = 1.0

export var interpolate_to_target:bool = true

export var target_object_path:NodePath
export var vertical_target_offset:float

export var planet_path:NodePath

export var shoulder_view_pos_path:NodePath

export var follow_view_pos_path:NodePath

export var mouse_smoothing_enabled:bool = false

export var on_planet:bool = true
export var collide_with_walls = false

export(Curve) var camera_pitch_curve
#----------------------------
#----REFERENCES--------------

var target_object:Spatial

var planet:Spatial

var camera:Camera

var shoulder_view_pos:Spatial

var follow_view_pos:Spatial

var tween:Tween
#----------------------------
#----VARIABLES---------------

var speed_y = 0.0
var speed_z = 0.0

var max_distance = 5.0
var wall_collide_bit_mask = 0b00000000000000000001
var last_distance = 0

var new_input_x = 0.0
# Captured mouse position input each frame
var mouse_input:Vector2

# Can the player influence the camera
var enabled = true

# Current rotation around Y axis
var y_rot:float = -PI/2.0

# Current rotation around Z axis
var z_rot:float


# Screenshake parameters
# https://kidscancode.org/godot_recipes/2d/screen_shake/

var shake_decay = 0.95

var max_offset = Vector2(0.1,0.1)

var trauma = 0.0
var trauma_power = 1.0

var simplex_noise = OpenSimplexNoise.new()
var noise_y = 0.0


var local_cam_target


var player_ref
#----------------------------

func _init():
	var _connection_results = RuntimeSettings.connect("settings_changed",self,"UpdateMouseInputOptions")
	SceneResources.RegisterResource("CameraController",self)
	pass

	
# Called when the node enters the scene tree for the first time.
func _ready():
	simplex_noise.seed = randi()
	simplex_noise.period = 4
	simplex_noise.octaves = 2

	UpdateMouseInputOptions()
	InitReferences()
	ConnectSignals()
	# Idk why we need the viewport HEIGHT here since its taking in the X input of the mouse but oh well
	new_input_x = get_viewport().get_visible_rect().size.y/2.0

	if(target_object != null):
		global_transform.origin = target_object.global_transform.origin

	# Start camera as far out as possible
	var vec_to_camera = (camera.global_transform.origin - global_transform.origin).normalized()
	camera.global_transform.origin = global_transform.origin + vec_to_camera * max_distance

	InputState.ToggleCursor(false)
	InputState.SetCursorModifierActiveState(false)
	InputState.ToggleEscapeExit(false)
	InputState.ChangeInputState("ALL")
	player_ref = SceneResources.GetResource("Player")
	pass # Replace with function body.

	
func _exit_tree():
	_DisconnectSignals()
	pass


# Connect signals
func ConnectSignals():
	if(on_planet):
		var _temp = SceneResources.GetResource("Multitool").connect("multi_tool_toggled",self,"_OnToolModeToggled")
		pass
	pass


# Update input settings by getting new control Runtime Settings
func UpdateMouseInputOptions():
	vert_sensitivity = lerp(vert_sensitivity_bounds.x,vert_sensitivity_bounds.y,RuntimeSettings.GetSetting("mouse_sensitivity_vert")/100.0)
	horiz_sensitivity = lerp(horiz_sensitivity_bounds.x,horiz_sensitivity_bounds.y,RuntimeSettings.GetSetting("mouse_sensitivity_horiz")/100.0)
	pass


# Disconnects signals
func _DisconnectSignals():
	if(on_planet):
		SceneResources.GetResource("Multitool").disconnect("multi_tool_toggled",self,"_OnToolModeToggled")
		pass

	if(RuntimeSettings.is_connected("settings_changed",self,"UpdateMouseInputOptions")):
		RuntimeSettings.disconnect("settings_changed",self,"UpdateMouseInputOptions")
		pass
	pass


# Initialize internal references to external nodes
func InitReferences():
	target_object = get_node(target_object_path)
	if(on_planet):
		planet = get_node(planet_path)
	follow_view_pos = get_node(follow_view_pos_path)
	shoulder_view_pos = get_node(shoulder_view_pos_path)
	tween = $Tween
	camera = get_viewport().get_camera()

	pass

# Add camera shake trauma
func AddShakeTrauma(trauma_to_add = 0.1):
	trauma = min(trauma + trauma_to_add,1.0)
	pass


func ShakeCamera():
	var amount = pow(trauma,trauma_power)
	var offset =  Vector2.ZERO
	noise_y +=1
	offset.x = max_offset.x * amount * simplex_noise.get_noise_2d(simplex_noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * simplex_noise.get_noise_2d(simplex_noise.seed*3, noise_y)

	camera.transform.origin += Vector3(offset.x,offset.y,0)
	pass

# Captures input (built in function)
func _input(event):
	if(event is InputEventMouseMotion):
		# Reset mouse input
		mouse_input = event.relative
		mouse_input.x *= horiz_sensitivity
		mouse_input.y *= vert_sensitivity
		pass
	pass

	
func _process(delta: float):
	if(enabled):
		RotateCamera(deg2rad(-mouse_input.y * delta),deg2rad(mouse_input.x * delta),get_physics_process_delta_time())
		pass


	#if(trauma > 0.0):
	#	trauma = max(trauma - shake_decay * delta, 0)
	#	ShakeCamera()
	#	pass


	mouse_input = Vector2.ZERO
	pass

func _physics_process(delta: float):
	if(collide_with_walls):
		# Avoid camera clipping through walls
		_AvoidWalls(delta)
		pass
	pass

func _AvoidWalls(delta:float):

	# Cast ray towards new camera pos
	var space_state = get_world().direct_space_state
	var ray_collision_info = space_state.intersect_ray(global_transform.origin,camera.global_transform.origin,[self,player_ref],wall_collide_bit_mask,true,false)
	var dist_to_camera = global_transform.origin.distance_to(camera.global_transform.origin)


	if(!ray_collision_info.empty()):
		# Collision has occured
		var vec_to_collision =  (ray_collision_info["position"] - camera.global_transform.origin ).normalized()
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(ray_collision_info["position"] - vec_to_collision * 0.1 ,delta * 30)
		return

	else:
		if(dist_to_camera <= max_distance ):
			var vec_to_camera = (camera.global_transform.origin - global_transform.origin).normalized()
			camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(global_transform.origin + vec_to_camera * (dist_to_camera + 0.5),delta * 10)
			pass
		pass
	pass


# Try to rotate the camera, but let the mouse take priority
func ExternalRotateCamera(delta_z,delta_y):
	if(mouse_input == Vector2.ZERO && InputState.GetCursorCaptured()):
		RotateCamera(delta_z,delta_y,get_process_delta_time())
		pass
	pass

# Set the Z rotation of the camera (in radians)
func SetCameraRotationZ(new_z):
	z_rot = clamp(new_z,deg2rad(min_z_angle),deg2rad(max_z_angle))
	RotateCamera(0,0,0)
	pass

# Set the Y rotation of the camera (in radians)
func SetCameraRotationY(new_y):
	y_rot = new_y
	RotateCamera(0,0,0)
	pass


# Rotate the camera with a given z and y speed
func RotateCamera(delta_z,delta_y,delta):

	if(delta_y == null):
		delta_y = 0
		pass
	if(delta_z == null):
		delta_z = 0
		pass

	# Move if the cursor is currently captured
	if(InputState.GetCursorCaptured() && InputState.GetCurrentInputState() == "ALL"):

		# Lerp rotation around the Y axis
		speed_y = lerp(speed_y,delta_y,delta * 8.0)
		y_rot -= speed_y


		# Lerp rotation around the Z
		speed_z = lerp(speed_z,delta_z ,delta * 8.0) 
		z_rot += speed_z
		z_rot = clamp(z_rot ,deg2rad(min_z_angle),deg2rad(max_z_angle)) 

	# Rotate camera around Y axis relative to target transform
	var new_transform = target_object.transform

	# Basically like normalize but spherical (I think), prevents float rounding errors
	#new_transform.orthonormalized()
	
	if(on_planet):
		# Align to planet surface
		global_transform = Utilities.AlignWithNormal(new_transform,(global_transform.origin - planet.global_transform.origin).normalized())
		global_transform.origin = target_object.global_transform.origin
	else:
		global_transform = Utilities.AlignWithNormal(new_transform,Vector3(0,1,0).normalized()) 
		global_transform.origin = target_object.global_transform.origin
		pass
	
	# Rotate around Z axis
	global_rotate(transform.basis.z,z_rot)
	global_rotate(target_object.global_transform.basis.y.normalized(),y_rot)
	pass

# Callback for when build mode is toggled
func _OnToolModeToggled(var tool_mode_active):

	if(tool_mode_active):
		# Lerp to shoulderPose
		var _null_arg
		_null_arg = tween.stop(camera)
		_null_arg = tween.interpolate_property(camera, "translation",null,shoulder_view_pos.translation,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		_null_arg = tween.start()
		pass
	else:
		var _null_arg
		# Lerp to followPose
		_null_arg = tween.stop(camera)
		_null_arg = tween.interpolate_property(camera, "translation",null,follow_view_pos.translation,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		_null_arg = tween.start()
		pass
	pass

extends Spatial

export var ship_model_path:NodePath
var ship_model:Spatial

export var player_base_path:NodePath
var player_base:Spatial

export var player_path:NodePath
var player

export var camera_target_path:NodePath
var camera_target

export var motor_particles_path:NodePath
var motor_particles:Particles

export var smoke_particles_path:NodePath
var smoke_particles:Particles



var player_fade_mat:Material = preload("res://Materials/PAL_Main_FADE.tres")
var player_torso_mat:Material = load("res://Materials/PlayerTorsoMat.tres")
var jetpack_indicator_mat:Material = load("res://Materials/JetpackIndicator.tres")

var far_dither_value: float = 50.0
var default_dither_value: float = 1.9

export var motor_light_path:NodePath
var motor_light

var ship_land_end_y = 19.355

var ship_takeoff_end_y = 52.187
var tween

export var ship_audio_path:NodePath

var ship_audio

var camera_controller

func _ready():
	
	# TODO: Add option to skip landing 

	camera_target = get_node(camera_target_path)
	player_base = get_node(player_base_path)
	ship_model = get_node(ship_model_path)
	player = get_node(player_path)
	motor_particles = get_node(motor_particles_path)
	motor_light = get_node(motor_light_path)
	smoke_particles = get_node(smoke_particles_path)
	ship_audio = get_node(ship_audio_path)
	tween = $Tween

	camera_controller = SceneResources.GetResource("CameraController")


	# Skip the landing animation if needed
	if(!SceneManager.GetActiveSceneArgs().has("landing_skip")):
			LandingAnimation()
			pass
	elif(SceneManager.GetActiveSceneArgs().has("landing_skip")):
		if(!SceneManager.GetActiveSceneArgs()["landing_skip"]):
			LandingAnimation()
			pass
		pass

	

	pass


# Animate taking off from the planet
func TakeoffAnim():

	InputState.ToggleEscapeExit(true)
	SceneResources.GetResource("Multitool").SetMultitoolEnabled(false)
	player.SetPlayerInputActive(false)

	# Fade the player out
	var _tween_bool = tween.interpolate_property(player_fade_mat,"distance_fade_max_distance",default_dither_value,far_dither_value,0.5,Tween.TRANS_QUAD,Tween.EASE_OUT)
	_tween_bool = tween.interpolate_property(player_torso_mat,"distance_fade_max_distance",default_dither_value,far_dither_value,0.5,Tween.TRANS_QUAD,Tween.EASE_OUT)
	_tween_bool = tween.interpolate_property(jetpack_indicator_mat,"distance_fade_max_distance",default_dither_value,far_dither_value,0.5,Tween.TRANS_QUAD,Tween.EASE_OUT)
	tween.start()

	# Wait for them to fade out
	yield(get_tree().create_timer(1.0),"timeout")
	
	camera_target.SetTarget(ship_model)

	motor_particles.emitting = true
	player.visible = false
	ship_model.visible = true
	player_base.visible = false

	ship_model.global_transform.origin.y = ship_land_end_y
	SceneResources.GetResource("CameraController").SetCameraRotationY(deg2rad(90))
	SceneResources.GetResource("CameraController").SetCameraRotationZ(deg2rad(0))

	_tween_bool = tween.interpolate_property(ship_model,"translation:y",null,ship_takeoff_end_y,5.0,Tween.TRANS_QUAD,Tween.EASE_IN)
	_tween_bool = tween.interpolate_method(SceneResources.GetResource("CameraController"),"SetCameraRotationZ",deg2rad(20),deg2rad(-17.0),5.0,Tween.TRANS_QUAD,Tween.EASE_OUT)

	_tween_bool = tween.interpolate_property(ship_audio,"max_db",-60,-3,0.5,Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()
	ship_audio.play()

	motor_particles.emitting = true
	motor_light.visible = true

	var timer = 4.5

	# Wait 
	while(timer > 0.0): 
		timer -= get_process_delta_time()
		if(ship_model.global_transform.origin.y < ship_land_end_y + 1.5 && !smoke_particles.is_emitting()):
			smoke_particles.emitting = true
			pass
		elif(ship_model.global_transform.origin.y > ship_land_end_y + 1.5 && smoke_particles.is_emitting()):
			smoke_particles.emitting = false
			pass

		# Wait for next frame
		yield(get_tree(),"idle_frame")
		pass

	# Wait until the animation is finished
	#yield(get_tree().create_timer(4.5),"timeout")

	InputState.ToggleEscapeExit(false)
	SceneManager.LoadScene("homeShip")
	
	pass

# Animate landing on the planet
func LandingAnimation():

	ship_audio.play()
	# Disable escape while the animation is playing
	InputState.ToggleEscapeExit(true)
	SceneResources.GetResource("Multitool").SetMultitoolEnabled(false)

	# Set inital variables
	player.SetPlayerInputActive(false)
	camera_target.SetTarget(ship_model)

	motor_particles.emitting = true
	smoke_particles.emitting = false
	player.visible = false
	ship_model.visible = true
	player_base.visible = false

	# Snap camera rotation and model translation
	ship_model.translation.y = 39.728
	SceneResources.GetResource("CameraController").SetCameraRotationY(deg2rad(90))
	SceneResources.GetResource("CameraController").SetCameraRotationZ(deg2rad(-13.0))

	var _tween_bool = tween.interpolate_property(ship_model,"translation:y",null,ship_land_end_y,5.0,Tween.TRANS_QUAD,Tween.EASE_OUT)
	_tween_bool = tween.interpolate_method(SceneResources.GetResource("CameraController"),"SetCameraRotationZ",deg2rad(-17.0),deg2rad(20),5.0,Tween.TRANS_QUAD,Tween.EASE_OUT)

	_tween_bool = tween.interpolate_property(ship_audio,"max_db",-3,-20.0,5,Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()


	# Wait until the animation is finished
	while(tween.is_active()):

		# Start/stop particle systems
		if(ship_model.global_transform.origin.y < ship_land_end_y + 1.5 && ship_model.global_transform.origin.y > ship_land_end_y + 0.01 && !smoke_particles.is_emitting()):
			smoke_particles.emitting = true
			pass
		elif(ship_model.global_transform.origin.y < ship_land_end_y + 0.01 && smoke_particles.is_emitting()):
			smoke_particles.emitting = false
			pass

		# Turn off particles
		if(ship_model.global_transform.origin.y < ship_land_end_y + 0.01 && motor_particles.is_emitting()):
			motor_particles.emitting = false
			motor_light.visible = false
			smoke_particles.emitting = false
			pass
		else:
			camera_controller.AddShakeTrauma(0.1)

		yield(get_tree(),"idle_frame")
		pass

	# Pause for effect
	yield(get_tree().create_timer(1.0),"timeout")
	camera_target.SetTarget(player)
	SceneResources.GetResource("CameraController").SetCameraRotationY(deg2rad(0))
	ship_model.visible = false
	player_base.visible = true

	ship_audio.stop()
	

	# Fade in player
	_tween_bool = tween.interpolate_property(player_fade_mat,"distance_fade_max_distance",far_dither_value,default_dither_value,0.5,Tween.TRANS_QUAD,Tween.EASE_OUT)
	_tween_bool = tween.interpolate_property(player_torso_mat,"distance_fade_max_distance",far_dither_value,default_dither_value,0.5,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
	_tween_bool = tween.interpolate_property(jetpack_indicator_mat,"distance_fade_max_distance",far_dither_value,default_dither_value,0.5,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
	tween.start()
	
	player.visible = true

	# Wait until the fade animation is
	while(tween.is_active()):
		yield(get_tree(),"idle_frame")
		pass

	# Set states to gameplay for involved objects
	player.SetPlayerInputActive(true)
	SceneResources.GetResource("Multitool").SetMultitoolEnabled(true)
	InputState.ToggleEscapeExit(false)
	ship_model.visible = false

	#yield(get_tree().create_timer(3.0),"timeout")
	#TakeoffAnim()
	pass

func _exit_tree():
	# Reset the (sick) fade materials
	player_fade_mat.distance_fade_max_distance = default_dither_value
	player_torso_mat.distance_fade_max_distance = default_dither_value
	jetpack_indicator_mat.distance_fade_max_distance = default_dither_value
	pass

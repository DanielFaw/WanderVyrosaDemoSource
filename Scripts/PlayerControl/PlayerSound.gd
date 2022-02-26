extends Spatial


export var left_foot_sound_path:NodePath
export var right_foot_sound_path:NodePath

var left_foot_sound:AudioStreamPlayer
var right_foot_sound:AudioStreamPlayer

export var grass_footesteps:Array
export var metal_footesteps:Array


export var player_controller_path:NodePath
var player_controller

export(Vector2) var pitch_variation_range = Vector2(0.8,1.1);
export(Vector2) var volume_range = Vector2(-40.0,-20.0);


func _ready():
	left_foot_sound = get_node(left_foot_sound_path)
	right_foot_sound = get_node(right_foot_sound_path)

	if(get_node(player_controller_path) == null):
		player_controller = null
	else:
		player_controller = get_node(player_controller_path)

	# Set which footsteps should be used
	if(SceneManager.GetCurrentSceneName() == "homeShip"):
		left_foot_sound.stream = metal_footesteps[0]
		right_foot_sound.stream = metal_footesteps[0]

		# Enable reverb for the SFX bus
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("SFX"),0,true)
		pass
	elif(SceneManager.GetCurrentSceneName() == "mainWorld"):
		left_foot_sound.stream = grass_footesteps[0]
		right_foot_sound.stream = grass_footesteps[0]
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("SFX"),0,false)
		pass
	pass



func _StepLeft():
	if player_controller == null:
		return

	if(!player_controller.isOnGround):
		return
	var volume

	if(player_controller.currentVelocity.length() > 0.1):
		volume = lerp(volume_range.x,volume_range.y,( player_controller.currentVelocity.length() / player_controller.moveSpeed))
	else:
		volume = -100;
	var pitch = Utilities.GetRandomValue(pitch_variation_range.y,pitch_variation_range.x)	

	if(left_foot_sound.playing):
		left_foot_sound.stop()

	left_foot_sound.volume_db = volume	
	left_foot_sound.pitch_scale = pitch
	left_foot_sound.play()
	pass
func _StepRight():
	if player_controller == null:
		return
		
	if(!player_controller.isOnGround):
		return

	var volume
	if(player_controller.currentVelocity.length() > 0.1):
		volume = lerp(volume_range.x,volume_range.y,( player_controller.currentVelocity.length() / player_controller.moveSpeed))
	else:
		volume = -100;

	var pitch = Utilities.GetRandomValue(pitch_variation_range.y,pitch_variation_range.x)		

	if(right_foot_sound.playing):
		right_foot_sound.stop()
	right_foot_sound.volume_db = volume	
	right_foot_sound.pitch_scale = pitch
	right_foot_sound.play()
	pass

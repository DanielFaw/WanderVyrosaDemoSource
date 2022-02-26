extends AnimatedSprite3D

export var audio_path:NodePath
var audio:AudioStreamPlayer3D

var time_since_complete = 0
export var delay_time:float = 1

export var enabled = false


var timer:Timer

func _init():

	pass

func _ready():
	audio = get_node(audio_path)
	timer = Timer.new()
	var _connection = timer.connect("timeout",self,"Play")
	add_child(timer)

	var _conn = audio.connect("finished",self,"WaitToPlay")

	if(enabled):
		audio.play()
		play()

	pass

# Set the state of the ping
func SetEnabled(is_enabled):
	enabled = is_enabled

	# Bail out if we can't find the audio source
	if(audio == null && audio_path != ""):
		audio = get_node(audio_path)
	elif(audio_path == ""):
		return


	if(is_enabled):
		play()
		audio.play()
		visible = true
		pass
	else:
		# Stop the animation
		stop()
		# Audio.stop is not called because it will automatically end after the next play via WaitToPlay enable check
		visible = false
		pass
	pass


func Play():
	if(enabled):
		audio.play()
		play()
		pass


	pass

func WaitToPlay():
	if(timer.time_left > 0):
		timer.stop()
		pass
	timer.start(delay_time)
	pass

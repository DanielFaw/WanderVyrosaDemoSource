extends Spatial


export(Array,NodePath) var audios_fade_out

export(Array,NodePath) var audios_fade_in

export(Array,float) var fade_in_volumes

var in_tween

var out_tween


export var default_fade_time:float = 1.0


func _ready():
	in_tween = Tween.new()
	add_child(in_tween)

	out_tween = Tween.new()
	add_child(out_tween)
	pass


func SetFadeData(audios_in:Array, audios_out:Array, in_end_volumes:Array,default_time):
	audios_fade_in = audios_in
	audios_fade_out = audios_out
	fade_in_volumes = in_end_volumes
	default_fade_time = default_time
	pass

func StartCrossFade(fade_time=1.0,fade_out_offset=0.0):

	if(audios_fade_in == [] && audios_fade_out == []):
		return


	for aud in audios_fade_out:
		if(get_node(aud) != null):
			out_tween.interpolate_property(get_node(aud),"volume_db",null,-100,fade_time + fade_out_offset,Tween.TRANS_LINEAR,Tween.EASE_IN)
		pass

	for i in range(audios_fade_in.size()):

		var audio_node = get_node(audios_fade_in[i])
		if(!audio_node.is_playing()):
			audio_node.volume_db = -50
			audio_node.play()
			pass
			in_tween.interpolate_property(audio_node,"volume_db",null,fade_in_volumes[i],fade_time,Tween.TRANS_LINEAR,Tween.EASE_IN)
		pass


	in_tween.start()
	out_tween.start()

	while(out_tween.is_active()):
		yield(get_tree(),"idle_frame")
		pass

	for aud in audios_fade_out:
		if(aud == null):
			break
		else:
			if(get_node(aud) != null): 
				get_node(aud).playing = false
		pass
	pass

func _exit_tree():
	in_tween.stop_all()
	out_tween.stop_all()

	pass

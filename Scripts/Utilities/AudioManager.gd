extends Node

var audio_bus_ranges = {}


func _init():
	SetAudioBusRanges()
	var _connection_results = RuntimeSettings.connect("settings_changed",self,"ApplyAudioSettings")
	pass


func _exit_tree():
	if(RuntimeSettings.is_connected("settings_changed",self,"ApplyAudioSettings")):
		RuntimeSettings.disconnect("settings_changed",self,"ApplyAudioSettings")
		pass

	pass


# Set customizable ranges for audio bus levels
func SetAudioBusRanges():
	audio_bus_ranges["SFX"] = Vector2(-60.0,0.0)
	audio_bus_ranges["Music"] = Vector2(-60.0,0.0)
	audio_bus_ranges["Master"] = Vector2(-60.0,0.0)
	
# Set audio bus volumes based on range of "tuned" values
func ApplyAudioSettings():
	var main_volume = RuntimeSettings.GetSetting("volume_main")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),lerp(audio_bus_ranges["Master"].x,audio_bus_ranges["Master"].y,main_volume/100.0))

	var sfx_volume = RuntimeSettings.GetSetting("volume_sfx")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),lerp(audio_bus_ranges["SFX"].x,audio_bus_ranges["SFX"].y,sfx_volume/100.0))

	var music_volume = RuntimeSettings.GetSetting("volume_music")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),lerp(audio_bus_ranges["Music"].x,audio_bus_ranges["Music"].y,music_volume/100.0))

	pass
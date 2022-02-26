extends Control

export var resolution_dropdown_path:NodePath
var resolution_dropdown:OptionButton

export (Dictionary) var graphics_settings_inputs
export (Dictionary) var audio_settings_inputs
export (Dictionary) var control_settings_inputs

signal settings_closed


func _ready():
	resolution_dropdown = get_node(resolution_dropdown_path)
	PopulateResolutionChoices()
	#visible = false
	pass


func ApplySettings():
	#print("For now pretend that the settings were applied ;)")
	# TODO: (Ethan) Gather all settings and apply/save them
	GatherAndUpdateGraphicsSettings()
	GatherAndUpdateAudioSettings()
	GatherAndUpdateControlSettings()
	RuntimeSettings.ApplyAndSaveSettings()
	pass


func PopulateResolutionChoices():
	resolution_dropdown.add_item("2560x1440",0)
	resolution_dropdown.add_item("1920x1080",1)
	resolution_dropdown.add_item("1280x720", 2)
	resolution_dropdown.add_item("1024x600", 3)
	
	print(str(OS.get_window_size().x) + "," + str(OS.get_window_size().y))
	pass


func OpenSettings():
	UpdateGraphicsSettingsDisplay()
	UpdateAudioSettingsDisplay()
	UpdateControlSettingsDisplay()
	visible = true
	pass


# Take in new graphics settings value and update RuntimeSettings.gd(singleton)
func GatherAndUpdateGraphicsSettings():

	# Graphics Settings
	RuntimeSettings.UpdateSetting("use_vsync",get_node(graphics_settings_inputs["vsync"]).pressed)
	RuntimeSettings.UpdateSetting("fullscreen",get_node(graphics_settings_inputs["fullscreen"]).pressed)

	var resolution = get_node(graphics_settings_inputs["resolution"]).get_selected_id()

	# Match the selected WINDOWED resolution
	match(resolution):
		0:
			RuntimeSettings.UpdateSetting("resolution_x",2560)
			RuntimeSettings.UpdateSetting("resolution_y",1440)
			pass
		1:
			RuntimeSettings.UpdateSetting("resolution_x",1920)
			RuntimeSettings.UpdateSetting("resolution_y",1080)
			pass
		2:
			RuntimeSettings.UpdateSetting("resolution_x",1280)
			RuntimeSettings.UpdateSetting("resolution_y",720)
			pass
		3:
			RuntimeSettings.UpdateSetting("resolution_x",1024)
			RuntimeSettings.UpdateSetting("resolution_y",600)
		_:
			# Just leave the settings as is
			pass

	pass


# Match the UI with the currently selected settings (graphics)
func UpdateGraphicsSettingsDisplay():
	# TODO: Ethan
	#print(RuntimeSettings.GetSetting("use_vsync") )
	get_node(graphics_settings_inputs["vsync"]).pressed = RuntimeSettings.GetSetting("use_vsync")
	get_node(graphics_settings_inputs["fullscreen"]).pressed = RuntimeSettings.GetSetting("fullscreen")

	# TODO: This will probably be changed to a nested match when more resolutions are supported
	#          cuz this just feels dirty :(
	if(RuntimeSettings.GetSetting("resolution_x") == 2560 && RuntimeSettings.GetSetting("resolution_y") == 1440):
		get_node(graphics_settings_inputs["resolution"]).select(0)
		pass
	elif(RuntimeSettings.GetSetting("resolution_x") == 1920 && RuntimeSettings.GetSetting("resolution_y") == 1080):
		get_node(graphics_settings_inputs["resolution"]).select(1)
		pass
	elif(RuntimeSettings.GetSetting("resolution_x") == 1280 && RuntimeSettings.GetSetting("resolution_y") == 720):
		get_node(graphics_settings_inputs["resolution"]).select(2)
		pass
	elif(RuntimeSettings.GetSetting("resolution_x") == 1024 && RuntimeSettings.GetSetting("resolution_y") == 600):
		get_node(graphics_settings_inputs["resolution"]).select(3)
		pass

	pass


func GatherAndUpdateAudioSettings():
	RuntimeSettings.UpdateSetting("volume_main",get_node(audio_settings_inputs["main_volume"]).GetCurrentValue())
	RuntimeSettings.UpdateSetting("volume_sfx",get_node(audio_settings_inputs["sfx_volume"]).GetCurrentValue())
	RuntimeSettings.UpdateSetting("volume_music",get_node(audio_settings_inputs["music_volume"]).GetCurrentValue())
	pass


#  Match the UI with the currently selected settings (audio)
func UpdateAudioSettingsDisplay():
	# TODO: Ethan
	get_node(audio_settings_inputs["main_volume"]).SetSliderValue(RuntimeSettings.GetSetting("volume_main"));
	get_node(audio_settings_inputs["sfx_volume"]).SetSliderValue(RuntimeSettings.GetSetting("volume_sfx"));
	get_node(audio_settings_inputs["music_volume"]).SetSliderValue(RuntimeSettings.GetSetting("volume_music"));
	pass


func UpdateControlSettingsDisplay():
	get_node(control_settings_inputs["mouse_sensitivity_x"]).SetSliderValue(RuntimeSettings.GetSetting("mouse_sensitivity_horiz"))
	get_node(control_settings_inputs["mouse_sensitivity_y"]).SetSliderValue(RuntimeSettings.GetSetting("mouse_sensitivity_vert"))
	pass


func GatherAndUpdateControlSettings():
	RuntimeSettings.UpdateSetting("mouse_sensitivity_horiz",get_node(control_settings_inputs["mouse_sensitivity_x"]).GetCurrentValue())
	RuntimeSettings.UpdateSetting("mouse_sensitivity_vert",get_node(control_settings_inputs["mouse_sensitivity_y"]).GetCurrentValue())
	pass


func SettingsClosed():
	emit_signal("settings_closed")
	visible = false
	pass

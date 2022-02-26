extends Node

func _init():
	var _connection_result = RuntimeSettings.connect("settings_changed",self,"UpdateGraphicsSettings")
	if(OS.is_debug_build()):
		OS.window_resizable = true
		pass
	else:
		OS.window_resizable = false
		pass
	pass


func _exit_tree():
	if(RuntimeSettings.is_connected("settings_changed",self,"UpdateGraphicsSettings")):
		RuntimeSettings.disconnect("settings_changed",self,"UpdateGraphicsSettings")
		pass
	pass


func UpdateGraphicsSettings():
	print("Updating Graphics Settings")

	OS.set_use_vsync(RuntimeSettings.GetSetting("use_vsync"))
	OS.set_window_fullscreen(RuntimeSettings.GetSetting("fullscreen"))
	if(!RuntimeSettings.GetSetting("fullscreen")):
		#if(OS.get_screen_size().x > RuntimeSettings.GetSetting("resolution_x") || OS.get_screen_size().y > RuntimeSettings.GetSetting("resolution_y")):
		#	OS.set_window_maximized(true)
		#	pass
		#else:
		#	OS.set_window_maximized(false)
		#	pass

		OS.set_window_size(Vector2(RuntimeSettings.GetSetting("resolution_x"),RuntimeSettings.GetSetting("resolution_y")))
		pass

		OS.set_window_maximized(false)
	
	pass


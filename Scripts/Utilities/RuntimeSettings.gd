extends Node

const SETTINGS_LOCATION = "user://settings.dat"

# The currently applied settings (that will be saved when SaveSettings is called)
var json_settings:Dictionary

# A 'buffer' for any modifications to settings during runtimes
var updated_settings:Dictionary

# The default settings (THIS SHOULD NOT BE CHANGED AFTER IT'S INITIALIZED)
var default_settings:Dictionary = {}

signal settings_changed

# Save paths for different platforms
#
# Windows: %APPDATA%\Godot\
# macOS: ~/Library/Application Support/Godot/
# Linux: ~/.local/share/godot/
#
# Source: https://docs.godotengine.org/en/3.4/tutorials/io/data_paths.html

func _init():
	_InitializeDefaults()

	#_WriteDefaultSettings()
	var settings_file = File.new()
	if(settings_file.file_exists(SETTINGS_LOCATION)):
		print("SETTINGS FILE EXISTS!")
		_LoadSettings()
		pass
	else:
		_WriteDefaultSettings()
		json_settings = default_settings
		pass
	pass

	
func _ready():
	# Set default settings (or loaded ones if present)
	emit_signal("settings_changed")
	updated_settings = json_settings

	pass


# Set the default setting values
func _InitializeDefaults():
	#default_settings = {}
	default_settings["mouse_sensitivity_vert"] = 50
	default_settings["mouse_sensitivity_horiz"] = 50
	default_settings["resolution_x"] = 1280
	default_settings["resolution_y"] = 720
	default_settings["use_vsync"] = false
	default_settings["fullscreen"] = false
	default_settings["volume_main"] = 100.0
	default_settings["volume_music"] = 100.0
	default_settings["volume_sfx"] = 100.0
	default_settings["username"] = "Unnamed Crewmate"
	pass


# Write the default settings
func _WriteDefaultSettings():
	var settings_file = File.new()
	var open_result = settings_file.open(SETTINGS_LOCATION,File.WRITE)

	if(open_result != OK):
		print("Error writing default settings..")
		print(open_result)
		json_settings = default_settings
		return
	
	# Convert dictionary to string and store
	settings_file.store_string(JSON.print(default_settings,"\t"))

	#print("Saved default settings!")
	settings_file.close()
	pass


# Get the value of a runtime setting
func GetSetting(key:String):
	if(json_settings.has(key)):
		return json_settings[key]

	# Try to return the default setting instead
	elif(default_settings.has(key)):
		return default_settings[key]
		pass
	else:
		printerr("Runtime setting " + str(key) + " does not exist!")
		print_stack()
		return null
	
	pass


# Reset all settings to default, then reload settings
func ResetToDefault():
	_WriteDefaultSettings()
	_LoadSettings()
	pass


# Save the current settings
func SaveSettings():

	var settings_file = File.new()
	var open_result = settings_file.open(SETTINGS_LOCATION,File.WRITE)

	if(open_result != OK):
		print("COULD NOT OPEN SETTINGS FILE TO SAVE")
		return
	else:
		print("Settings file Saved Successfully!")
		#print(JSON.print(json_settings,"\t"))

	# Convert dictionary to string and store
	settings_file.store_string(JSON.print(json_settings,"\t"))

	#print("Saved default settings!")
	settings_file.close()

	pass


# Update a setting in the current settings dictionary
func UpdateSetting(setting_name:String, new_value):
	if(updated_settings.has(setting_name)):
		updated_settings[setting_name] = new_value
		pass
	else:
		if(OS.is_debug_build()):
			print("Runtime setting " + str(setting_name) + " does not exist!")
			print_stack()
		pass
	
	pass

# Set the current settings and notify any listeners to update and apply new settings
func ApplyAndSaveSettings():
	#print(JSON.print(updated_settings,"\t"))
	json_settings = updated_settings


	#print("----vvvvvvvvvvvv----")
	#print(JSON.print(updated_settings,"\t"))
	#print("----^^^^----")
	
	SaveSettings()
	emit_signal("settings_changed")
	pass


# Load the last saved settings (or default)
func _LoadSettings():
	if(OS.is_debug_build()):
		print("Loaded runtime settings")
		pass
	# Open a file for reading
	var settings_file = File.new()
	var open_result = settings_file.open(SETTINGS_LOCATION,File.READ)

	# If the settings couldn't be loaded, revert to the default settings
	if(open_result != OK):
		print("ERROR LOADING SETTINGS FILE")
		print(open_result)
		json_settings = default_settings
		return

	# Get the text content as a file
	var _string_contents = settings_file.get_as_text()
	json_settings = JSON.parse(_string_contents).result
	

	settings_file.close()
	pass

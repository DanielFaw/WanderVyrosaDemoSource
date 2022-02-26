extends Node

var scene_index = preload("res://CustomResources/SceneIndex.tres")
var default_scene = "homeShip"

# The name of the currently active scene
var active_scene_name = ""

# The active scene OBJECT and arguments the scene was loaded with
var active_scene_args = {}
var active_scene

# Object and name of the "loading" scene
var loader_scene_name = "loading"
var loading_scene

var max_poll_time = 0.1

# The loader object for the current scene
var scene_loader


signal current_scene_changed(new_scene_name)


const mat_cache = preload("res://Scenes/MatCache.tscn")

func _ready():
	var cache = mat_cache.instance()
	add_child(cache)
	cache.global_transform.origin = Vector3(1000,1000,1000)
	pass

# Load a new scene with a desired 
func LoadScene(new_scene:String, load_args:Dictionary={}):

	# Show "loading" scene
	#yield(get_tree().create_timer(1),"timeout")
	
	var currently_loaded_scene = get_tree().get_current_scene()
	
	#print(currently_loaded_scene.name)

	# Start loading the desired scene
	scene_loader = ResourceLoader.load_interactive(scene_index.GetScenePath(new_scene))
	
	if(scene_loader == null):
		print("SCENE LOADER ERROR ")
		pass
	else:

		# Disable process and physics
		set_process(false)
		set_physics_process(false)

		
		# Delete the "old" scene
		currently_loaded_scene.queue_free()
		

		# Show or create the "loading" scene
		if(loading_scene == null):
			loading_scene = load(scene_index.GetScenePath(loader_scene_name)).instance()
			get_tree().get_root().add_child(loading_scene)
			pass
		else:
			loading_scene.visible = true
			pass
		
		# Wait until the current scene has been fully deleted
		while is_instance_valid(currently_loaded_scene):
			yield(get_tree(),"idle_frame")
			pass

		# Clear all scene resources
		SceneResources.FlushResources()

		# Set data for the scene
		active_scene_name = new_scene
		active_scene_args = load_args

		# Start processing
		set_process(true)
		set_physics_process(true)
		pass
	pass


func _process(_delta: float):

	# Disable processing if scene loader is null
	if(scene_loader == null):
		set_process(false)
		return

	var t = OS.get_ticks_msec()

	while OS.get_ticks_msec() < t + max_poll_time:

		var error = scene_loader.poll()

		# The loader has finished
		if(error == ERR_FILE_EOF):
			var loaded_scene = scene_loader.get_resource()
			
			scene_loader = null
			_SetNewScene(loaded_scene)
			return

		# Loader is still working but hasnt thrown an error
		elif( error == OK):
			var load_progress = float(scene_loader.get_stage())/scene_loader.get_stage_count()
			#print("Scene load progress: " + str(load_progress))
			loading_scene.SetLoadProgress(load_progress)
			pass
		else:
			print(error)
			scene_loader = null
			break

	pass


func GetActiveSceneArgs():
	return active_scene_args
	pass

func HideLoadingScene():
	# Unshow the loading scene
	loading_scene.visible = false
	loading_scene.queue_free()
	loading_scene = null
	

	# Update that we have switched scenes
	emit_signal("current_scene_changed",active_scene_name)

	# Remove the loading scene hide trigger
	if(active_scene.is_connected("ready",self,"HideLoadingScene")):
		active_scene.disconnect("ready",self,"HideLoadingScene")
	pass

func GetCurrentSceneName():
	return active_scene_name
	pass

func _SetNewScene(new_scene):
	# Create an instance of the new scene
	active_scene = new_scene.instance()

	# Wait until the current scene is ready to hide the loading scene
	#	to prevent the scene from being shown too soon (i.e before the camera has been placed/initialized)
	active_scene.connect("ready",self,"HideLoadingScene")

	#print_debug("Loader waiting for ready call...")
	get_tree().get_root().add_child(active_scene)
	get_tree().set_current_scene(active_scene)

	#if(!active_scene.is_connected("ready",self,"HideLoadingScene")):
	#	HideLoadingScene()
	#	pass

	pass

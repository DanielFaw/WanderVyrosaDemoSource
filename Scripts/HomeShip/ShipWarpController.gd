extends Node

export var skip_landing_cutscene = false

var is_ready = false

func _ready():
	var _null = SceneResources.GetResource("NavigationManager").connect("new_planet_queued",self,"SetActive")
	pass

func SetActive(_new_planet_id):
	self.visible = true
	is_ready = true
	pass

func _OnBodyEnter(new_body):
	if(new_body is PlayerController):
		if(is_ready):
			var queued_planet = SceneResources.GetResource("NavigationManager").GetQueuedPlanetData()
			var scene_args ={
				"current_planet_id":    queued_planet.GetPlanetId(),
				"current_planet_seed":  queued_planet.GetPlanetSeed(),
				"planet_is_last":       SceneResources.GetResource("NavigationManager").GetPlanetIsLast()
			}

			if(skip_landing_cutscene):
				scene_args["landing_skip"] = true
				pass

			SceneManager.LoadScene("mainWorld",scene_args)
			pass
	pass

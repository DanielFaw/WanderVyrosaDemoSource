extends Node


var amount_planets_completed:int = 0

var amount_systems_completed:int = 0

var current_difficulty:float = 1


var difficulty_increase_per_planet:float = 0.5
var difficulty_increase_per_system:float = 5


var tutorial_viewed = false
var navigation_viewed = false
var upgrades_viewed = false

# Used to generate a new system once the previous system has been completed
var last_completed_planet_seed = -1

# The rng seed of the current planet
var current_system_seed

# An array of the completed planet ids in the current system
var planets_complete = []

var regenrate_new_system:bool = false

var currency_bank : int = 0
var base_money_per_planet : int = 6
var base_money_per_system : int = 8

var upgrades_have_been_initialized = false

 # TODO: Check this
#signal checkpoint_updated(checkpoint_name)

func _ready():
	var _connection = SceneManager.connect("current_scene_changed",self,"OnSceneSwitch")
	
	pass

# Reset the players run progression
func ResetProgression():
	regenrate_new_system = false
	upgrades_have_been_initialized = false
	planets_complete = []
	current_system_seed = -1
	last_completed_planet_seed = -1


	amount_planets_completed = 0
	amount_systems_completed = 0
	current_difficulty = 1

	# Reset checkpoints
	tutorial_viewed = false
	navigation_viewed = false
	upgrades_viewed = false

	pass


func SetCheckpointBool(name:String,value:bool):

	match(name):
		"tutorial_viewed":
			tutorial_viewed = value
			pass
		"navigation_viewed":
			navigation_viewed = value
			pass
		"upgrades_viewed":
			print("SET")
			upgrades_viewed = value
			pass
		_:
			return
	pass

# Get the amount complete in the system
func GetPlanetsCompleteInSystem():
	return planets_complete.size()
	pass

func GetCheckpointBool(name):
		match(name):
			"tutorial_viewed":
				return tutorial_viewed
				pass
			"navigation_viewed":
				return navigation_viewed
				pass
			"upgrades_viewed":
				return upgrades_viewed
				pass
			_:
				return 0
		pass

func _exit_tree():
	if(SceneManager.is_connected("current_scene_changed",self,"OnSceneSwitch")):
		SceneManager.disconnect("current_scene_changed",self,"OnSceneSwitch")
		pass

# Accessor for the current difficulty
func GetCurrentDifficulty():
	return current_difficulty
	pass

func GetBankAmount() -> int:
	var ret = currency_bank
	currency_bank = 0
	return ret

func GetLastPlanetCompletedID():
	
	if(planets_complete.size() > 0):
		return planets_complete.back()
	else:
		return - 1
	pass

func PlanetComplete(planet_id,is_last_planet = false):
	# TODO: Connect to signal of game manager
	planets_complete.push_back(planet_id)
	last_completed_planet_seed = planet_id
	current_difficulty += difficulty_increase_per_planet
	amount_planets_completed += 1
	
	#Monie
	currency_bank += clamp(base_money_per_planet + amount_planets_completed, 1, 10)

	if(is_last_planet):
		SystemComplete()
		pass
	pass

func OnSceneSwitch(new_scene_name):
	if(new_scene_name == "homeShip"):
		CheckSystemGeneration()
		pass
	pass

# Check if a new system should be generated
func CheckSystemGeneration():
	if(current_system_seed == null):
		# Seed the generation of a new system
		var rng = RandomNumberGenerator.new()
		rng.randomize()

		var new_system_seed = rng.randi()
		SceneResources.GetResource("SystemGenerator").GenerateSystem(new_system_seed)
		SetCurrentSystemData(new_system_seed)

		# DEBUG
		#SceneResources.GetResource("SystemGenerator").GetPlanetData(0).SetPlanetComplete(true)
		pass

	# Generate a new system using the last 
	elif(regenrate_new_system):
		current_system_seed = last_completed_planet_seed
		SceneResources.GetResource("SystemGenerator").GenerateSystem(last_completed_planet_seed)
		regenrate_new_system = false

		pass
	else:
		# System is 'in progress'
		SceneResources.GetResource("SystemGenerator").GenerateSystem(current_system_seed)
		SceneResources.GetResource("SystemGenerator").SetCompletedPlanets(planets_complete)
		pass
	pass

# Returns the number of planets completed in the current run
func GetAmountPlanetsCompleted():
	return amount_planets_completed
	pass
func GetAmountSystemsCompleted():
	return amount_systems_completed
	pass

# Set the data for the current system
#   Will mostly likely only be used for save game loading
func SetCurrentSystemData(new_system_seed,completed_planets=[]):
	current_system_seed = new_system_seed
	planets_complete = completed_planets
	pass


# Mark the system as complete and flag the system generator to create a new system 
func SystemComplete():
	# TODO: Connect to signal of system manager(?)
	current_difficulty += difficulty_increase_per_system
	
	amount_systems_completed += 1
	
	currency_bank += (amount_systems_completed * base_money_per_system) + 7
	
	planets_complete = []
	
	regenrate_new_system = true
	pass

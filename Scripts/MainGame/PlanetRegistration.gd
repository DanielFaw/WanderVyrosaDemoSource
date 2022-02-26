extends Spatial

var planet_resource_abundance = {}


# Used as the 'mean' (0.0 -> 1.0) when calculating vertical placement distribution and vein density
#	Higher = closer to player base
var planet_mid_vein_position = 0.8

# Used as the 'std deviation' (0.0 -> 1.0) when calculating vertical placement distribution and vein density
var planet_vein_deviation = 0.3

const RESOURCE_TYPE = preload("res://Scripts/MainGame/ResourceType.gd")

func _init():
	SceneResources.RegisterResource("Planet",self)
	SetPlanetVariables()

	pass

func SetResourceAbundance(var abundanceDict):
	planet_resource_abundance = abundanceDict
	pass

# Set the plnet variables from the scene arguments
func SetPlanetVariables():

	var planet_variables 
	if(SceneManager.GetActiveSceneArgs() == null):
		planet_variables = SceneManager.GetActiveSceneArgs()["planet_variables"]
		pass


	if(planet_variables != null):
		planet_resource_abundance[RESOURCE_TYPE.TYPE.Metal] = planet_variables["metal_abundance"]
		planet_resource_abundance[RESOURCE_TYPE.TYPE.Quartz] = planet_variables["quartz_abundance"]
		planet_resource_abundance[RESOURCE_TYPE.TYPE.Silicon] = planet_variables["silicon_abundance"]
		planet_resource_abundance[RESOURCE_TYPE.TYPE.BoomStone] = planet_variables["boomstone_abundance"]
		planet_mid_vein_position = planet_variables["mid_vein_pos"]
		planet_vein_deviation = planet_variables["vein_pos_deviation"]
	else:
		# Set default abundance for testing
		# Addition of all needs to be <= 1.0
		planet_resource_abundance[RESOURCE_TYPE.TYPE.Metal] = 0.31
		planet_resource_abundance[RESOURCE_TYPE.TYPE.Quartz] = 0.21
		planet_resource_abundance[RESOURCE_TYPE.TYPE.Silicon] = 0.2
		planet_resource_abundance[RESOURCE_TYPE.TYPE.BoomStone] = 0.3

	pass

# Just get the whole dictionary describing planet resources
func GetPlanetResourceAbundance():
	return planet_resource_abundance.duplicate()
	pass

# Get a dictionary {mean,dev} describing the resource vein spawn parameters
func GetPlanetResourceSpawnParams():
	return {"mean":planet_mid_vein_position, "dev":planet_vein_deviation}
	pass


# Get the percentage of a given resource's abundance on this planet (between 0.1 and 1.0)
func GetResourceAbundance(var resource_type):
	if(planet_resource_abundance.has(resource_type)):
		return planet_resource_abundance[resource_type]
		pass
	pass



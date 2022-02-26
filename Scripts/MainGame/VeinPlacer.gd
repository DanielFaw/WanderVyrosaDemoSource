extends Spatial

export var amount_to_place:int = 0

export var horizontal_path_finding_resolution:int = 20
export var vertical_path_finding_resolution:int = 15

var vertical_no_place
var horizontal_no_place

const RESOURCE_TYPE = preload("res://Scripts/MainGame/ResourceType.gd")

export(Dictionary) var vein_prefabs


export var density_curve:Curve

# The rarity of each ore from greatest -> least
var ordered_rarity = []
var breakpoint_values = [0, 0, 0, 0]
var total_shares

# The planet resource distribution
var planet_resource_distribution:Dictionary


# The rarity of each resource keyed to the type
var rarity_to_resource:Dictionary

# Used as the 'mean' (0.0 -> 1.0) when calculating vertical placement distribution and vein density
#	Higher = closer to player base
var vein_mid_spawn_height = 0.8

# Used as the 'std deviation' (0.0 -> 1.0) when calculating vertical placement distribution and vein density
var vein_spawn_deviation = 0.3


func _ready():
	# Calculate the deltas the node generation uses
	#		to avoid placing veins there
	vertical_no_place = PI/ float(vertical_path_finding_resolution);
	horizontal_no_place =  (2.0 * PI) / float(horizontal_path_finding_resolution)

	GetPlanetaryPlacementVariables()
	PlaceVeins()

	pass

# Place ore veins
func PlaceVeins():
	for _i in range(amount_to_place):

		# TODO: Make randomization parameters settable per planet
		var normal_rand = Utilities.GetNormalRandomValue(vein_mid_spawn_height,vein_spawn_deviation);
		var theta = normal_rand * ((float(PI) - 0.5) - 0.5)
		var phi = Utilities.GetRandomValue(2.0 * float(PI),0);


		# Calculate new density using the theta value (placement height)
		#   Veins closer to the enemy base will have a higher density/ yield per tick
		var new_density = density_curve.interpolate( 1.0 - inverse_lerp(0.5,float(PI) - 0.5,theta)) + Utilities.GetRandomValue(0.3, 0)
		#new_density = Utilities.GetRandFloat(0.3, density_curve.interpolate( 1.0 - inverse_lerp(0.5,float(PI) - 0.5,theta)))
		if(fmod(theta,vertical_no_place) == 0):
			theta += vertical_no_place / 2.0
			pass

		if(fmod(phi, horizontal_no_place) == 0):
			phi += horizontal_no_place / 2.0
			pass


		var rand = Utilities.GetRandomValue(total_shares,0.0)
		var new_location = Utilities.SphericalCoordToCartesian(18.1,theta,phi)


		# Determine which one should be created and spawn it
		if(rand >= 0 && rand <= breakpoint_values[0]):
			#Spawn first resource
			call_deferred("CreateVein",new_density,rarity_to_resource[ordered_rarity[0]],new_location)
			pass
		elif (rand <= breakpoint_values[1]):
			#Spawn second resource
			call_deferred("CreateVein",new_density,rarity_to_resource[ordered_rarity[1]],new_location)
			pass
		elif (rand <= breakpoint_values[2]):
			#Spawn third resource
			call_deferred("CreateVein",new_density,rarity_to_resource[ordered_rarity[2]],new_location)
			pass
		else:
			#Spawn the last resource
			call_deferred("CreateVein",new_density,rarity_to_resource[ordered_rarity[3]],new_location)
			pass

		pass

	print("Veins Generated")
	return
	pass


# Get the needed placement information from the planet resource
func GetPlanetaryPlacementVariables():

	# TODO: Set distribution mean/deviation
	planet_resource_distribution = SceneResources.GetResource("Planet").GetPlanetResourceAbundance()
	
	# Reverse the planet_resource_distribution dictionary so resources can be looked up by their rarity
	for resource in planet_resource_distribution.keys():
		rarity_to_resource[planet_resource_distribution[resource]] = resource
		pass

	# Create an ordered list of the resource rarity from greatest -> least
	ordered_rarity = rarity_to_resource.keys()
	print(ordered_rarity)
	ordered_rarity.sort()
	print(ordered_rarity)
	ordered_rarity.invert()
	
	breakpoint_values[0] = ordered_rarity[0]
	breakpoint_values[1] = ordered_rarity[0] + ordered_rarity[1]
	breakpoint_values[2] = ordered_rarity[0] + ordered_rarity[1] + ordered_rarity[2]
	breakpoint_values[3] = ordered_rarity[0] + ordered_rarity[1] + ordered_rarity[2] + ordered_rarity[3]
	total_shares = breakpoint_values[3]

	# Random distribution variables
	var spawn_params = SceneResources.GetResource("Planet").GetPlanetResourceSpawnParams()
	vein_mid_spawn_height = spawn_params["mean"]
	vein_spawn_deviation = spawn_params["dev"]

	pass

	
func CreateVein(density:float, type_int:int,new_location:Vector3):

	# TODO: Add the vein prefabs to the resource lookup
	var vein_to_create = vein_prefabs[type_int]

	var new_vein = vein_to_create.instance()
	var local_up = Utilities.CalculateGravityDirection(new_location)
	add_child(new_vein)

	new_vein.global_transform.origin = new_location
	new_vein.global_transform = Utilities.AlignWithNormal(new_vein.global_transform,local_up)
	new_vein.SetDensity(density)

	pass

	

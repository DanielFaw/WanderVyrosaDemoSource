extends Node

const SYSTEM_PLANET = preload("res://Scripts/HomeShip/SystemPlanet.gd")

var system_generator_seed:int

# A dictionary containing all planets in the system 
# 	 	int (system_id) -> Planet
var current_system:Dictionary = {}

# How many columns of planets there are (including start/end)
#  i.e 4 columns is a start and end planet with 2 columns of planets in between
var columns = 4

var max_planets_per_column:int = 3

# A dictionary of each "column" in the system
#		int (column number) -> int[] (planet ids)
var system_columns:Dictionary = {}

# The RNG specifically for generating systems and planet seeds
#  	*SHOULD* provide deterministic result
var rng = RandomNumberGenerator.new()

var generated_planets = 0

var system_complete:bool = false

signal new_system_generated

func _init():
	SceneResources.RegisterResource("SystemGenerator",self)
	pass

func _ready():
	#yield(get_tree().create_timer(0.3),"timeout")
	#GenerateSystem("ooga booga".hash())
	#GenerateSystem(Utilities.GetRandInt(0,1000000))
	#TracePathThroughSystem()
	pass

# TODO: Probably return new system as a dictionary??
# Generate a new system with a given seed
func GenerateSystem(system_seed:int):
	system_generator_seed = system_seed
	rng.seed = system_generator_seed
	system_columns = {}
	current_system = {}


	# Initialize columns
	for i in range(columns):
		system_columns[i] = []
		pass
	
	# Generate start planet
	if(!system_columns.has(0)):
		system_columns[0] = []
		pass
	system_columns[0].push_back(GenerateNewPlanet())


	# Generate `middle` planets
	for c in range(columns - 2):
		var planets_in_column = rng.randi_range(1,max_planets_per_column)
		#print(planets_in_column)

		# Generate all planets in the column
		for _i in range(planets_in_column):
			## Initialize column if it hasn't already
			#if(!system_columns.has(c+1)):
			#	system_columns[c+1] = []
			#	pass
			# Add to system column
			var new_planet_id = GenerateNewPlanet()
			system_columns[c+1].push_back(new_planet_id)
			#print(system_columns[c+1])
			pass

		#print("---------------------------")
		pass


	# Generate end planet
	if(!system_columns.has(columns-1)):
		system_columns[columns-1] = []
		pass

	system_columns[columns-1].push_back(GenerateNewPlanet())


	#print("System columns",system_columns)

	# ------------------ GENERATE PATHS ------------------
	# First, connect one planet from each column to guarantee there is a path through the system

	var from_planet_id = 0
	for c in range(columns-1):
		var next_column = c + 1

		var random_next_planet_column_index = rng.randi_range(0,system_columns[next_column].size() -1)
		var random_planet_in_next_id = system_columns[next_column][random_next_planet_column_index]

		#print("Connecting " + str(from_planet_id) + " to " + str(random_planet_in_next_id))

		# Connect the systems to each other (bi-directional)
		current_system[from_planet_id].ConnectPlanet(random_planet_in_next_id)
		current_system[random_planet_in_next_id].ConnectPlanet(from_planet_id)

		# Set the 'next' planet id as the one continuing to go forward
		from_planet_id = random_planet_in_next_id
		pass


	# Next, pick a random number of planets to connect, then connect them to a planet in the next column
	for c in range(1,columns-1):
		var next_column = c + 1

		# How many planets in the current system should we connect
		var planets_to_connect = rng.randi_range(0, system_columns[c].size()-1)
		var current_column_planets = system_columns[c]

		# For each planet to connect, connect to a random planet in the next column if a connection doesn't already exist
		for _pi in range(planets_to_connect):
			var planet_id_from = current_column_planets[rng.randi_range(0, system_columns[c].size()-1)]

			var planet_index_to = rng.randi_range(0, system_columns[next_column].size()-1)
			var planet_id_to = system_columns[next_column][planet_index_to]

			# If the two planets aren't currently connected, connect them!
			if(!current_system[planet_id_from].IsConnected(current_system[planet_id_to])):

				current_system[from_planet_id].ConnectPlanet(planet_id_to)
				current_system[planet_id_to].ConnectPlanet(from_planet_id)
				pass

			pass
		pass

	# Finally, allow some planets to be connected to other planets in the same column
	for c in range(columns):
		if(system_columns[c].size() > 1):

			# Figure out how many should be connected in the current column
			# 	amount is MAX because some connections may already exist
			var max_amount_to_connect = rng.randi_range(0,system_columns[c].size() -1)

			for _i in range(max_amount_to_connect):
				var planet_from_id = system_columns[c][rng.randi_range(0,system_columns[c].size() -1)]

				# Create a list of connections that this planet can connect to by removing itself from a copied array of the columns planets
				var available_connections = system_columns[c].duplicate()
				available_connections.erase(planet_from_id)

				var planet_to_id = available_connections[rng.randi_range(0,available_connections.size() -1)]

				# Connect the planets if they aren't already
				if(!current_system[planet_from_id].IsConnected(current_system[planet_to_id])):
					current_system[planet_from_id].ConnectPlanet(planet_to_id)
					current_system[planet_to_id].ConnectPlanet(planet_from_id)
					pass
				pass
			pass

	# Tell listeners a new starsytem has been generated
	emit_signal("new_system_generated")
	pass

# Generate a new planet, returning the id of the newly generated planet in the system dict
func GenerateNewPlanet():
	var new_id = generated_planets
	var planet = SYSTEM_PLANET.new(new_id)
	planet.SetPlanetSeed(rng.randf_range(0.0,100000000000))

	if(!current_system.has(new_id)):
		current_system[new_id] = planet
		generated_planets += 1
		pass
	else:
		printerr(" PLANET ID ALREADY EXISTS")
		planet.queue_free()

	# Add to the global system dictionary
	
	
	return new_id

# Returns the dictionary holding each column of planets in the system
func GetCurrentSystemColumns():
	return system_columns

# Returns a dictionary of information describing the limits of the system generation structure
#   form {"max_columns":int,"max_planets_per_column":int}
func GetGenerationStructureInformation():
	return {"max_columns":columns,"max_planets_per_column":max_planets_per_column}
	pass
	
# Returns the planet object at a given id, or null if it doesnt exist
func GetPlanetData(planet_id):
	if(current_system.has(planet_id)):
		return current_system[planet_id]
		pass
	else:
		printerr("Can't get data for planet " + str(planet_id) + " - Planet does not exist")
		print_stack()
		return null

# Get the current star system dictionary
func GetCurrentSystem():
	return current_system
	pass

# Set the planets that have been completed for each system
func SetCompletedPlanets(planets_completed:Array):
	# Loop through all complete planets and mark the objects as complete
	for pid in planets_completed:
		if(current_system.has(pid)):
			current_system[pid].SetPlanetComplete(true)
			pass
		pass
	pass

# Returns the random seed the current generation was created with
func GetSystemSeed():
	return system_generator_seed
	pass

# Returns an array of the start to finish 
func TracePathThroughSystem():
	var current_planet = current_system.keys()[current_system.keys().size() -1]

	# TODO: Find a way to trace the path recursively for debugging purposes
	#print( TracePathRecursive(current_planet) )

	pass

func TracePathRecursive(planet_id_to_trace):
	var planet = current_system[planet_id_to_trace]

	var traced_planets = []


	if(planet_id_to_trace != 0):

		if(planet.GetPlanetConnections().size() > 0):
			for i in planet.GetPlanetConnections():
				if(i != planet_id_to_trace && !traced_planets.has(i)):
					traced_planets.append(i)
					return [planet_id_to_trace].append(TracePathRecursive(i))
				pass
			pass
		pass
	else:
		return [planet_id_to_trace]
		
	pass
	

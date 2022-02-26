
# The id of this planet in the current system
var planet_id:int = -1

# Has the planet been completed yet
var is_completed:bool = false


# The planet's generation seed
var planet_seed:int = -1


# The other planet ids this planet is connected to (bi-directional)
var connections:Array =  []


# Parameterized constructor
func _init(new_planet_id):
	planet_id = new_planet_id
	is_completed = false
	pass


# Sets the planets seed used for generation of flora, veins, etc
func SetPlanetSeed(new_seed):
	planet_seed = new_seed
	pass


# Returns the planets seed used for generation of flora, veins, etc
func GetPlanetSeed():
	return planet_seed
	pass


# Set whether the planet has been complete
func SetPlanetComplete(is_complete):
	is_completed = is_complete
	pass

# Returns whether the planet has been completed
func IsPlanetComplete():
	return is_completed
	pass

# Returns an array(int) of the planet ids this planet is connected to
func GetPlanetConnections():
	return connections
	pass


# Get the id of this planet in the system
func GetPlanetId():
	return planet_id
	pass
	

# Add a planet of new_planet_id to the list of connected planets
func ConnectPlanet(new_planet_id):
	if(!connections.has(new_planet_id)):
		connections.push_front(new_planet_id)
		pass
	pass


# Remove a planet of new_planet_id to the list of connected planets
func DisonnectPlanet(planet_id_to_disconnect):
	if(connections.has(planet_id_to_disconnect)):
		connections.erase(planet_id_to_disconnect)
		pass
	pass

# Returns true if the planet of the id is connected to this planet
func IsConnected(planet_connected_id):
	return connections.has(planet_connected_id)
	pass

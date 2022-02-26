extends Spatial


export var dronePrefab:PackedScene;
export var placementSoundPrefab:PackedScene

var _maxDeployedDrones:int = 4
var _currentlyDeployedDrones:int = 0

var _buildQueue = []

var _builtTowers = {}
var _towerAmountBuilt = 0

export var death_particles_prefab : PackedScene

var drone_stats = preload("res://CustomResources/UpgradableStats/BuildingController_Stats.tres")

export var droneSpawnPointPath:NodePath
var droneSpawnPoint:Position3D

func _init():
	SceneResources.RegisterResource("TowerManager",self)

func _ready():
	droneSpawnPoint = get_node(droneSpawnPointPath)
	
	#Get the max allowed amount of drones
	_maxDeployedDrones = drone_stats.GetAllStats()[TStat.DRONECOUNT]
	pass


func ReportDroneReturned():
	_currentlyDeployedDrones -=1;

	# Drone returned, check if we need to send another
	if(_ShouldDeployDrone()):
		call_deferred("_DeployDroneToTower")
		_currentlyDeployedDrones += 1
		pass

# Add tower to list of currently built towers
func ReportTowerBuilt(var builtTower):
	var idToAdd = builtTower.GetTowerInstanceID()
	if(!_builtTowers.has(idToAdd)):
		_builtTowers[idToAdd] = builtTower
		pass
	else:
		if(OS.is_debug_build()):
			print("Tower with ID " + str(idToAdd) + " already exists in the tower list!! Is something out of sync?")
			print_stack()

# Remove tower from list of currently built towers
func ReportTowerDestroyed(var builtTower):
	var idToRemove = builtTower.GetTowerInstanceID()
	if(_builtTowers.has(idToRemove)):
		_builtTowers.erase(idToRemove)
		#Spawn particles for 0.2 seconds
		
		var death_particles = death_particles_prefab.instance()
		add_child(death_particles)
		death_particles.global_transform = builtTower.global_transform
		#death_particles.
		yield (get_tree().create_timer(0.25), "timeout")
		death_particles.queue_free()
		
		pass
	else:
		if(OS.is_debug_build()):
			print("Tower with ID " + str(idToRemove) + " no longer exists in the tower list!! Is something out of sync?")
			print_stack()


# Add a tower into the queue to be built
func AddTowerToBuildQueue(var towerToAdd):
	if(!_buildQueue.has(towerToAdd)):
		_buildQueue.push_back(towerToAdd);

		# Deploy a new drone if needed
		if(_ShouldDeployDrone()):
			call_deferred("_DeployDroneToTower")
			_currentlyDeployedDrones += 1
			pass
	pass;

# Should a drone be deployed
func _ShouldDeployDrone():

	# TODO: Maybe add a way for drones to build multiple towers on a deployment
	#		Could be like a "drone battery size" upgrade so they could be deployed for longer?

	# UNCOMMENT TO TEMPORARILY DISABLE DRONES
	#return false
	if(!_buildQueue.empty() &&  _currentlyDeployedDrones < _maxDeployedDrones):
		return true
	else:
		return false
	pass;


# If possible, add a building to the world
func PlaceBuilding(towerResource,newTowerTransform,newTowerID=-1):
	var buildingToPlace = towerResource.GetTowerPrefab().instance()
	# Make model invisible until we place it
	buildingToPlace.visible = false

	# Add to scene, position, and align to surface
	get_tree().get_current_scene().add_child(buildingToPlace)
	
	# Align with visual
	buildingToPlace.global_transform = Quat(newTowerTransform.basis.orthonormalized()).slerp(newTowerTransform.basis.get_rotation_quat(),1.0)
	buildingToPlace.global_transform.origin = newTowerTransform.origin
	buildingToPlace.visible = true

	# Set new ID if its not -1 
	# TODO: Once authoritative server is implemented, remove conditional since it will ALWAYS be set by the authoritative server
	if(newTowerID != -1):
		if(buildingToPlace.has_method("SetTowerID")):
			buildingToPlace.SetTowerID(newTowerID)
			pass
		else:
			return;
		
	else:
		if(buildingToPlace.has_method("SetTowerID")):
			buildingToPlace.SetTowerID(_towerAmountBuilt)
			_towerAmountBuilt += 1
			pass
		else:
			return;
		

	var soundFX = placementSoundPrefab.instance()
	buildingToPlace.add_child(soundFX)
	
	# Register the built tower
	ReportTowerBuilt(buildingToPlace)
	pass;


# Deploy a drone to go build a tower
func _DeployDroneToTower():
	# Instance drone and set target to tower
	var towerToDeployTo = _buildQueue.pop_front()
	if(towerToDeployTo != null):
		var newDrone = dronePrefab.instance()
		get_tree().get_current_scene().add_child(newDrone)
		newDrone.global_transform.origin = droneSpawnPoint.global_transform.origin
		newDrone.call_deferred("SetTarget",towerToDeployTo)
		pass
	pass

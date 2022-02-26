extends Spatial

export var _unbuiltMaterial:Material
export var _builtMaterial:Material

export(Array,NodePath) var _meshes = [];
export(Array,NodePath) var _nonPlacementColliders = [];
export var placementColliderPath:NodePath
var placementCollider


var _towerInstanceID = 0;

const clearMask = 0b000000000000000010000

# The name of this tower in the tower index
export var towerIndexName:String = "UNDEFINED"

var buildComplete = false;

export var timeToBuild = 5.0
var buildProgress = 0.0

var build_particles_res = preload("res://Prefabs/Effects/BuildFX.tscn")

var build_particles

var build_complete_particles = preload("res://Prefabs/Effects/BuildCompleteParticles.tscn")

export var _towerMaxHealth : float
var _health : float


var entered_during_build = []

var current_damage_indicator
var damage_indicator_prefab = preload("res://Prefabs/Effects/DamageIndicator.tscn")


export var hit_audio_path:NodePath
var hit_audio

func _ready():

	# Mark this tower as needs building
	SceneResources.GetResource("TowerManager").AddTowerToBuildQueue(self)

	placementCollider = get_node(placementColliderPath)
	
	if(hit_audio_path != ""):
		hit_audio = get_node(hit_audio_path)
		pass

	_health = _towerMaxHealth
	## Apply new mesh
	for m in _meshes:
		var meshObj = get_node(m)
		if(meshObj != null):
			meshObj.set_surface_material(0,_unbuiltMaterial); 

	# Disable colliders
	for c in _nonPlacementColliders:
		var colObj = get_node(c)
		if(colObj != null):
			colObj.disabled = true
	
	# DEBUG INSTA BUILD
	#Build(timeToBuild)
	pass

func GetIndexName():
	return towerIndexName

func _OnBodyEnter(var body):
	if(body.has_method("TowerRangeEntered")):
		if(buildComplete):
			body.TowerRangeEntered(self)
		elif(!buildComplete):
			entered_during_build.push_back(body)
		pass
	pass

func _OnBodyExit(var body):
	if(body.has_method("TowerRangeExited")):
		body.TowerRangeExited(self)
		if(entered_during_build.has(body)):
			entered_during_build.erase(body)
	pass


func GetHealth():
	return _health

func GetMaxHealth():
	return _towerMaxHealth


func TakeDamage(var damageToTake):
	_SpawnDamageIndicator(damageToTake)
	if(hit_audio != null):
		hit_audio.play()
		pass


	_health -= damageToTake
	if(_health <= 0):
		_OnDeath()
		pass

func _OnDeath():
	SceneResources.GetResource("TowerManager").ReportTowerDestroyed(self)
	self.queue_free()

func GetTowerInstanceID():
	return _towerInstanceID;
	pass

func SetTowerID(newTowerID):
	_towerInstanceID = newTowerID
	pass


func Build(var deltaBuildTime):
	buildProgress += deltaBuildTime

	# Add build particles
	if(build_particles == null):
		build_particles = build_particles_res.instance()
		add_child(build_particles)
		pass

	if(buildProgress > timeToBuild):
		buildComplete = true
		#SceneResources.GetResource("TowerManager").ReportTowerBuilt(self)

		# Tell all enemies that entered during build to attack this
		for e in entered_during_build:
			if(e.has_method("TowerRangeEntered")):
				e.TowerRangeEntered(self)
				pass
			pass

		# Apply new material to mesh objects
		_SetBuiltMaterial()
		_EnableColliders()
		
		_RemoveFlora()

		# Delete the build particles
		if(build_particles != null):
			build_particles.queue_free()
			pass

		# Particle effect
		var particles = build_complete_particles.instance()
		add_child(particles)
		pass

func _EnableColliders():
	# Enable colliders
	for c in _nonPlacementColliders:
		var colObj = get_node(c)
		if(colObj != null):
			colObj.disabled = false
	pass

# Removes flora around the tower
func _RemoveFlora():
	yield(get_tree().create_timer(0.01),"timeout")
	var queryShape = PhysicsShapeQueryParameters.new()
	queryShape.transform.origin = global_transform.origin
	queryShape.set_shape(placementCollider.shape)
	queryShape.collide_with_areas = true
	queryShape.collision_mask = clearMask

	var space_state = get_world().direct_space_state
	var shapeCollisionInfo = space_state.intersect_shape(queryShape,32)

	# Remove all intersected environment/flora objects
	if(shapeCollisionInfo.size() > 0):
		for o in shapeCollisionInfo:
			o["collider"].queue_free()

	pass
func _SpawnDamageIndicator(damageTaken:float):
	#if(currentDamageIndicator == null):
	current_damage_indicator = damage_indicator_prefab.instance()
	self.add_child(current_damage_indicator)
	current_damage_indicator.SetInitialY(1.0)
	
	#print("HP percentage: " + str(_health/_towerMaxHealth))
	if(current_damage_indicator != null):
		current_damage_indicator.SetDamageText(damageTaken, _health / _towerMaxHealth)
	pass


func _SetBuiltMaterial():
	for m in _meshes:
		var meshObj = get_node(m)
		if(meshObj != null):
			meshObj.set_surface_material(0,_builtMaterial); 

	pass
		

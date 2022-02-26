extends Spatial

var _enemiesAlive = {}
const _enemyIndex = preload("res://CustomResources/R_EnemyIndex.tres")

export var enemySpawnPointPath:NodePath

var enemySpawnPoint;

var pathfindingResolution:int = 10

var towerCheckMask = 0b00000000000000000100

export var shouldSpawnEnemies = false;

var enemySpawnID = 0;

signal enemyListEmpty

func _init():
	SceneResources.RegisterResource("EnemyManager",self)
	pass

func _ready():
	_enemiesAlive.clear()
	enemySpawnPoint = get_node(enemySpawnPointPath)
	pass

# Store a new enemy with a given spawnID
func EnemySpawned(var newEnemy,var spawnID):
	if(!_enemiesAlive.has(spawnID)):
		_enemiesAlive[spawnID] = newEnemy
		# Increment spawn ID
		enemySpawnID += 1
	else:
		printerr("ENEMY OF " + str(spawnID) + " ALREADY EXISTS (" + _enemyIndex[spawnID].name + "). IS SOMETHING OUT OF SYNC?")

# Function for network manager to spawn an enemy of a specified type with a specified ID
func SpawnEnemyNetwork(var enemyName,var _spawnId):
	# Retrieve enemy from enemyIndex
	var prefab = _enemyIndex.GetEnemyPrefab(enemyName);
	if(prefab == null):
		return;
	
	# Spawn enemy and register them
	var newEnemy = prefab.instance()
	get_tree().get_current_scene().add_child(newEnemy);
	newEnemy.global_transform.origin = enemySpawnPoint.global_transform.origin
	newEnemy.global_transform = Utilities.AlignWithNormal(newEnemy.global_transform, Utilities.CalculateGravityDirection(enemySpawnPoint.global_transform.origin))

	pass;

func SpawnEnemy(var enemyName):
	var prefab = _enemyIndex.GetEnemyPrefab(enemyName);
	if(prefab == null):
		return;

	# Spawn enemy and register them

	var randomRot = Utilities.GetRandomValue(0.0,2.0 * PI)
	var newEnemy = prefab.instance()
	get_tree().get_current_scene().add_child(newEnemy);
	newEnemy.global_transform.origin = enemySpawnPoint.global_transform.origin
	newEnemy.global_transform = Utilities.AlignWithNormal(newEnemy.global_transform, Utilities.CalculateGravityDirection(enemySpawnPoint.global_transform.origin))
	
	#Slightly modify enemy health and damage
	CalculateEnemyStrength(newEnemy)
	
	newEnemy.SetSpawnID(enemySpawnID);
	# Send off in a random direction
	newEnemy.global_transform = newEnemy.global_transform.rotated(newEnemy.global_transform.basis.y.normalized(),randomRot);

	# Report that the enemy has been spawned
	EnemySpawned(newEnemy,enemySpawnID);
	pass

func CalculateEnemyStrength(var enemy):
	
	var enemy_level = clamp(pow(ProgressionManager.GetCurrentDifficulty(), 0.75), 1, 100)
	
	var random_tolerance = 0.33 #Enemies can be this much % stronger or weaker
	
	var a = 1 + Utilities.GetRandFloat(-random_tolerance, random_tolerance)
	var b = 1 + Utilities.GetRandFloat(-random_tolerance, random_tolerance)
	var c = 1 + Utilities.GetRandFloat(-random_tolerance, random_tolerance)
	var d = 1 + Utilities.GetRandFloat(-random_tolerance, random_tolerance)
	#var total = a+b+c+d
	
	var base_enemy_damage = 0.5
	var damage_increase_per_level = 0.1
	var base_enemy_attack_speed = 3.0
	var attack_increase_per_level = -0.1
	var base_enemy_health = 15.0
	var health_increase_per_level = 4.0
	var base_enemy_speed = 30.0
	var speed_increase_per_level = 0.5
	
	
	
	
	
	#Increase its damage
	var new_damage = (base_enemy_damage + damage_increase_per_level * enemy_level) * a
	new_damage = stepify(new_damage, 0.1)
	
	#Change its attack speed
	var new_attack_speed = (base_enemy_attack_speed + attack_increase_per_level * enemy_level) * b
	
	#Increase its health
	var new_health = (base_enemy_health + health_increase_per_level * enemy_level) * c
	
	#Increase its speed
	var new_speed = (base_enemy_speed + speed_increase_per_level * enemy_level) * d
	
	var params = {
		"hp" : new_health,
		"atkspd" : new_attack_speed,
		"dmg" : new_damage,
		"spd" : new_speed
	}
	
	enemy.SetStats(params)
	
	pass

func CalculateEnemyPath(var currentCartesianPos):
	var pathData = {};

	pathData["waypoints"] = SceneResources.GetResource("AStarManager").CalculatePath(currentCartesianPos, SceneResources.GetResource("PlayerBase").global_transform.origin)
	
	return pathData
	pass

# Function for network manager to delete an enemy of a specified ID
func DeleteEnemy(var enemyID):
	if(_enemiesAlive.has(enemyID)):
		_enemiesAlive[enemyID].queue_free()
		if(_enemiesAlive.empty()):
			emit_signal("enemyListEmpty")
	else:
		if(OS.is_debug_build()):
			printerr("ENEMY OF " + str(enemyID) + " DOES NOT EXIST. IS SOMETHING OUT OF SYNC?")
	pass;

# An callback for when an enemy is destroyed
func EnemyDestroyed(var destroyedEnemySpawnID):
	if(_enemiesAlive.has(destroyedEnemySpawnID)):
		_enemiesAlive.erase(destroyedEnemySpawnID)

		# Check for gameover if all enemies are destroyed
		if(_enemiesAlive.empty()):
			#print("ENEMY ALIVE LIST IS EMPTY!")
			emit_signal("enemyListEmpty")
			
		#print("Enemy " + str(destroyedEnemySpawnID) + " has been destroyed")

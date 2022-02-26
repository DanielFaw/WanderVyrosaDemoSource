extends "res://Scripts/MainGame/TowerControl/BuildableTower.gd"

enum TOWER_STATE {IDLE,FIRING}


# The path of the prefab to fire
export var projectilePrefab:PackedScene

# Path to the node to "fire" from
export var firingPointPath:NodePath

# Cooldown time between firing (in seconds)
export var firingCooldown:float = 1

# The time since we fired last (in seconds)
export var timeSinceFiring: float = 0.0

# How high the projectile should be fired 
export var projectileMaxHeight:float = 1.0

# How random should the aiming be
export var randomSpreadBounds:Vector2 = Vector2.ZERO

var currentProjectileHeight:float

# The current state (enum) of this tower
var _currentState = TOWER_STATE.IDLE

# List of current targets in range
var targetsInRange = []

# The target we are currently firing at 
var _currentTarget:Spatial

# The projectile to fire
var _projectilePrefab:PackedScene

# The max height of the projectile
var targetProjectileHeight = 5.0

# The point we're firing from
# NOTE: _firingPoint must be a Position3d Node
var _firingPoint:Position3D

# Acceleration due to gravity
var gravity = -9.8

func _ready():
	._ready()
	_projectilePrefab = projectilePrefab
	_firingPoint = get_node(firingPointPath)

	pass

func _physics_process(_delta):
	if(!buildComplete):
		_currentState = TOWER_STATE.IDLE

	pass

# Signal called when a body enters 
func _OnBodyEnter(var body):
	#Override in child class
	._OnBodyEnter(body)
	pass

# Signal called when a body exits
func _OnBodyExit(var body):
	# Remove if part of tracked targets
	if(targetsInRange.has(body)):
		var index = targetsInRange.find(body)
		if(index != -1):
			# Tell the enemy they have left the range of the tower
			if(body != null):
				._OnBodyExit(body);
			targetsInRange.remove(index)

	# If its the one we were aiming at, find another one
	if(body == _currentTarget):
		pass
	pass
	
# Selects a new target to fire at
func _SelectNewTarget():
	if(targetsInRange.size() == 0):
		_currentState = TOWER_STATE.IDLE
	else:
		var randEnemy = round(Utilities.GetRandomValue(0,targetsInRange.size()-1))
		_currentTarget = targetsInRange[randEnemy]
		_currentState = TOWER_STATE.FIRING

func TakeDamage(var damageToTake):
	.TakeDamage(damageToTake)
	pass


func Build(var deltaBuildTime):
	.Build(deltaBuildTime)
	if(buildComplete):
		# Look for new targets
		_SelectNewTarget()

func _Fire():
	# Reset time since last fired
	timeSinceFiring = 0.0
	pass

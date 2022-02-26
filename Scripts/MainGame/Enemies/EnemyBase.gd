extends KinematicBody

enum enemyState {ATTACKING,ENEMY_FOUND,WANDERING}

# How fast we should move horizontally
export var moveSpeed:float;

# How strong gravity is
var gravityStrength = 9.8
var velocity = Vector3.ZERO

# CUMULATIVE gravity strength
var currentGravityStrength = 0

# How fast do we reach max speed?
var acceleration = 1.0

# How long it takes to charge an attack
var chargeTime = 1.0;
var chargeTimeElapsed = 0.0;

# How long it takes between each attack
export var attackCooldown = 1.0

# A list of how many towers are in the radius of awareness
var towersInRadius = []

# How far from a target (max) should we be before we start attacking
export var attackDistance = 5.0;

# The tower we are currently 
var currentTargetTower;

# Our current state
var currentEnemyState = enemyState.WANDERING;

var damageIndicatorPrefab = preload("res://Prefabs/Effects/DamageIndicator.tscn")

# The player's base 
var playerBase;

# Is the attack currently on cooldown
var onAttackCooldown = false

# The shape that we are checking obstacle avoidance with
var intersectshape;

var collisionAvoidanceMask = 0b00000000000000011010

var collidedLastFrame = false
export var testCube:PackedScene

var newVelocity = Vector3.ZERO

export var maxHealth : float = 1;
var currentHealth : float

var pathWaypoints = []
var currentWaypoint = 0

# How fast we are actually traveling
var worldVelocity = Vector3.ZERO

var attackTimer:Timer;

# Did we skip the last index because an obstacle was in the way?
var skippedLastIndex = false

var spawnID

var damageIndicatorTotalDamage:float = 0.0
var currentDamageIndicator

var is_stunned = false
var stun_duration = 0.0

var is_on_fire = false
var remaining_fire_ticks = 0
var fire_damage = 0
var fire_time_counter = 0
var fire_timer = 0

var timer 

func _ready():
	playerBase = SceneResources.GetResource("PlayerBase")
	currentHealth = maxHealth

	attackTimer = Timer.new()
	var _attackConnectSuccess = attackTimer.connect("timeout",self,"_EndAttackCoolDown");

	add_child(attackTimer);
	# Set shape for obstacle avoidance
	intersectshape = PhysicsShapeQueryParameters.new()
	intersectshape.collision_mask = collisionAvoidanceMask
	intersectshape.exclude = [self]
	intersectshape.set_shape(get_node("CollisionShape").shape)


	timer = Timer.new()
	add_child(timer)

	timer.connect("timeout",self,"SetupPathfinding")
	timer.one_shot = true
	timer.start()

	pass


func SetupPathfinding():

	var pathInfo = SceneResources.GetResource("EnemyManager").CalculateEnemyPath(global_transform.origin + global_transform.basis.z * 6.0);

	pathWaypoints = pathInfo["waypoints"]

	timer.queue_free()
	pass

func _Attack():
	chargeTimeElapsed = 0;

	# Wait for cooldown
	onAttackCooldown = true

	attackTimer.start(attackCooldown);
	pass;

func _EndAttackCoolDown():
	onAttackCooldown = false
	pass

func TowerRangeEntered(var tower):
	if(!towersInRadius.has(tower)):
		towersInRadius.push_back(tower);
	if(currentTargetTower == null):
		_SelectNewTarget();
	pass;

func TowerRangeExited(var tower):
	if(towersInRadius.has(tower)):
		var index = towersInRadius.find(tower)
		if(index != -1):
			towersInRadius.remove(index);
	if(tower == currentTargetTower):
		_SelectNewTarget();
	pass;
	
func TakeDamage(var damageToTake, var params = {}):
	if params.size() > 0:
		#Check what element to add
		if params.has("stun"):
			stun_duration += params["stun"]
			is_stunned = true
			pass
		elif params.has("fire"):
			var s = params["fire"]
			start_flame_damage(s["dmg"], s["amnt"], s["time"])
			pass
		pass
	
	
	currentHealth -= damageToTake
	_SpawnDamageIndicator(damageToTake)
	if(currentHealth < 0):
		_OnDeath();

func start_flame_damage(var damage, var amnt, var time):
	is_on_fire = true
	fire_damage = damage
	fire_timer = time
	remaining_fire_ticks = amnt
	pass

func stun_me(var time):
	is_stunned = true
	stun_duration += time
	pass

func _SpawnDamageIndicator(damageTaken:float):
	#if(currentDamageIndicator == null):
	currentDamageIndicator = damageIndicatorPrefab.instance()
	self.add_child(currentDamageIndicator)
	currentDamageIndicator.SetInitialY(1.0)
	
	if(currentDamageIndicator != null):
		currentDamageIndicator.SetDamageText(damageTaken, currentHealth / maxHealth)
	pass


func _OnDeath():
	self.queue_free()

func _SelectNewTarget():
	# No towers in radius, head for main base
	if(towersInRadius.empty()):
		currentTargetTower = null;
		currentEnemyState = enemyState.WANDERING
	else:
		# For now, just get tower at the front of the list
		currentTargetTower = towersInRadius.front();

func _AttackState(var deltaTime):
	chargeTimeElapsed += deltaTime
	newVelocity = currentTargetTower.global_transform.origin - global_transform.origin
	if(chargeTimeElapsed > chargeTime && !onAttackCooldown):
		_Attack();

	pass


func _MoveToTower():
	var vecToTarget = (currentTargetTower.global_transform.origin - global_transform.origin)
	
	# We're at the target, start attacking
	if(vecToTarget.length() < attackDistance):
		currentEnemyState = enemyState.ATTACKING
		return
	else:
		# Apply movement to overall velocity
		velocity += global_transform.basis.z.normalized() * moveSpeed * get_physics_process_delta_time()

	pass;

# If there is no active tower we're attacking, move towards the base
func _WanderState(var _localUp):
	if(playerBase == null):
		return;

	if(currentTargetTower == null):
		if(pathWaypoints.empty() || currentWaypoint > pathWaypoints.size()-1):
			return


		var vecToWaypoint:Vector3 = (pathWaypoints[currentWaypoint] - global_transform.origin)
		
		if(OS.is_debug_build()):
			Debug.DrawDebugLine(global_transform.origin,pathWaypoints[currentWaypoint],Color.blue)
		
		newVelocity = vecToWaypoint.normalized()


		var closerToNext = false;
		# Check if we are currently closer to the next waypoint than the current one
		if(currentWaypoint != pathWaypoints.size() -1):
			if(global_transform.origin.distance_to(pathWaypoints[currentWaypoint +1]) < vecToWaypoint.length()):
				closerToNext = true

		# If we reached the base without any other towers, attack it
		if(currentWaypoint >= pathWaypoints.size() -1):
			currentTargetTower = playerBase
			currentEnemyState = enemyState.ATTACKING;

		

		# Continue to the next point
		elif(global_transform.origin.distance_to(pathWaypoints[currentWaypoint]) < 1.0 || closerToNext):
			currentWaypoint += 1
			skippedLastIndex = false
			#print("Incrementing waypoint to " + str(currentWaypoint))
	
	else:
		currentEnemyState = enemyState.ENEMY_FOUND

	pass

func _physics_process(delta):
	
	#Check fire damage first
	if(is_on_fire):
		fire_time_counter += delta
		if fire_time_counter >= fire_timer:
			fire_time_counter -= fire_timer
			remaining_fire_ticks -= 1
			TakeDamage(fire_damage)
			pass
		pass
	
	#Then make sure they aren't stunned
	if(is_stunned):
		stun_duration -= delta
		if(stun_duration > 0):
			return
		#Else
		is_stunned = false
		pass
	
	newVelocity = Vector3.ZERO
	# Calculate the direction to the target and make it relative to the planet surface
	var gravDirection = Utilities.CalculateGravityDirection(global_transform.origin)

	# Main "state machine"
	match(currentEnemyState):
		enemyState.WANDERING:
			_WanderState(-gravDirection)
			pass;
		enemyState.ENEMY_FOUND:
			_MoveToTower();
			pass;
		enemyState.ATTACKING:
			_AttackState(delta)
			pass;

	# Check if the character is on the floor (as determined by 'UP' vector passed into move_and_slide)
	if(is_on_floor()):
		#If you apply gravity while on the ground, the object tends to slide. Applying *very* slight upwards gravity prevents this.
		currentGravityStrength = -0.01
		pass
	else:
		currentGravityStrength += gravityStrength * delta
		currentGravityStrength = clamp(currentGravityStrength,0.0,gravityStrength) 

	
	# If we're moving, avoid collisions
	if(currentEnemyState != enemyState.ATTACKING):
		var avoidanceForce = _AvoidCollisions()
		if(avoidanceForce.length() > 0):
			# Average(?) velocities
			#newVelocity = (newVelocity.normalized() + avoidanceForce) / 2.0;
			newVelocity = newVelocity.normalized() + avoidanceForce
			pass
		pass

	# Look towards where we're going (smoothed)
	if(newVelocity.x != 0.0):
		var targetTransform = global_transform.looking_at(-newVelocity,gravDirection).orthonormalized()
		global_transform.basis = global_transform.basis.orthonormalized().slerp(Utilities.AlignWithNormal(targetTransform,gravDirection).basis.orthonormalized(),delta * 3.0).orthonormalized()

	# Always align transform
	else:
		global_transform = Utilities.AlignWithNormal(global_transform,gravDirection)

	var alignedVel = Vector3.ZERO
	if(currentEnemyState != enemyState.ATTACKING):
		alignedVel = global_transform.basis.z.normalized() * moveSpeed * delta
		velocity += alignedVel;

	# Apply gravity to overall velocity
	velocity -= gravDirection * currentGravityStrength 

	# Smooth velocity with acceleration
	velocity = velocity.linear_interpolate(velocity,delta * acceleration)
	
	# Apply movement to character
	velocity = move_and_slide(velocity, gravDirection)

	worldVelocity = velocity - worldVelocity

	# Reset velocity
	velocity = Vector3.ZERO
	newVelocity = Vector3.ZERO
	pass

# Avoid collisions to objects impo
func _AvoidCollisions():

	if(pathWaypoints.empty()):
		return Vector3.ZERO

	# Spatial of the current target
	var currentTarget = pathWaypoints[currentWaypoint]
	var vecToTarget = (currentTarget - global_transform.origin)
	var space_state = get_world().direct_space_state


	intersectshape.transform.origin = global_transform.origin + vecToTarget.normalized()

	Debug.DrawDebugLine(global_transform.origin,global_transform.origin + vecToTarget.normalized(),Color.green)
	var shapeCollisionInfo = space_state.intersect_shape(intersectshape,1)

	if(shapeCollisionInfo.size() > 0):
		collidedLastFrame = true

		# If the way point is close to or on top of the obstacle, just keep moving towards the next point
		var obstacleOrigin = shapeCollisionInfo[0]["collider"].global_transform.origin
		var vecToObstacle = (obstacleOrigin - global_transform.origin).normalized()

		if( abs(vecToTarget.dot(vecToObstacle.normalized())) < 0 && !skippedLastIndex):
			currentWaypoint += 1;
			skippedLastIndex = true
			pass
		#Check again in the direction of the new avoidance vec to maneuver out of corners

		var vecToObstacleLocal = transform.xform_inv(vecToObstacle)
		var avoidanceVec
		if(vecToObstacleLocal.x < 0):
			#Calucate a perpendicular vector to "go around" the tower
			avoidanceVec = global_transform.basis.y.normalized().cross(vecToObstacle.normalized())
			Debug.DrawDebugLine(global_transform.origin, global_transform.origin + avoidanceVec.normalized(),Color.yellow)
		else:
			avoidanceVec = global_transform.basis.y.normalized().cross(-vecToObstacle.normalized())
			Debug.DrawDebugLine(global_transform.origin, global_transform.origin - avoidanceVec.normalized(),Color.blue)
			
		return avoidanceVec.normalized()
			
	return Vector3.ZERO
	pass

func SetSpawnID(var newId:int):
	spawnID = newId
	pass

func _exit_tree():
	attackTimer.stop()
	if(attackTimer.is_connected("timeout",self,"_EndAttackCoolDown")):
		attackTimer.disconnect("timeout",self,"_EndAttackCoolDown");
		
	SceneResources.GetResource("EnemyManager").EnemyDestroyed(spawnID)

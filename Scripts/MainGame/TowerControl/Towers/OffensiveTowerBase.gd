extends "res://Scripts/MainGame/TowerControl/BaseTower.gd"

var aimpointTarget:Spatial
var targetLastPosition:Vector3

func _ready():
	._ready()

	# Create aimpoint
	aimpointTarget = Spatial.new()
	add_child(aimpointTarget)
	aimpointTarget.global_transform.origin = global_transform.origin

	pass

func TakeDamage(var damageToTake):
	.TakeDamage(damageToTake)
	pass

func Build(var deltaBuildTime):
	.Build(deltaBuildTime)

func _OnDeath():
	._OnDeath()

func _physics_process(delta):
	._physics_process(delta)

	# Update our _currentState
	match(_currentState):

		# Currently just chillin
		TOWER_STATE.IDLE:
			if(targetsInRange.size() > 0):
				_currentState = TOWER_STATE.FIRING
			pass

		# Currently firing at an enemy
		TOWER_STATE.FIRING:
			if(targetsInRange.front() == null):
				_currentState = TOWER_STATE.IDLE
			else:

				# Check if we still have a target
				if(_currentTarget == null):
					_SelectNewTarget()
					return
				#---------- Aimpoint leading -----------------
				# Match target position
				if(targetLastPosition == null):
					targetLastPosition = _currentTarget.global_transform.origin

				var enemyVel = _currentTarget.global_transform.origin - targetLastPosition

				var predictedEnemyPos = aimpointTarget.global_transform.origin.linear_interpolate(_currentTarget.global_transform.origin  + enemyVel * 4.0,delta * 10.0)
				aimpointTarget.global_transform.origin = predictedEnemyPos

				targetLastPosition = _currentTarget.global_transform.origin
				#---------------------------------------------

				# Delay each "shot"
				if(timeSinceFiring > firingCooldown):
					_Fire()
				else:
					# Recharging
					timeSinceFiring += delta
			pass
	pass

func _SelectNewTarget():
	._SelectNewTarget()
	pass;

func _SetBuiltMaterial():
	._SetBuiltMaterial()
	_SelectNewTarget();
	pass;

func _OnBodyEnter(var body):
	._OnBodyEnter(body);
	# If we dont have the body in our list of targets, add it as a target
	if(body.collision_layer != null):
		if(body.collision_layer != 9 && body.collision_layer != 1):
			if(!targetsInRange.has(body)):
				#print("New target: " + body.name )
				targetsInRange.push_back(body)
					
				# If we aren't yet completely built, dont select new target
				if(!buildComplete):
					return
				_SelectNewTarget();
	pass;

func _OnBodyExit(var body):
	._OnBodyExit(body)

	if(body == _currentTarget):
		_currentTarget = null;

		if(!buildComplete):
			return
		_SelectNewTarget();
	pass;

func _Fire():
	if(_currentTarget != null):

		# Tower fire code
	._Fire()
	pass;

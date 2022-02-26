extends "res://Scripts/MainGame/TowerControl/BaseTower.gd"

var targetLastPosition:Vector3
var aimpointTarget:Spatial

export var _fireAudioSourcePath:NodePath
export var _decoMissilePath:NodePath
var _decoMissile:Spatial

var tower_stats = preload("res://CustomResources/UpgradableStats/Mortar_Stats.tres")
var myStats
var explosionRadius
var damage

var can_stun : bool = false
var stun_duration

var can_flame : bool = false

var flame_damage
var flame_amount
var flame_time

var elemental_stats = {
	
}

func _ready():
	._ready()

	_decoMissile = get_node(_decoMissilePath)
	_decoMissile.visible = false
	# Create aimpoint
	aimpointTarget = Spatial.new()
	add_child(aimpointTarget)
	aimpointTarget.global_transform.origin = global_transform.origin
	
	myStats = tower_stats.GetAllStats()
	UpdateStats()
	pass

func UpdateStats() -> void:
	firingCooldown = myStats[TStat.ATTACKSPEED]
	damage = myStats[TStat.DAMAGE]
	timeToBuild = myStats[TStat.BUILDTIME]
	_towerMaxHealth = myStats[TStat.HP]
	_health = _towerMaxHealth
	explosionRadius = myStats[TStat.EXPLOSIONRADIUS]
	
	can_stun = myStats[TStat.STUN_ENABLED]
	stun_duration = myStats[TStat.STUNDURATION]
	
	can_flame = myStats[TStat.NAPALM_ENABLED]
	
	flame_damage = myStats[TStat.FIREDAMAGE]
	flame_amount = myStats[TStat.FIRETICKAMOUNT]
	flame_time = myStats[TStat.TIMEBETWEENTICKS]
	
	if(can_flame):
		elemental_stats["fire"] = {
			"dmg" : flame_damage,
			"amnt" : flame_amount,
			"time" : flame_time
		}
		pass
	elif(can_stun):
		elemental_stats["stun"] = stun_duration
		pass
	
	
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
			elif(!_decoMissile.visible && timeSinceFiring > firingCooldown):
				_decoMissile.visible = true
				pass
			pass

		# Currently firing at an enemy
		TOWER_STATE.FIRING:
			if(targetsInRange.front() == null):
				_currentState = TOWER_STATE.IDLE
				pass
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
				if(timeSinceFiring > firingCooldown):
					_Fire()
					_decoMissile.visible = false
					pass

			pass
	pass


	# Recharge regardless of state to "prep" for next enemy
	timeSinceFiring += delta
	pass

func _SelectNewTarget():
	._SelectNewTarget()

	pass;

func _SetBuiltMaterial():
	._SetBuiltMaterial()
	_SelectNewTarget()
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
				_SelectNewTarget()
	pass;

func _OnBodyExit(var body):
	._OnBodyExit(body)

	if(body == _currentTarget):
		_currentTarget = null

		if(!buildComplete):
			return
		_SelectNewTarget();
	pass;

func _Fire():
	if(_currentTarget != null):

		# Calculate midPoint
		var vecToTarget =  _currentTarget.global_transform.origin - _firingPoint.global_transform.origin
		var midPoint = _firingPoint.global_transform.origin + vecToTarget.normalized() * (vecToTarget.length() / 2.0)
		var radius = vecToTarget.length()/ 2.0

		var newProjectile = projectilePrefab.instance()
		get_tree().get_current_scene().add_child(newProjectile)

		newProjectile.global_transform.origin = _firingPoint.global_transform.origin
		newProjectile.SetData(radius,_firingPoint.global_transform.origin,_currentTarget.global_transform.origin,2.0,midPoint,damage, explosionRadius, elemental_stats)
		get_node(_fireAudioSourcePath).playing = true
		pass

	._Fire()
	pass;

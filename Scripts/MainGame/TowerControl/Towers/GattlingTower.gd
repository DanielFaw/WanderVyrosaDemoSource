extends "res://Scripts/MainGame/TowerControl/BaseTower.gd"

# Paths to the bone controllers for this model
export(Array,NodePath) var boneControlPaths

# The bone control scripts attached to this model
var boneControlScripts = [];

export var aimpointAttachmentPath:NodePath
var aimpointAttachment

var targetLastPosition:Vector3

export var _skeletonPath:NodePath
var _skeleton:Skeleton
export var _barrelBoneName:String
var _barrelBoneID

var losMask = 0b00000000000000000110

export var fire_sound_path:NodePath
var fire_sound:AudioStreamPlayer3D

export var spin_sound_volume_bounds:Vector2
export var spin_sound_pitch_bounds:Vector2

export var spin_sound_pitch_curve:Curve

export var spin_sound_path:NodePath
var spin_sound:AudioStreamPlayer3D

var aimpointTarget:Spatial

var myStats
var tower_stats : Resource
var bulletDamage

var windupTime : float
var windupCounter : float = 0
var doneWinding = false


var cooldownTime : float
var cooldownTimer : float = 0
var currentlyUnderCooldown = false

var constantFireTime : float
var constantFireCounter : float = 0
var ableToFire = false

var barrelSpinSpeed = 10.0
var barrelSpinMulti = 15.0

var windDownIdle = 0

var bulletSpreadAmount

func _ready():
	._ready()
	fire_sound = get_node(fire_sound_path)
	_skeleton = get_node(_skeletonPath)
	_barrelBoneID = _skeleton.find_bone(_barrelBoneName)
	spin_sound = get_node(spin_sound_path)
	

	# Create aimpoint
	aimpointTarget = Spatial.new()
	add_child(aimpointTarget)
	aimpointTarget.global_transform.origin = global_transform.origin

	# Hook up bone control stuff
	for path in boneControlPaths:
		boneControlScripts.push_front(get_node(path))
		pass
	for b in boneControlScripts:
		b.UpdateTarget(aimpointTarget.get_path());
		b.enabled = false

	# Wait until skeleton is initialized, then add attachment
	aimpointAttachment = get_node(aimpointAttachmentPath)

	#TODO: This should be updated to not rely on a timer
	yield(get_tree().create_timer(0.1),"timeout")
	aimpointAttachment.set_bone_name("Base_Rot_X")
	
	tower_stats = load("res://CustomResources/UpgradableStats/Gatling_Stats.tres")
	#tower_stats.connect("upgrade_added", self, "UpdateStats")
	UpdateStats()
	pass

"""----------------------TOWER STATS INIT------------------------"""
func UpdateStats() -> void:
	myStats = tower_stats.GetAllStats()
	
	firingCooldown = myStats[TStat.ATTACKSPEED]
	bulletDamage = myStats[TStat.DAMAGE]
	timeToBuild = myStats[TStat.BUILDTIME]
	_towerMaxHealth = myStats[TStat.HP]
	_health = _towerMaxHealth
	windupTime = myStats[TStat.WINDTIME]
	cooldownTime = myStats[TStat.COOLDOWN]
	cooldownTimer = cooldownTime
	constantFireTime = myStats[TStat.SHOOTTIME]
	bulletSpreadAmount = myStats[TStat.BULLETSPREAD]
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
	if(!buildComplete):
		return

	
	# barrelSpinSpeed = deg2rad((windupCounter / windupTime) * 10.0)
	# Update our _currentState
	match(_currentState):
		
		TOWER_STATE.IDLE:
			#If the constantFireCounter has any 'juice'
			if(constantFireCounter > 0 && ableToFire):
				constantFireCounter -= delta
				pass
			if(targetsInRange.size() > 0):
				_currentState = TOWER_STATE.FIRING
			pass

		# Currently firing at an enemy
		TOWER_STATE.FIRING:
			if(targetsInRange.front() == null):
				_currentState = TOWER_STATE.IDLE
				#print("RRRREEEEEEEEEEEEEEEEEEEEEEEE")
				if(!doneWinding && !ableToFire):
					windDownIdle = (windupCounter / windupTime)
					pass
				else:
					windDownIdle = 1
				#print("Gatling will now wind down")
			else:

				# Check if we still have a target
				if(_currentTarget == null):
					#print("ree")
					_SelectNewTarget()
					#print("Ree2")
					return
					
				if(!doneWinding && !currentlyUnderCooldown):
					#If the tower isn't done winding up, make it wind (unable to shoot)
					windupCounter += delta
					spin_sound.pitch_scale = lerp(spin_sound_pitch_bounds.x,spin_sound_pitch_bounds.y,spin_sound_pitch_curve.interpolate(windupCounter/windupTime))

					if(windupCounter >= windupTime):
						doneWinding = true
						ableToFire = true
						#print("Gatling is done winding up")
						windupCounter = 0.0001
						pass
					pass
				else:
					#If it is done winding up, check if it's on cooldown or not
					
					#If it's on cooldown, it cant shoot
					
					#if its off cooldown and its also done winding, increase cooldown timer
					if(currentlyUnderCooldown):
						cooldownTimer -= delta
						ableToFire = false
						if(cooldownTimer < 0):
							cooldownTimer = cooldownTime
							currentlyUnderCooldown = false
							doneWinding = false
							#print("Gatling is done cooling down, beginning to wind")
							pass
						pass
					else:
						#Ready to shoot!
						ableToFire = true
						constantFireCounter += delta
						if(constantFireCounter >= constantFireTime):
							ableToFire = false
							currentlyUnderCooldown = true
							doneWinding = false
							constantFireCounter = 0.0001
							#print("Gatling has to cool down")
							pass
						pass
					pass
				

				#---------- Aimpoint leading -----------------
				# Match target position
				if(targetLastPosition == null):
					targetLastPosition = _currentTarget.global_transform.origin

				var enemyVel = _currentTarget.global_transform.origin - targetLastPosition

				var predictedEnemyPos = aimpointTarget.global_transform.origin.linear_interpolate(_currentTarget.global_transform.origin  + enemyVel * 4.0,delta * 10.0)
				aimpointTarget.global_transform.origin = predictedEnemyPos

				targetLastPosition = _currentTarget.global_transform.origin
				#---------------------------------------------
				if(ableToFire):
					if(timeSinceFiring > firingCooldown):
						_Fire()
						#_FireProjectile()
						pass
					else:
						# Recharging
						timeSinceFiring += delta
						pass
					pass
				pass

			pass
		
	#If the tower is currently firing, it should be at 100% speed
	if(_currentState == TOWER_STATE.IDLE || targetsInRange.size() == 0):
		#Wind down
		if(windDownIdle > 0):
			windDownIdle -= delta
			pass
		else:
			windDownIdle = 0
			pass
		
		barrelSpinSpeed = deg2rad(windDownIdle * barrelSpinMulti)
		pass
	elif(ableToFire && doneWinding && _currentState == TOWER_STATE.FIRING):
		barrelSpinSpeed = deg2rad(barrelSpinMulti)
		pass
	elif(currentlyUnderCooldown):
		var percent
		var deltaCool = cooldownTime - cooldownTimer
		if(deltaCool > 1.5):
			percent = 0
		else:
			percent = 1 - (deltaCool/1.5)
		barrelSpinSpeed = deg2rad(percent * barrelSpinMulti)
		pass
	elif(!doneWinding && _currentState == TOWER_STATE.FIRING):
		#print("Windup time: " + str(windupTime))
		windDownIdle = (windupCounter / windupTime)
		barrelSpinSpeed = deg2rad((windupCounter / windupTime) * barrelSpinMulti)
		pass

	var barrelTransform = _skeleton.get_bone_pose(_barrelBoneID)
	# Rotate barrel
	_skeleton.set_bone_pose(_barrelBoneID, barrelTransform.rotated(barrelTransform.basis.y, barrelSpinSpeed))


	var current_spin_speed_normalized = rad2deg(barrelSpinSpeed)/barrelSpinMulti

	if(current_spin_speed_normalized > 0 && !spin_sound.playing):
		spin_sound.play()
		pass
	elif (current_spin_speed_normalized <= 0 && spin_sound.playing):
		spin_sound.stop()
		pass
	
	# Set the pitch
	spin_sound.pitch_scale = lerp(spin_sound_pitch_bounds.x,spin_sound_pitch_bounds.y,spin_sound_pitch_curve.interpolate(current_spin_speed_normalized))
	
	pass

func _SelectNewTarget():
	._SelectNewTarget()

	if(_currentTarget == null):
		for b in boneControlScripts:
			b.enabled = false;
			pass;
	else:
		for b in boneControlScripts:
			b.enabled = true;
			pass;

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
		#Raycast towards target to see if we have a clear shot
		var space = get_world().direct_space_state
		var result = space.intersect_ray(_firingPoint.global_transform.origin,_currentTarget.global_transform.origin,[self],losMask)

		# Check if we hit the target
		if(result.size() > 0):
			if(result.collider_id == _currentTarget.get_instance_id()):
				#Fire bullet
				var newBullet = _projectilePrefab.instance()
				newBullet.visible = false
				get_tree().get_root().add_child(newBullet)
			
				# Create and fire new projectile
				newBullet.global_transform.origin = _firingPoint.global_transform.origin
				var random_spread_x = Utilities.GetNormalRandomValue(0.5, 0.1)
				random_spread_x = (random_spread_x - 0.5) * bulletSpreadAmount
				var random_spread_y = Utilities.GetNormalRandomValue(0.5, 0.1)
				random_spread_y = (random_spread_y - 0.5) * bulletSpreadAmount
				var my_vec = Vector3(random_spread_x, random_spread_y, 0)
				#my_vec = transform.orthonormalized().xform(my_vec)
				var target_vector = _currentTarget.global_transform.origin - my_vec
				var direction = (target_vector - _firingPoint.global_transform.origin).normalized()
				#direction -= my_vec
				Debug.DrawDebugLine(_firingPoint.global_transform.origin, _firingPoint.global_transform.origin + my_vec, Color.whitesmoke)
				Debug.DrawDebugLine(_firingPoint.global_transform.origin, _currentTarget.global_transform.origin, Color.blue)
				Debug.DrawDebugLine(_firingPoint.global_transform.origin, _currentTarget.global_transform.origin + my_vec, Color.red)
				
				
				# Fire towards player
				newBullet.SetValues(direction,[2],bulletDamage)

				newBullet.visible = true
				fire_sound.pitch_scale = Utilities.GetRandomValue(0.8, 1.2)
				fire_sound.play()
				pass
			else:
				# If we hit another enemy, target them instead
				if(result.collider.is_in_group("Enemies")):
					_currentTarget = result.collider.get_owner();
				elif(targetsInRange.size() > 2):
					_SelectNewTarget()
		else:
			fire_sound.stop()
	._Fire()
	pass;

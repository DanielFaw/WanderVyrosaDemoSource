extends KinematicBody

export var move_speed:float = 1.0

export var bob_speed:float = 1
export var bob_magnitude:float = 1
export var build_speed:float = 1.0

export var vis_path:NodePath

var vis_object
var target_node

export var weld_audio_path:NodePath
var weld_audio:AudioStreamPlayer3D

export var particles_path:NodePath
var particles

enum DRONE_STATE {TRAVELING_TO_TOWER,AT_TOWER,TRAVELING_TO_BASE,AT_BASE}

var current_drone_state = DRONE_STATE.TRAVELING_TO_TOWER

var time = 0

var myStats
var drone_stats = preload("res://CustomResources/UpgradableStats/BuildingController_Stats.tres")

# Travel Parameters
var travel_time_elapsed:float = 0.0
var current_target_radius:float
var time_to_target:float = 0.0

var arc_travel_distance:float
var travel_start_position:Vector3

func _ready():
	weld_audio = get_node(weld_audio_path)
	vis_object = get_node(vis_path)
	particles = get_node(particles_path)
	particles.emitting = false
	InitStats()
	pass

func InitStats():
	myStats = drone_stats.GetAllStats()
	move_speed = myStats[TStat.DRONESPEED]
	pass

func SetTarget(var newTarget):
	target_node = newTarget

	# Calculate slerp travel properties
	travel_start_position = global_transform.origin
	current_target_radius = travel_start_position.distance_to(target_node.global_transform.origin) / 2.0

	var planet_to_start:Vector3 = SceneResources.GetResource("Planet").global_transform.origin - travel_start_position
	var planet_to_target:Vector3 = SceneResources.GetResource("Planet").global_transform.origin - target_node.global_transform.origin

	# Calculate the linear distance of the arc:  arc_travel_distance = radius * angle between vectors
	arc_travel_distance = 20.0 * planet_to_start.angle_to(planet_to_target)

	# How long it should take to get to the target based on distance from start
	time_to_target =  arc_travel_distance / move_speed
	
	travel_time_elapsed = 0.0


func _process(delta: float):
	time += delta * bob_speed
	vis_object.translation.y = sin(time) * bob_magnitude
	pass


func _physics_process(delta: float):

	match(current_drone_state):
		DRONE_STATE.TRAVELING_TO_TOWER:
			if(target_node != null):
				_MoveTowardsTarget(delta)
				pass
			else:

				# Target building has been destroyed, return to base
				SetTarget(SceneResources.GetResource("TowerManager"))
				current_drone_state = DRONE_STATE.TRAVELING_TO_BASE

				pass

		DRONE_STATE.AT_TOWER:
			if(!weld_audio.playing):
				weld_audio.play()
		
			_BuildTower(delta)
			pass
		
		DRONE_STATE.TRAVELING_TO_BASE:
			if(weld_audio.playing):
				weld_audio.stop()
			_MoveTowardsTarget(delta)
			pass

		DRONE_STATE.AT_BASE:
			# Mark that we have returned, and "delete" ourselves
			SceneResources.GetResource("TowerManager").ReportDroneReturned()
			self.queue_free()
			pass
		

	pass

# Build the target tower
func _BuildTower(delta):
	if(target_node == null):
		current_drone_state = DRONE_STATE.TRAVELING_TO_BASE
		SetTarget(SceneResources.GetResource("TowerManager"))	
		return
		
	if(!target_node.buildComplete):
		particles.emitting = true
		target_node.Build(delta * build_speed)
	else:
		particles.emitting = false
		current_drone_state = DRONE_STATE.TRAVELING_TO_BASE
		SetTarget(SceneResources.GetResource("TowerManager"))	
		pass

# Move towards a new target
func _MoveTowardsTarget(var physics_delta:float):

	# Tower no longer exists, go back to base
	if(target_node == null):
		SetTarget(SceneResources.GetResource("TowerManager"))
		current_drone_state = DRONE_STATE.TRAVELING_TO_BASE
		return

	var local_up = Utilities.CalculateGravityDirection(global_transform.origin)

	# Look towards target direction AND align with local UP direction
	global_transform = Utilities.AlignWithNormal(global_transform.looking_at(target_node.global_transform.origin,local_up).rotated(local_up,PI),local_up)

	# Use slerp to move around planet towards target
	travel_time_elapsed += (physics_delta / time_to_target)

	var target_slerp_position = travel_start_position.slerp(target_node.global_transform.origin,travel_time_elapsed).normalized()
	var vec_planet_to_target = target_slerp_position - SceneResources.GetResource("Planet").global_transform.origin

	# TODO: Replace 20.0 with planet radius eventually
	var target_pos =  (vec_planet_to_target.normalized() * 20.0)
	global_transform.origin = target_pos


	# Drone is at target, update state accordingly
	if(travel_time_elapsed > 0.98):
		travel_time_elapsed = 0.98

		if(current_drone_state == DRONE_STATE.TRAVELING_TO_TOWER):
			current_drone_state = DRONE_STATE.AT_TOWER
			pass 

		elif(current_drone_state == DRONE_STATE.TRAVELING_TO_BASE):
			current_drone_state = DRONE_STATE.AT_BASE
			pass
		
		pass
	pass

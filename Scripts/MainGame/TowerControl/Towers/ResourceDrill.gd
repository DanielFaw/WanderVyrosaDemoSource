extends "res://Scripts/MainGame/TowerControl/BuildableTower.gd"

export var dirt_path:NodePath
var dirt_model:Spatial
export var anim_player_path:NodePath
var anim_player:AnimationTree

const RESOURCE_TYPE = preload("res://Scripts/MainGame/ResourceType.gd")
var current_target_resource_type

export var spawn_node_path:NodePath
var spawn_point

export var particle_path:NodePath
var particles

export var metal_prefab:PackedScene
export var silicon_prefab:PackedScene
export var quartz_prefab:PackedScene
export var boom_stone_prefab:PackedScene

export var audio_source_path:NodePath

var mined_amount = 0.0

# How many ticks should pass between each minute 
#   150 ticks = ~2.5 seconds

var time_to_mine:float = 2.5
var time_since_last_resource:float = 0.0

var building_controller

export var mining_efficency = 1.0
var bucket_size
var my_bucket = {
	0 : 0,
	1 : 0,
	2 : 0,
	3 : 0
}

var visual_bucket = {
	0 : 0,
	1 : 0,
	2 : 0,
	3 : 0
}

var myStats
var tower_stats = preload("res://CustomResources/UpgradableStats/Drill_Stats.tres")


export var vein_raycast_path:NodePath
var vein_raycast:RayCast

var vein_density

func _ready():

	particles = get_node(particle_path)
	particles.emitting = false
	spawn_point = get_node(spawn_node_path)
	# Dont show the dirt until the tower is complete
	dirt_model = get_node(dirt_path)
	dirt_model.visible = false
	anim_player = get_node(anim_player_path)
	current_target_resource_type = RESOURCE_TYPE.TYPE.Metal
	vein_raycast = get_node(vein_raycast_path)
	building_controller = SceneResources.GetResource("BuildingController")


	._ready()
	
	myStats = tower_stats.GetAllStats()
	UpdateStats()
	pass

"""----------------------TOWER STATS INIT------------------------"""
func UpdateStats() -> void:
	timeToBuild = myStats[TStat.BUILDTIME]
	_towerMaxHealth = myStats[TStat.HP]
	_health = _towerMaxHealth
	mining_efficency = myStats[TStat.DRILLEFF]
	time_to_mine = myStats[TStat.DRILLSPEED]
	bucket_size = myStats[TStat.BUCKETSIZE]
	pass
	
func Build(var build_delta_time):
	.Build(build_delta_time)
	if(buildComplete):
		
		SetTargetResource()
		anim_player.active = true
		dirt_model.visible = true
		particles.emitting = true
		get_node(audio_source_path).playing = true
		_OnTargetResourceChange()


func _OnTargetResourceChange():
	#TODO: Calculate new time
	time_since_last_resource = 0
	# Base time is 5s for 100% availibility, and 10s for 10% availibility or lessme toerp(10.0,5.0, SceneResources.GetResource("Planet").GetResourceAbundance(current_target_resource_type))
	#print("Resource mining time for " + str(current_target_resource_type) + ": " + stme)to
# Set the resource this drill should currently be mining based on vein placement
func SetTargetResource():
	if(vein_raycast.is_colliding()):
		var vein_type = vein_raycast.get_collider().get_owner().get_owner().GetVeinInfo()["type"]
		vein_density = vein_raycast.get_collider().get_owner().get_owner().GetVeinInfo()["density"]

		match(vein_type):
			"0":
				current_target_resource_type = RESOURCE_TYPE.TYPE.Metal
				pass
			"1":
				current_target_resource_type = RESOURCE_TYPE.TYPE.Quartz
				pass
			"2":
				current_target_resource_type = RESOURCE_TYPE.TYPE.Silicon
				pass
			"3":
				current_target_resource_type = RESOURCE_TYPE.TYPE.BoomStone
				pass
			_:
				current_target_resource_type = RESOURCE_TYPE.TYPE.Random
				pass
		pass
	else:
		current_target_resource_type = RESOURCE_TYPE.TYPE.Random
		pass
	pass


func OnBodyEnter(var body):
	._OnBodyEnter(body)
	pass


func OnBodyExit(var body):
	._OnBodyExit(body)
	pass


# Spawns a resource item as an effect
func _SpawnResourceItem(var resource_type):
	var resource_item

	match(resource_type):
		RESOURCE_TYPE.TYPE.Metal:
			resource_item = metal_prefab
			pass
		RESOURCE_TYPE.TYPE.Quartz:
			resource_item = quartz_prefab
			pass
		RESOURCE_TYPE.TYPE.Silicon:
			resource_item = silicon_prefab
			pass
		RESOURCE_TYPE.TYPE.BoomStone:
			resource_item = boom_stone_prefab
			pass

	var resource_instance = resource_item.instance()
	get_tree().get_current_scene().add_child(resource_instance)
	resource_instance.global_transform.origin = spawn_point.global_transform.origin
	resource_instance.CalculateTargetVec()
	pass


func _physics_process(delta):

	if(buildComplete):
		time_since_last_resource += delta

		if(time_since_last_resource > time_to_mine):

			# amount_mined = <drill efficency> * <vein/planet resource density>
			var amount_mined
			var resource_type
			
			if(current_target_resource_type != 4):
				resource_type = current_target_resource_type
				amount_mined = mining_efficency * vein_density
				pass
			# Drill was not placed on a vein, so mine random resources
			else:
				var resource_rand = Utilities.GetRandInt(0,3)
				resource_type = RESOURCE_TYPE.TYPE[RESOURCE_TYPE.TYPE.keys()[resource_rand]]
				var density = SceneResources.GetResource("Planet").GetResourceAbundance(resource_type)
				amount_mined = density * mining_efficency
				
				pass

			my_bucket[resource_type] += amount_mined
			visual_bucket[resource_type] += amount_mined
			
			#I literally cannot bring myself to delete the next line.
			#It will be forever frozen in time, a monument to human evolution
			#mined_amount += amount_mined

			# If the amount this drill has mined is more than the bucket quantity, spawn the effect
			
			while(my_bucket[resource_type] > bucket_size):
				if(visual_bucket[resource_type]) > max(1.0, bucket_size):
					_SpawnResourceItem(resource_type)
					visual_bucket[resource_type] -= max(1.0, bucket_size)
				my_bucket[resource_type] -= bucket_size
				building_controller.CollectResource(resource_type, bucket_size)
				pass


			time_since_last_resource = 0
			pass

	pass

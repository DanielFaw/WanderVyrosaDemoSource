extends Spatial

# Form of spherical coords: Vector3(r,theta,phi)
var target_pos
var fire_point_pos
var radius = 1
var time_since_fire = 0.0
var travel_time_to_target = 1
var mid_point = Vector3.ZERO
var mid_point_vert
var mid_target
var damage_amount = 0

export var damage_particle_prefab:PackedScene = preload("res://Prefabs/Effects/ExplosionParticles.tscn")

export var damage_area_path:NodePath
var damage_area_physics_shape:PhysicsShapeQueryParameters
var damage_mask =  0b00000000000000000010

var has_exploded = false
var objects_to_damage = []

var distance_multiplier = 1.0


var elemental_params = {}

func _ready():
	damage_area_physics_shape = PhysicsShapeQueryParameters.new()
	damage_area_physics_shape.set_shape(get_node(damage_area_path).shape)
	damage_area_physics_shape.transform = get_node(damage_area_path).transform
	damage_area_physics_shape.collision_mask = damage_mask
	pass

func SetData(radius_in:float, fire_point:Vector3, target_point:Vector3, travel_time_to_target_in:float, mid_point_in:Vector3, damage_amount_in:float, explosion_radius, elemental_stats : Dictionary):
	time_since_fire = 0.0
	self.radius = radius_in
	self.fire_point_pos = fire_point
	self.target_pos = target_point
	self.travel_time_to_target = travel_time_to_target_in
	self.mid_point = mid_point_in
	$DamageArea.shape.radius = explosion_radius
	#$DamageArea.scale = Vector3(explosion_radius, explosion_radius, explosion_radius)
	$Particles.scale = Vector3(explosion_radius, explosion_radius, explosion_radius)
	
	if elemental_stats.size() > 0:
		elemental_params = elemental_stats

	mid_point_vert = Utilities.CalculateGravityDirection(mid_point).normalized() 
	mid_target = (mid_point + mid_point_vert)
	damage_amount = damage_amount_in

	# This is totally precise math I swear
	distance_multiplier = inverse_lerp(0.0, 20.0, clamp(radius * 2.0,0.0,20.0)) + 0.1 * 0.5
	pass

func _physics_process(delta: float):
	time_since_fire += delta

	var percent_traveled = inverse_lerp(0.0,travel_time_to_target * distance_multiplier, time_since_fire) * 2.0
	var new_point_cartesian

	if(percent_traveled <= 1.0):
		var start = fire_point_pos - mid_point
		var end = mid_target
		new_point_cartesian = start.normalized().slerp(end.normalized(),percent_traveled) * radius
	elif(percent_traveled <= 2.0):
		var start = mid_target
		var end = target_pos - mid_point
		new_point_cartesian = start.normalized().slerp(end.normalized(),percent_traveled - 1.0) * radius
	else:
		if(!has_exploded):
			_OnExplode()
		return
	
	if((new_point_cartesian + mid_point).x != 0):
		global_transform = global_transform.looking_at(new_point_cartesian + mid_point,Utilities.CalculateGravityDirection(global_transform.origin).normalized())

	#TODO: Add variation to Y speed to make it more realistic
	global_transform.origin = new_point_cartesian + mid_point

	pass

func _OnExplode():
	has_exploded = true

	# Spawn particle effect
	var expolsion = damage_particle_prefab.instance()
	get_tree().get_current_scene().add_child(expolsion)
	expolsion.global_transform.origin = global_transform.origin

	# Damage All enemies in the surrounding area
	#damage_area_physics_shape.transform.origin = global_transform.origin
	var space_state = get_world().direct_space_state
	damage_area_physics_shape.transform.origin = global_transform.origin
	var ray_collision_info = space_state.intersect_shape(damage_area_physics_shape,15)

	if(ray_collision_info.size() > 0):
		for i in ray_collision_info.size():
			if(ray_collision_info[i]["collider"] != null):
				if(ray_collision_info[i]["collider"].has_method("TakeDamage")):
					ray_collision_info[i]["collider"].TakeDamage(damage_amount, elemental_params)
					pass
				elif(ray_collision_info[i]["collider"].get_owner() != null):
					if(ray_collision_info[i]["collider"].get_owner().has_method("TakeDamage")):
						ray_collision_info[i]["collider"].get_owner().TakeDamage(damage_amount, elemental_params)
						pass
		pass	
		
	self.queue_free()
	pass

extends Spatial

#---LOADS--------------

const PLAYER_CONTROLLER = preload("res://Scripts/PlayerControl/PlayerContoller.gd")
#----------------------

#---EXPORTS------------

# The player movement controller
export var player_controller_path:NodePath
export var animation_tree_path:NodePath
export var jetpack_particle_path:NodePath

export(Array,NodePath) var jetpack_fuel_indicator_paths


export(Array,NodePath) var pack_items

#----------------------

#---REFERENCES---------

var player_controller:PLAYER_CONTROLLER
var animation_tree:AnimationTree
var jetpack_particles:Particles

var jetpack_started:bool = false

var jetpack_fuel_indicator = [];
#----------------------


# Called when the node enters the scene tree for the first time.
func _ready():
	
	player_controller = get_node(player_controller_path) as PLAYER_CONTROLLER
	animation_tree = get_node(animation_tree_path)
	jetpack_particles = get_node(jetpack_particle_path)
	#yield(get_tree().create_timer(1.5),"timeout")

	for p in jetpack_fuel_indicator_paths:
		jetpack_fuel_indicator.push_back(get_node(p))
		pass
	jetpack_particles.emitting = false

	# Hide the pack if we're not on the planet
	if(!player_controller.GetIsOnPlanet()):
		for n in pack_items:
			get_node(n).visible = false
			pass
		pass

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	
	# TODO: Ethan- make this a little cleaner
	var percent_used = 1.0 - (player_controller._jetpackTimeElapsed / player_controller._maxJetpackTime)

	# Set jetpack vfx
	if(percent_used >= 0.0 && !player_controller.isOnGround && Input.is_action_pressed("player_jump")):
		if(!jetpack_started):
			jetpack_started = true
			jetpack_particles.set_emitting(true)
			pass

		_SetFuelIndicators(percent_used)
		pass

	else:
		if(jetpack_started):
			jetpack_started = false
			jetpack_particles.set_emitting(false)
			pass

		if(player_controller.isOnGround && !jetpack_fuel_indicator[0].visible):
			for indicator in jetpack_fuel_indicator:
				indicator.visible = true;
				pass
			pass
		# Set indicator visibility
	

func _physics_process(_delta: float):
	var flat_vel = player_controller.currentVelocity
	flat_vel.y = 0
	flat_vel = flat_vel.normalized() *  player_controller.currentVelocity.length()


	if(player_controller.isOnGround):
		animation_tree.set("parameters/Grounded/B_Idle_Move/blend_amount",flat_vel.length() / player_controller.moveSpeed)
		animation_tree.set("parameters/Grounded/B_Run_Walk/blend_amount",flat_vel.length() / player_controller.moveSpeed)

		# Use only one sound anim at a time
		if(flat_vel.length() / player_controller.moveSpeed > 0.5):
			animation_tree.set("parameters/Grounded/RunSound/add_amount",1.0);
			animation_tree.set("parameters/Grounded/WalkSound/add_amount",0.0);
		else:
			animation_tree.set("parameters/Grounded/RunSound/add_amount",0.0);
			animation_tree.set("parameters/Grounded/WalkSound/add_amount",1.0);
			pass;


		animation_tree.set("parameters/conditions/hovering",false);
		animation_tree.set("parameters/conditions/isGrounded",true);
	else:
		animation_tree.set("parameters/Grounded/B_Idle_Move/blend_amount",0.0)
		animation_tree.set("parameters/Grounded/B_Run_Walk/blend_amount",0.0)

		# Set data for hovering stuff
		animation_tree.set("parameters/conditions/hovering",true);
		animation_tree.set("parameters/conditions/isGrounded",false);
		animation_tree.set("parameters/Hovering/vertSpeed/blend_position",-clamp(stepify(player_controller.currentVelocity.y,0.1),-1.0,1.0))
	pass


func _SetFuelIndicators(percent_used):
	#print(percent_used);
	if(percent_used <= 0.1):
		jetpack_fuel_indicator[2].visible = false;
		pass
	if(percent_used <= 0.33):
		jetpack_fuel_indicator[1].visible = false;
	if(percent_used <= 0.66):
		jetpack_fuel_indicator[0].visible = false;

	

extends KinematicBody

export var planetPath:NodePath

# The strength of gravity
export var gravityStrength:float = 9.8

# How fast the player should accelerate
export var acceleration:float = 1.0
#----------------------------

# The visual object (seperated from the physics representation)
var _vis:Spatial

export var visPath:NodePath

# Player's movement speed
export var moveSpeed:float

export var _torsoPath:NodePath
var _torsoMaterial:Material

# The RELATIVE direction of the player input (*relative to camera rotation)
var direction = Vector3.ZERO

# The velocity of the body
var velocity = Vector3.ZERO

var currentVelocity = Vector3.ZERO

# The direction of gravity
var gravityDirection = Vector3.ZERO

# CUMULATIVE gravity strength
var currentGravityStrength = 0

# The GLOBAL direction of the player input
var rawInputDirection = Vector3.ZERO;
#----------------------------

var targetPosition = Vector3.ZERO
var previousPosition = Vector3.ZERO

# The network ID of the player who this character represents
var playerID

# The planet position
var _planet:Spatial

var isOnPlanet:bool = true

var setUp = false

func on_ready(num):
	playerID = num
	SceneResources.RegisterResource("RemotePlayer"+ str(playerID),self)

	if(isOnPlanet):
		_planet = SceneResources.GetResource("Planet")
	_vis = get_node("_Vis");

	# Get the torso material for custom color assignment
	_torsoMaterial = (get_node(_torsoPath) as MeshInstance).get_surface_material(1)
	_torsoMaterial.resource_local_to_scene = true


	setUp = true
	pass

# Set the color of the player
func SetPlayerColor(newColor:Color):
	_torsoMaterial.albedo_color = newColor
	pass


# Update this players "target" position from the network manager
func UpdateTargetPosition(newPosition : Transform):
	#If the distances are really close together then try to idle
	if previousPosition.distance_squared_to(newPosition.origin) < 0.005:
		
		return
	
	
	previousPosition = targetPosition
	targetPosition = newPosition.origin
	
	var targetTransform : Transform = Utilities.AlignWithNormal(newPosition, Utilities.CalculateGravityDirection(global_transform.origin)).orthonormalized()
	global_transform = newPosition
	#_vis.global_transform = targetTransform
	#targetPosition = Utilities.AlignWithNormal(newPosition,(newPosition.origin - _planet.global_transform.origin).normalized())
	global_transform = global_transform.rotated(transform.orthonormalized().basis.y, PI)
	
	#var targetRot = Quat(targetTransform.rotated(targetTransform.basis.y.normalized(),-PI/2.0).basis)
	_vis.global_transform = targetTransform
	
func _CalculateNewVelocity():
	#Direction should be the current position - previous position
	direction = (targetPosition - previousPosition).normalized()
	pass;

func _process(delta: float):

	if(!setUp):
		return
	#TEMP
	#UpdateTargetPosition(global_transform.origin + global_transform.basis.z)
	#UpdateTargetPosition(SceneResources.GetResource("Player").global_transform.origin)

	if(global_transform.basis.z != gravityDirection):
		var targetTransform = _vis.global_transform.looking_at(global_transform.origin + direction, gravityDirection)
		targetTransform = Utilities.AlignWithNormal(targetTransform, gravityDirection)
		
		var targetRot = Quat(targetTransform.rotated(targetTransform.basis.y, PI).basis.orthonormalized())
		# Lerp towards desired direction
		_vis.global_transform.basis = Quat(_vis.global_transform.basis).slerp(targetRot, delta * 8.0)
		pass


func _physics_process(delta: float):
	#global_transform.origin = targetPosition
	#global_transform = Utilities.AlignWithNormal(global_transform,(global_transform.origin - _planet.global_transform.origin).normalized())
	#_CalculateNewVelocity()
	#velocity = direction
	#pass
	_CalculateNewVelocity()
	
	# Align 'up' vector with planet surface
	global_transform = Utilities.AlignWithNormal(global_transform,gravityDirection)

	# Update the direction of gravity

	if(isOnPlanet):
		gravityDirection = Utilities.CalculateGravityDirection(global_transform.origin)
		pass
	else:
		gravityDirection = Vector3(0,1,0)
		pass

	# Check if the character is on the floor (as determined by 'UP' vector passed into move_and_slide)
	if(is_on_floor()):
		#If you apply gravity while on the ground, the object tends to slide. Applying *very* slight upwards gravity prevents this.
		currentGravityStrength = -0.01
		pass

	else:
		currentGravityStrength += gravityStrength * delta
		currentGravityStrength = clamp(currentGravityStrength,0.0,gravityStrength) 

	# Apply gravity to overall velocity
	velocity -= gravityDirection * currentGravityStrength 

	# Apply movement to overall velocity
	velocity += direction.normalized() * moveSpeed 

	# Smooth velocity with acceleration
	#velocity = currentVelocity.linear_interpolate(velocity,delta * acceleration)

	# Apply movement to character
	var _returnedVel = move_and_slide(velocity, gravityDirection)

	# "Store" current velocity
	currentVelocity = velocity

	# Reset velocity
	velocity = Vector3.ZERO

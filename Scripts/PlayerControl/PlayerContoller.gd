class_name PlayerController extends KinematicBody

#----EXPORTS-----------------
export var cameraPivotPath:NodePath

# Player's movement speed
export var moveSpeed:float

export var planetPath:NodePath

# The strength of gravity
export var gravityStrength:float = 9.8

# How fast the player should accelerate
export var acceleration:float = 1.0

export var _maxJetpackTime:float = 5.0

export var _onPlanet:bool = true

export var jetpack_enabled:bool = true
#----------------------------

#----REFERENCES--------------

# The camera pivot. Used to apply directional movement relative to camera
var _cameraPivot:Spatial

# The planet position
var _planet:Spatial

# The visual object (seperated from the physics representation)
var _vis:Spatial

#----------------------------

#----VARIABLES---------------

# The RELATIVE direction of the player input (*relative to camera rotation)
var direction = Vector3.ZERO

# The velocity of the body
var velocity = Vector3.ZERO

var currentVelocity = Vector3.ZERO

var worldVelocity = Vector3.ZERO

# The direction of gravity
var gravityDirection = Vector3(0,1,0)

# CUMULATIVE gravity strength
var currentGravityStrength = 0

# The GLOBAL direction of the player input
var rawInputDirection = Vector3.ZERO

var currentBasisZ = Vector3.FORWARD

var isOnGround = true

var groundMask = 0b00000000000000110101

var _jetpackTimeElapsed = 0

var input_active:bool = true
#----------------------------


func _init():
	SceneResources.RegisterResource("Player",self)
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	_InitReferences()

	pass # Replace with function body.

# Initialize internal references to external nodes
func _InitReferences():
	_cameraPivot = get_node(cameraPivotPath)
	if(_onPlanet):
		_planet = get_node(planetPath)

	# Initialize with explicit path. Can cause errors if heirarchy changes
	_vis = get_node("_VIS")
	_vis.set_as_toplevel(true)

	pass

func SetPlayerColor(newColor:Color):
	# TODO

	pass

func GetIsOnPlanet():
	return _onPlanet
	pass

# Get the input from the player
func _GetPlayerInput():

	# Since the cameraPivot is rotating around the Z axis, the 'X' axis changes. 
	# Thus we need to calculate a forward vector parallel to the surface
	var forwardVec = gravityDirection.cross(_cameraPivot.transform.orthonormalized().basis.z.normalized()).normalized()
	
	direction = Vector3.ZERO
	rawInputDirection = Vector3.ZERO

	# Only apply if all input is applied
	if(InputState.GetCurrentInputState() != "ALL"):
		return


	if(Input.is_action_pressed("player_move_forward")):
		direction += forwardVec
		rawInputDirection.x += 1.0
		pass

	elif(Input.is_action_pressed("player_move_back")):
		direction -= forwardVec
		rawInputDirection.x -= 1.0
		pass

	if(Input.is_action_pressed("player_move_left")):
		direction -= _cameraPivot.transform.basis.z.normalized()
		rawInputDirection.z -= 1.0
		pass

	elif(Input.is_action_pressed("player_move_right")):
		direction += _cameraPivot.transform.orthonormalized().basis.z.normalized()
		rawInputDirection.z += 1.0
		pass


	rawInputDirection = rawInputDirection.normalized()
	SceneResources.GetResource("CameraController").ExternalRotateCamera(0,get_process_delta_time() * 0.01 * rawInputDirection.z)
	direction = direction.normalized()

	# If we're on the floor, apply jetpack force
	if(Input.is_action_pressed("player_jump") && jetpack_enabled):
		if(_jetpackTimeElapsed < _maxJetpackTime):
			isOnGround = false
			velocity += gravityDirection * 600.0 * get_process_delta_time()
			_jetpackTimeElapsed += get_process_delta_time()
			pass

		elif(isOnGround):
			_jetpackTimeElapsed = 0.0
			pass
		pass
	pass

# Set whether the player controller should be responding to input
func SetPlayerInputActive(is_input_active):
	input_active = is_input_active
	if(!input_active):
		velocity = Vector3.ZERO
		currentVelocity = Vector3.ZERO
		pass
	pass

# Called every frame
func _process(delta):

	if(input_active):
		_GetPlayerInput()
		pass
	else:
		direction = Vector3.ZERO
		pass

	var target_vis_pos = lerp(_vis.global_transform.origin,global_transform.origin,get_physics_process_delta_time() * 25.0)
	#_vis.global_transform.origin = lerp(_vis.global_transform.origin,global_transform.origin,delta * 25.0)

	# If we are currently moving
	#Debug.Report("PlayerDirection", "Player Input:" + str(direction))
	var targetRot
	var targetTransform

	if(direction != Vector3.ZERO):
		var newLookDir

		# Align character with current direction
		# Quaternions/Transforms are weird, so buckle up boyz
		# 	Basically what we are doing is calculating a transform such that the _vis object is looking in the rawInputDirection's Z direction relative to the _cameraPivot's GLOBAL transform.
		# 	We are then taking that targetTransform and creating a Quaternion rotation from it, such that we can lerp between the current Quaternion and the target Quat using slerp (spherical lerp)
		if(_onPlanet):
			newLookDir = gravityDirection.cross(_cameraPivot.global_transform.xform(rawInputDirection)).normalized()
			pass
		else:
			newLookDir = direction.normalized().rotated(global_transform.basis.y.normalized(),PI / 2.0)
			pass


		# Godot freaks out if the angle to and up are really close
		# https://godotforums.org/discussion/27860/transform-looking-at-not-working
		if((_vis.global_transform.origin - newLookDir).normalized().dot(Vector3.UP) < 0.999):
			targetTransform = _vis.global_transform.looking_at(_vis.global_transform.origin - newLookDir,gravityDirection)
			pass
		else:
			targetTransform = Transform.IDENTITY
			pass

		#Debug.DrawDebugLine(global_transform.origin,global_transform.origin + targetTransform.basis.z.normalized(),Color.yellow)
		currentBasisZ = targetTransform.basis.z.normalized()
		pass
	else:
		var localUp 
		if(_onPlanet):
			localUp = Utilities.CalculateGravityDirection(global_transform.origin)
			pass
		else:
			localUp = Vector3(0,1,0)
			pass
		
		if((global_transform.origin - currentBasisZ).normalized().dot(Vector3.UP) < 0.999):
			targetTransform = Utilities.AlignWithNormal(_vis.global_transform.looking_at(global_transform.origin - currentBasisZ,localUp),localUp)
			pass
		else:
			# TODO: May need to add a null check here
			targetTransform = Transform.IDENTITY
			pass
		pass
	
	
	targetRot = Quat(targetTransform.rotated(targetTransform.basis.y.normalized(),-PI/2.0).basis)
	# Align to planet surface

	# For some reason, only setting the basis doesn't work in 'release' builds

	var target_basis = Utilities.AlignWithNormal(Transform(Quat(_vis.global_transform.basis.orthonormalized()).slerp(targetRot,delta * 8.0), global_transform.origin),gravityDirection).basis.orthonormalized()
	var target_transform = Transform(target_basis,target_vis_pos)
	_vis.global_transform =  target_transform
	pass

# Called on each physics tick, similar to FixedUpdate() in Unity
func _physics_process(delta):

	if(_onPlanet):
		# Align 'up' vector with planet surface
		global_transform = Utilities.AlignWithNormal(global_transform,(global_transform.origin - _planet.global_transform.origin).normalized())
	else:
		global_transform = Utilities.AlignWithNormal(global_transform,gravityDirection.normalized())
		pass

	if(_onPlanet):
		# Update the direction of gravity
		gravityDirection = Utilities.CalculateGravityDirection(global_transform.origin)
	else:
		gravityDirection = Vector3(0,1,0)

	# Use a raycast for more 'reliable' ground checking
	var space_state = get_world().direct_space_state
	var colInfo = space_state.intersect_ray(global_transform.origin, global_transform.origin - gravityDirection.normalized(),[self],groundMask)
	Debug.DrawDebugLine(global_transform.origin , global_transform.origin - gravityDirection.normalized()/1.2 ,Color.yellow)
	# Check if the character is on the floor (as determined by 'UP' vector passed into move_and_slide)

	if(is_on_floor() || !colInfo.empty()):
		isOnGround = true
	else:
		#print(colInfo["collider"].get_owner().name)
		isOnGround = false

	if(is_on_floor() ):
		#If you apply gravity while on the ground, the object tends to slide. Applying *very* slight upwards gravity prevents this.
		currentGravityStrength = -0.01
		pass

	else:
		currentGravityStrength += gravityStrength * delta
		currentGravityStrength = clamp(currentGravityStrength,0.0,gravityStrength) 

	# Apply gravity to overall velocity
	velocity -= gravityDirection * currentGravityStrength 

	if(input_active):
		# Apply movement to overall velocity
		velocity += direction.normalized() * moveSpeed 
	else:
		pass

	# Smooth velocity with acceleration
	velocity = currentVelocity.linear_interpolate(velocity,delta * acceleration)


	if(is_instance_valid(self)):
		# Apply movement to character
		currentVelocity = move_and_slide(velocity, gravityDirection)

	# Reset velocity
	velocity = Vector3.ZERO
	Debug.DrawDebugTransform(_vis.global_transform)
	pass

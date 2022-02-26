extends Spatial

export var enabled = false

# The path to the skeleton we want to modify
export var skeletonPath:NodePath

# The name of the bone to modify
export var targetBoneName:String

# Should we respect the parent's tranform?
export var useParentTransform:bool = false

# Is the target registered in SceneResources?
export var isTargetGlobal:bool = false

# The path to the target (name of the target if in SceneResources)
export var targetPath:String = ""

# Locks for each axis
export var lockX:bool = false
export var lockY:bool = false
export var lockZ:bool = false

# Rotational limits around each axis
export var limitX:Vector2
export var limitY:Vector2
export var limitZ:Vector2

export(Vector3) var offset

export var rotLerpSpeed = 100.0

var skeleton:Skeleton
var targetBoneID

var previousRotY = 0

export var addToAnimation = false
export var targetName:String

var lookTargetPosition = Vector3.ZERO
var exiting:bool = false

var previousTargetTransform

func _ready():
	skeleton = get_node(skeletonPath)
	targetBoneID = skeleton.find_bone(targetBoneName)
	pass

# Smoothly return to transform
func SmoothExit():
	exiting = true
	pass

func _process(delta):
	# No-op if not enabled
	if(!enabled || skeleton == null):
		return

	# No-op if there is no target
	if(targetPath == ""):
		enabled = false
		return

	# Transform target into local axis 
	var targetPos = Vector3.ZERO

	if(isTargetGlobal):
		targetPos = SceneResources.GetResource(targetPath).global_transform.origin
	elif(exiting):
		enabled = false
		exiting = false
	else:
		targetPos = (get_node(targetPath) as Spatial).global_transform.origin
		targetName = (get_node(targetPath) as Spatial).name
	
	_LookAtTarget(targetPos,delta)

	# Check if we're done with our smooth exit
	if(exiting):
		var forward = skeleton.get_bone_global_pose(targetBoneID).origin + global_transform.basis.z.normalized()

		if(skeleton.get_bone_global_pose(targetBoneID).basis.z.normalized() == forward):
			exiting = false
			enabled = false

# Update the target we want to look at
func UpdateTarget(var newTargetPath):
	enabled = false
	targetPath = newTargetPath
	enabled = true
	pass


# Rotate bone to look towards a target object
func _LookAtTarget(var targetPos, var delta):

	# Bail if skeleton is not initalized
	if(skeleton == null):
		return

	var targetL = skeleton.global_transform.xform_inv(targetPos) + offset

	# Smooth look rotation
	targetL = lookTargetPosition.linear_interpolate(targetL,rotLerpSpeed * delta)
	var targetTransform = transform

	#print(targetTransform.basis.determinant())
	if(targetTransform.basis.determinant() < 0):
		return

	# Calculate look transform
	if(transform.origin - targetL != Vector3.UP && transform.basis.z.normalized().dot(-targetL.normalized()) != 0):
		if(targetL.length() != 0 && targetL.length() != 0):
			targetTransform = transform.looking_at(-targetL,Vector3.UP)
			pass

	# Can't orthonormalize zero vector
	if(targetTransform.basis.determinant() != 0):
		# "Lock" rotations on desired axes
		if(lockX):
			targetTransform = targetTransform.rotated((targetTransform.basis.orthonormalized()).x.normalized(),-targetTransform.basis.orthonormalized().get_euler().x)
		if(lockY):
			targetTransform = targetTransform.rotated((targetTransform.basis.orthonormalized()).y.normalized(),-targetTransform.basis.orthonormalized().get_euler().y)
		if(lockZ):
			targetTransform = targetTransform.rotated((targetTransform.basis.orthonormalized()).z.normalized(),-targetTransform.basis.orthonormalized().get_euler().z)
	
	
	# "Lock" rotations on desired axes
	if(limitX != Vector2.ZERO):
		var rot = -targetTransform.basis.get_euler().x
		targetTransform = targetTransform.rotated(targetTransform.basis.x.normalized(),rot - clamp(-rot,deg2rad(limitX.x),deg2rad(limitX.y)))
		pass

	if(limitY != Vector2.ZERO):
		#var rot = lerp(previousRotY,-Quat(targetTransform.basis).get_euler().y,delta * 1.0) 
		var rot = -targetTransform.basis.get_euler().y
		targetTransform = targetTransform.rotated(targetTransform.basis.y.normalized(),rot - clamp(rot,deg2rad(limitY.x),deg2rad(limitY.y)))

		# Prevent snapping around Y axis
		previousRotY = rot
		pass

	if(limitZ != Vector2.ZERO):
		var rot = -targetTransform.basis.get_euler().z
		targetTransform = targetTransform.rotated(targetTransform.basis.z.normalized(),rot- clamp(rot,deg2rad(limitX.x),deg2rad(limitX.y)))
		pass

	# Apply parent transform to this bone
	if(useParentTransform):
		# Prevent index out of bounds error for parent bone lookup
		if(skeleton.get_bone_parent(targetBoneID) == -1):
			printerr("No bone parent for " + skeleton.get_bone_name(targetBoneID) + " in " + name)
			print_stack()
			useParentTransform = false
			pass

		var parentBoneTransform = skeleton.get_bone_global_pose(skeleton.get_bone_parent(targetBoneID))
		var parentTransformRot = parentBoneTransform.basis.orthonormalized().get_rotation_quat()

		# Order of application probably matters (I'm almost sure it does), so this will probably be updated
		targetTransform = targetTransform.rotated(parentBoneTransform.basis.x.normalized(),parentTransformRot.x)
		targetTransform = targetTransform.rotated(parentBoneTransform.basis.y.normalized(),parentTransformRot.y)
		targetTransform = targetTransform.rotated(parentBoneTransform.basis.z.normalized(),parentTransformRot.z)

		pass

	var targetRot = Quat.IDENTITY

	# Can't orthonormalize zero vector
	if(targetTransform.basis.determinant() != 0):
		#print(targetTransform.basis)
		targetRot = targetTransform.basis.orthonormalized()
		pass

	#targetRot = Quat(skeleton.get_bone_global_pose(targetBoneID).basis).slerp(targetRot,delta * 8.0)
	# Set origin and rotation
	#targetTransform.basis = targetTransform.basis.slerp(targetRot,1.0)
	
	targetTransform = Transform( targetRot ,skeleton.get_bone_global_pose(targetBoneID).origin)

	# Apply to bone
	if(addToAnimation):
		# Add to position in current animation
		targetTransform.origin = Vector3.ZERO
		if(skeleton != null):
			skeleton.set_bone_pose(targetBoneID,targetTransform.orthonormalized())
	else:
		if(skeleton != null):
			# Just straight up overwrites the animation
			skeleton.set_bone_global_pose_override(targetBoneID,targetTransform.orthonormalized(),1.0,true)
	pass

	# Update look position (for lerping)
	lookTargetPosition = targetL
	pass

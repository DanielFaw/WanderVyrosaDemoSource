extends Spatial

export var skeleton_path:NodePath
var skeleton

export var boneName:String

var parent_bone_id
var local_bone_offset:Vector3

func _ready():
	skeleton = get_node(skeleton_path)

	var bone =  skeleton.find_bone(boneName)
	if(bone != null):
		print(bone)
		parent_bone_id = bone
		local_bone_offset = skeleton.get_bone_global_pose(parent_bone_id).xform(transform.origin).translation
	else:
		print("BONE IS NULL")
		print_stack()
	pass

func _process(_delta: float):
	if(parent_bone_id != null):
		self.transform = skeleton.get_bone_global_pose(parent_bone_id)
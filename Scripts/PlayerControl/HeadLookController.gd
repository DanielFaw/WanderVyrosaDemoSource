extends Node

var headBoneLook;

export var head_look_path:NodePath
var head_look

export var vis_path:NodePath
var vis
var current_target
func _ready():
	vis = get_node(vis_path)
	head_look = get_node(head_look_path)


	if(SceneResources.HasResource("Planet")):
		headBoneLook = $HeadBoneModifier
		headBoneLook.targetPath = head_look.get_path()

		var _nullArg
		_nullArg = SceneResources.GetResource("BuildingController").connect("buildModeToggled",self,"_BuildModeToggled")
		_nullArg = SceneResources.GetResource("BuildingController").connect("towerSelectionChanged",self,"_TowerSelectionChanged")
	pass

func _TowerSelectionChanged():
	current_target = SceneResources.GetResource("BuildingController")._currentTowerPrefabInst
	pass


func _process(_delta: float):

	if(current_target != null && SceneResources.GetResource("BuildingController").GetBuildingState()):
		var vec_to_target = vis.global_transform.origin - current_target.global_transform.origin
		var forward_dot_target = vec_to_target.normalized().dot(vis.global_transform.basis.z.normalized())
		
		if(forward_dot_target < -0.3):
			head_look.global_transform.origin = vis.global_transform.origin - vec_to_target.normalized()
		# TODO: Ethan 
		#else:
		#	head_look.global_transform.origin = vis.global_transform.origin + Vector3(-vec_to_target.x,vec_to_target.y,vec_to_target.z)
		#pass

	pass

func _BuildModeToggled(var inBuildMode):
	if(inBuildMode):
		headBoneLook.enabled = true;
	else:
		headBoneLook.SmoothExit()

	pass

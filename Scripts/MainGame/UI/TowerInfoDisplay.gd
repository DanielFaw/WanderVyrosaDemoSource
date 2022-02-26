extends Node

export var resources_list_path:NodePath
export var cost_list_path:NodePath

export var tower_description_path:NodePath
export var tower_name_path:NodePath
export var tower_info_path:NodePath

var resources_list:RichTextLabel
var cost_list:RichTextLabel
var tower_description:RichTextLabel
var tower_name:RichTextLabel
var tower_info:Control

export var metal_label : NodePath
export var quartz_label : NodePath
export var silicon_label : NodePath
export var boomstone_label : NodePath

var cost_labels

const RESOURCE_TYPES = preload("res://Scripts/MainGame/ResourceType.gd")

var resources = {}

func _ready():
	resources_list = get_node(resources_list_path)
	#cost_list = get_node(cost_list_path)

	tower_description = get_node(tower_description_path)
	tower_name = get_node(tower_name_path)
	tower_info = get_node(tower_info_path)
	tower_info.visible = false;

	# Initialize dictionary
	for i in RESOURCE_TYPES.TYPE:
		resources[i] = 0
		
	var _e = SceneResources.GetResource("BuildingController").connect("resourceAmountChanged",self,"_UpdateResourceCount")
	_e = SceneResources.GetResource("BuildingController").connect("buildModeToggled",self,"_ToggleCostDisplay")
	_e = SceneResources.GetResource("BuildingController").connect("towerSelectionChanged",self,"_UpdateInfo")

	cost_labels = {
		0 : metal_label,
		1 : quartz_label,
		2 : silicon_label,
		3 : boomstone_label
		}
	
	pass

	
func _ToggleCostDisplay(var in_build_mode):
	if(!in_build_mode):
		tower_info.visible = false;
	else:
		_UpdateInfo()
		tower_info.visible = true;
	pass

func _UpdateResourceCount(_null1, _null2):
	_UpdateInfo()
	pass

func _UpdateInfo():
	#cost_list.clear()
	if(!SceneResources.GetResource("BuildingController").GetBuildingState()):
		return

	var cost = SceneResources.GetResource("BuildingController").GetCurrentTowerCost()
	#var cost_text = ""
	var _null

	for res in cost.keys():
		if(SceneResources.GetResource("BuildingController").GetResourceAmount(res) < cost[res]):
			_null = get_node(cost_labels[res]).parse_bbcode("[center][color=red]" + str(cost[res]) + "[/color][/center]")
			pass
		else:
			_null = get_node(cost_labels[res]).parse_bbcode("[center][color=green]" + str(cost[res]) + "[/color][/center]")
			pass
		pass

	# = cost_list.parse_bbcode(cost_text)
	_null = tower_name.parse_bbcode("[center]" + SceneResources.GetResource("BuildingController").GetCurrentTowerResource().GetDisplayName() + "[/center]");

	var info_string = "";

	info_string += "Type: " + SceneResources.GetResource("BuildingController").GetCurrentTowerResource().GetType() + "\n"
	info_string += "\n"
	info_string += "Description: " + SceneResources.GetResource("BuildingController").GetCurrentTowerResource().GetDescription() + "\n"

	_null = tower_description.parse_bbcode(info_string);
	pass


func _exit_tree():

	# Disconnect all events
	if(SceneResources.GetResource("BuildingController").is_connected("resourceAmountChanged",self,"_UpdateResourceCount")):
		SceneResources.GetResource("BuildingController").disconnect("resourceAmountChanged",self,"_UpdateResourceCount")
		pass
	if(SceneResources.GetResource("BuildingController").is_connected("buildModeToggled",self,"_ToggleCostDisplay")):
		SceneResources.GetResource("BuildingController").disconnect("buildModeToggled",self,"_ToggleCostDisplay")
		pass

extends Resource
class_name TowerResource

export var _towerModel:PackedScene
export var _towerPrefab:PackedScene

export var _modelScale:Vector3

export var _overridePlacementBounds = false

export var _towerName:String = ""
export var _displayName:String = ""

export var _towerType:String = ""
export var _towerDescription:String = ""

var _buildCost = {};

const RESOURCE_TYPE = preload("res://Scripts/MainGame/ResourceType.gd")

# Indiviual build costs
export var _metalCost:int = 0;
export var _quartzCost:int = 0;
export var _siliconCost:int = 0;
export var _boomStoneCost:int = 0;

# Get the resource build cost for this tower
func GetBuildCost()->Dictionary:

	# Initialize dict only if necessary
	if(_buildCost.empty()):
		_buildCost[RESOURCE_TYPE.TYPE.Metal] = _metalCost
		_buildCost[RESOURCE_TYPE.TYPE.Quartz] = _quartzCost
		_buildCost[RESOURCE_TYPE.TYPE.Silicon] = _siliconCost
		_buildCost[RESOURCE_TYPE.TYPE.BoomStone] = _boomStoneCost

	return _buildCost

func GetTowerName():
	return _towerName

func GetDisplayName():
	return _displayName

func GetDescription():
	return _towerDescription;

func GetType():
	return _towerType;

func GetOverridePlacement():
	return _overridePlacementBounds

# Get the model scene for this tower
func GetTowerModel()->PackedScene:
	return _towerModel
	pass;

func GetTowerPrefab()->PackedScene:
	return _towerPrefab
	pass;
	
func GetTowerModelScale()->Vector3:
	return _modelScale

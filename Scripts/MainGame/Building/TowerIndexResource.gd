extends Node

const _index = preload("res://CustomResources/R_TowerIndex.tres")

func _init():
	SceneResources.RegisterResource("TowerIndex",self)
	pass


# -------------------FUNCTIONS-----------------------------------------------
func GetTower(var name:String):
	return _index.GetTower(name)
	pass

func GetTowerModel(var name:String):
	return _index.GetTowerModel(name)
	pass

func GetTowerCost(var name:String):
	return _index.GetTowerCost(name)
	pass

func GetTowerNameAtIndex(var index:int):
	return _index.GetTowerNameAtIndex(index)
	pass
func GetTowerCount():
	return _index.GetTowerCount()
	pass

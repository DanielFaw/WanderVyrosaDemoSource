extends Resource
class_name TowerIndex

# This class acts as a central lookup for tower information 
# 	including: build cost and a way to get the towerfile globally

# A dictionary containing a map of towerName(String):towerResourceFile(TowerResource)
export(Dictionary) var _towerIndex;

# Returns the resource for a tower
func GetTower(var name:String):
	if(_towerIndex.has(name)):
		return _towerIndex[name]
	else:
		if(OS.is_debug_build()):
			printerr("TOWER " + str(name) + " DOES NOT EXIST IN THE TOWER INDEX")
			print("------------STACK TRACE------------")
			print_stack()
			print("-----------------------------------")
		return null
	pass

func GetTowerModel(var name:String):
	if(_towerIndex.has(name)):
		return _towerIndex[name].GetTowerModel()
	else:
		if(OS.is_debug_build()):
			printerr("TOWER " + str(name) + " DOES NOT EXIST IN THE TOWER INDEX")
			print("------------STACK TRACE------------")
			print_stack()
			print("-----------------------------------")
		return null
	pass

func GetTowerCost(var name:String):
	if(_towerIndex.has(name)):
		return _towerIndex[name].GetBuildCost()
	else:
		if(OS.is_debug_build()):
			printerr("TOWER " + str(name) + " DOES NOT EXIST IN THE TOWER INDEX")
			print("------------STACK TRACE------------")
			print_stack()
			print("-----------------------------------")
		return null
	pass


func GetTowerNameAtIndex(index:int):
	if(_towerIndex.size() -1 < index || index < 0):
		return ""
	else:
		return _towerIndex.keys()[index]

	pass
func GetTowerCount():
	return _towerIndex.size()
	

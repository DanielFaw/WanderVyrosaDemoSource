extends Resource
class_name EnemyIndex

# This class acts as a central lookup for enemy information 
# 	including: name and prefab

# A dictionary containing a map of towerName(String):towerResourceFile(TowerResource)
export(Dictionary) var _enemyIndex;


func GetEnemyPrefab(var name:String):
	if(_enemyIndex.has(name)):
		return _enemyIndex[name].GetEnemyPrefab();
	else:
		if(OS.is_debug_build()):
			printerr("ENEMY OF NAME: " + name + " DOES NOT EXIST IN ENEMY INDEX")
			print("------------STACK TRACE------------")
			print_stack()
			print("-----------------------------------")
		return null
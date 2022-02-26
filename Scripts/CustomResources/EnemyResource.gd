extends Resource
class_name EnemyResource

export var _enemyName:String = "UNDEFINED"

export var _enemyPrefab:PackedScene

func GetEnemyName():
	return _enemyName

func GetEnemyPrefab():
	return _enemyPrefab
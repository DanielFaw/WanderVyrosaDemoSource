extends Resource
class_name SceneIndex

export var sceneIndex = {};

func GetScenePath(name):
	if(sceneIndex.has(name)):
		return sceneIndex[name];
	pass
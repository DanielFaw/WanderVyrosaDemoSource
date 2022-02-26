extends Node

func OnPress():
	SceneResources.GetResource("WaveManager").StartLevel();
	self.visible = false

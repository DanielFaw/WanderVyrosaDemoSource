extends Control

func _process(_delta: float):
	if(Input.is_action_just_released("toggle_ui")):
		self.visible = !self.visible
	pass

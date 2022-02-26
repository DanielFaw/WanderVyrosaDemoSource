extends Node

export var health_bar_path:NodePath

var health_bar:ProgressBar

func _ready():
	var _e = SceneResources.GetResource("PlayerBase").connect("baseTookDamage",self,"_UpdateHealth")
	health_bar = get_node(health_bar_path);
	pass


func _UpdateHealth(newHealthPercentage):
	health_bar.value = newHealthPercentage;
	pass


func _exit_tree():
	if(SceneResources.GetResource("PlayerBase").is_connected("baseTookDamage",self,"_UpdateHealth")):
		SceneResources.GetResource("PlayerBase").disconnect("baseTookDamage",self,"_UpdateHealth")
		pass

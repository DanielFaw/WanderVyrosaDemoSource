extends Spatial

export var landing_cutscene_manager_path:NodePath

var is_active
func _ready():
	var _connection_result =SceneResources.GetResource("GameStateManager").connect("onGameOver",self,"GameOver")
	visible = false
	pass


func _exit_tree():
	if(SceneResources.GetResource("GameStateManager").is_connected("onGameOver",self,"GameOver")):
		SceneResources.GetResource("GameStateManager").disconnect("onGameOver",self,"GameOver")
		pass
	pass

func GameOver(_win_loss):
	is_active = true
	visible = true
	pass


func BodyEntered(_new_body):
	if(is_active):
		get_node(landing_cutscene_manager_path).TakeoffAnim()
	return

extends Area

export var node_to_show_on_interact_path:NodePath
var node_to_show_on_interact


export var interact_prompt:NodePath

var ready_to_open:bool = false


func _ready():
	if(node_to_show_on_interact_path != ""):
		node_to_show_on_interact = get_node(node_to_show_on_interact_path)
		var _connection = connect("body_entered",self,"OnPlayerEnter")
		_connection = connect("body_exited",self,"OnPlayerExit")
	pass




func _input(event: InputEvent):
	if(event is InputEventKey):
		
		pass
	pass


func _process(_delta: float):
	if(Input.is_action_just_released("player_interact") && ready_to_open):
		node_to_show_on_interact.visible = true
		SceneResources.GetResource("Player").SetPlayerInputActive(false)
		InputState.ToggleCursor(true)
		pass
	pass

func OnPlayerEnter(_player):
	ready_to_open = true
	get_node(interact_prompt).visible = true

	pass

func OnPlayerExit(_body_exiting):
	ready_to_open = false
	node_to_show_on_interact.visible = false
	get_node(interact_prompt).visible = false
	SceneResources.GetResource("Player").SetPlayerInputActive(true)
	InputState.ToggleCursor(false)
	pass

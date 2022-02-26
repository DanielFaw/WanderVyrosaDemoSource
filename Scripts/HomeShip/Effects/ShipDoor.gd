extends Node

var players_in_bounds = []

# Paths
export var door_top_path:NodePath
export var door_bottom_path:NodePath
export var door_collider_path:NodePath
export var tween_path:NodePath

# References
var door_top
var door_bottom
var door_collider
var tween
var is_door_open = false

export var is_door_locked:bool = false

func _ready():
	# Init references
	door_top = get_node(door_top_path)
	door_bottom = get_node(door_bottom_path)
	door_collider = get_node(door_collider_path)
	pass

func _OnBodyEnter(var body):

	# Ignore player if the door is locked
	if(is_door_locked):
		return
		pass


	if(!players_in_bounds.has(body)):
		players_in_bounds.append(body)
		pass
	if(!is_door_open):
		_OpenDoor()
		pass
	pass

func _OnBodyExit(var body):
	if(players_in_bounds.has(body)):
		players_in_bounds.remove(players_in_bounds.find(body))
		pass
	if(players_in_bounds.empty() && is_door_open):
		_CloseDoor()
		pass
	pass


func _OpenDoor():
	is_door_open = true

	if(tween == null):
		tween = get_node(tween_path)
	# Do Tween Stuff
	tween.interpolate_property(door_top,"translation",Vector3(0,door_top.translation.y,0),Vector3(0,2.174,0),0.25,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	tween.interpolate_property(door_bottom,"translation",Vector3(0,door_bottom.translation.y,0),Vector3(0,-0.192,0),0.25,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	tween.start()

	# Disable the collider
	door_collider.disabled = true
	
	pass

func _CloseDoor():
	is_door_open = false

	if(tween == null):
		tween = get_node(tween_path)

	# Do Tween Stuff
	tween.interpolate_property(door_top,"translation",Vector3(0,door_top.translation.y,0),Vector3(0,1.0090,0),0.25,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	tween.interpolate_property(door_bottom,"translation",Vector3(0,door_bottom.translation.y,0),Vector3(0,1.009,0),0.25,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	tween.start()

	# Enable the collider
	door_collider.disabled = false
	
	pass

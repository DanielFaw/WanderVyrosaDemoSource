extends Spatial


export var move_speed:float = 1.0
export var target_path:NodePath

# TODO: Add rotation matching and accessor/modifier functions

var target:Spatial

func _ready():
	target = get_node(target_path)
	if(target != null):
		global_transform.origin = target.global_transform.origin
		pass
	pass

func _process(delta: float):
	if(target != null):
		global_transform.origin = lerp(global_transform.origin,target.global_transform.origin,move_speed * delta)
		global_transform.basis = target.global_transform.basis.orthonormalized()
	pass


func SetTarget(new_target:Spatial):
	target = new_target
	target_path = new_target.get_path()
	return

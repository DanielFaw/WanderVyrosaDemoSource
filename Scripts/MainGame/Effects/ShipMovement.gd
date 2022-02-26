extends Spatial
export var bobSpeed:float = 1;
export var bobMagnitude:float = 1;

export var rotSpeed:float = 1;
export var rotMagnitude:float = 1;


export var shipPath:NodePath
var ship;


var startGlobalY;
var time = 0;

func _ready() -> void:
	ship = get_node(shipPath)

	pass

func _process(delta: float):
	time += delta;
	ship.translation.y = sin(time * bobSpeed) * bobMagnitude
	ship.rotation.x =  cos(time * rotSpeed) * rotMagnitude

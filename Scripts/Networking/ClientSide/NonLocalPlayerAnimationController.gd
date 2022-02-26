extends Spatial

#---LOADS--------------


#---EXPORTS------------

# The player movement controller
export var playerControllerPath:NodePath

export var playerModelPath:NodePath


#----------------------

#---REFERENCES---------

var _playerController
var _animationTree:AnimationTree

#----------------------


# Called when the node enters the scene tree for the first time.
func _ready():
	_playerController = get_node(playerControllerPath)
	_animationTree = get_node(playerModelPath).find_node("AnimationTree")



	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#TODO - Update with directional input + left/right strafe
	#TODO - Add transitions between different state machine states (if needed)

	var flatVelocity = _playerController.currentVelocity
	flatVelocity.y = 0.0
	if(flatVelocity.length() > 1.0):
		
		_animationTree.set("parameters/Grounded/B_Idle_Move/blend_amount",lerp(_animationTree.get("parameters/Grounded/B_Idle_Move/blend_amount"),1.0,delta * _playerController.acceleration))
		_animationTree.set("parameters/Grounded/B_Run_Walk/blend_amount",1.0)

	else:
		_animationTree.set("parameters/Grounded/B_Idle_Move/blend_amount",lerp(_animationTree.get("parameters/Grounded/B_Idle_Move/blend_amount"),0.0,delta * _playerController.acceleration))

	pass

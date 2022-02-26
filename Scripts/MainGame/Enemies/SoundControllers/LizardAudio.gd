extends Spatial

export var _leftFootSoundPath:NodePath
export var _rightFootSoundPath:NodePath

var _leftFootSound:AudioStreamPlayer3D
var _rightFootSound:AudioStreamPlayer3D

export var _enemyControllerPath:NodePath
var _enemyController

export(Vector2) var pitchVariationRange = Vector2(0.8,1.1);


func _ready():
	_leftFootSound = get_node(_leftFootSoundPath)
	_rightFootSound = get_node(_rightFootSoundPath)
	_enemyController = get_node(_enemyControllerPath)

	pass

func _StepLeft():

	var pitch = Utilities.GetRandomValue(pitchVariationRange.y,pitchVariationRange.x)	

	if(_leftFootSound.playing):
		_leftFootSound.stop()

	_leftFootSound.pitch_scale = pitch
	_leftFootSound.play()
	pass
func _StepRight():

	var pitch = Utilities.GetRandomValue(pitchVariationRange.y,pitchVariationRange.x)		

	if(_rightFootSound.playing):
		_rightFootSound.stop()
	_rightFootSound.pitch_scale = pitch
	_rightFootSound.play()
	pass

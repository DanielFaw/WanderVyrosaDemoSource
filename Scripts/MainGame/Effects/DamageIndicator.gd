extends Sprite3D

export var _label_path:NodePath
var _timer:Timer
var _start_y_translation:float;
#export var scale_bounds:Vector2 = Vector2(1.0,2.0)
var _scaleDelta = 0.1;
export var _color_bounds:Vector2 = Vector2(1.0, 20.0)
export var _color_gradient:Gradient;

func _ready():
	texture = $Viewport.get_texture()
	#SetDamageText(1,1)
	pass

func _physics_process(delta: float):
	translation.y += delta / 2.0
	pass

	#TODO: Pool these

func SetInitialY(initialY:float):
	_start_y_translation = initialY
	translation.y = initialY
	pass
func SetDamageText(_damage, health_percent):
	# Create a _timer to automatically delete this object after a period of time
	if(_timer == null):
		_timer = Timer.new()
		add_child(_timer)
		var _null = _timer.connect("timeout",self,"queue_free")
		pass
	_timer.set_wait_time(2)
	_timer.start()


	translation.y = _start_y_translation

	var _color = _color_gradient.interpolate(1-health_percent)

	get_node(_label_path).custom_effects[0].resetTimer = true
	get_node(_label_path).parse_bbcode("[fadeLine offset=0.5 colorHex=" + str(_color.to_html()) +"]" + str(_damage) + "[/fadeLine]")
	
	pass

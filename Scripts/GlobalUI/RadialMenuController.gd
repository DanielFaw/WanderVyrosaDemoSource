extends Control


export var option_prefab:PackedScene

export var tween_path:NodePath

export var ring_path:NodePath

export var pointer_path:NodePath

var ring
var pointer 

# Dictionary of option names (string) to their Icons (Texture)
export var options:Dictionary = {}
export var option_initial_offset_deg:float = -90

export(Array,String) var option_order

var option_dict:Dictionary = {}

var target_position_dict:Dictionary = {}

# The rad difference between each option
var option_offset = 0.0

# The radius of the circle (in px)
var radius:float = 200.0

var tween:Tween

var ring_initial_scale:Vector2
var ring_initial_size:Vector2

export var label_path:NodePath
var label:Label
var label_initial_position:Vector2

signal selection_changed(new_selection)
signal menu_closed
signal menu_opened

var enabled:bool = false


var last_selection:String = ""

var current_selection: = ""

func _init():
	# Preload all textures in the dictionary of options

	#print(rect_size.x)
	for option in options:
		var loaded_texture = load(options[option].load_path);
		options[option] = loaded_texture
		pass

	pass


func _ready():

	tween = get_node(tween_path)
	label = get_node(label_path)
	pointer = get_node(pointer_path)
	ring = get_node(ring_path)
	ring_initial_scale = ring.rect_scale
	ring_initial_size = ring.rect_size
	label_initial_position = label.rect_position
	
	if(options.empty()):
		print_debug("Radial Menu has no options!")
		print(self.name)
		pass
	else:
		# The radial difference between each option
		option_offset = (2.0 * PI) / options.size()
		
		# Instance all options
		for option in option_order:
			# Find the index of this option in the dictionary for math/placement purposes
			var index = option_order.find(option)
			var new_option = option_prefab.instance()

			new_option.SetIcon(options[option])
			option_dict[option] = new_option

			var option_center_offset = Vector2(new_option.rect_size.x/2.0,new_option.rect_size.y/2.0)
			
			target_position_dict[option] = Vector2(cos(option_offset * index - deg2rad(option_initial_offset_deg)) * radius - option_center_offset.x,-sin(option_offset * index - deg2rad(option_initial_offset_deg)) * radius - option_center_offset.y)
			#print()
			# Set target position
			new_option.rect_position = target_position_dict[option]
			call_deferred("add_child",new_option)
			pass

		pass

	visible = false
	_CloseMenu()
	pass


func _input(event):
	if event is InputEventMouseMotion:

		# Ignore input if menu isn't active
		if(!enabled):
			return
			pass

		var mouse_position = InputState.GetCursorPosition()

		# Figure out the current selection based oun the mouse position
		# TODO: Update this to take into account non-centered radial menus
		var centered_mouse = Vector2(mouse_position.x - get_viewport().get_visible_rect().size.x /2.0 ,mouse_position.y - get_viewport().get_visible_rect().size.y /2.0).normalized()
		var mouse_rad = atan2(centered_mouse.y,centered_mouse.x) 

		pointer.rect_rotation = rad2deg(mouse_rad) + 90.0
		var angle = 2.0 * PI - fmod(mouse_rad + (PI * 2.0) - deg2rad(option_initial_offset_deg) ,(PI * 2.0))
		var selection = round(angle/(2.0 * PI)/ (1.0/options.size()))

		if(selection > options.size() -1):
			selection = 0
			pass

		current_selection = option_order[selection]

		# Check if last_selection has been set yet
		if(last_selection == ""):
			last_selection = current_selection
			pass

		
		# TODO: Highlight the new selection
		if(current_selection != last_selection):
			var _callback = tween.interpolate_property(option_dict[current_selection],"rect_scale",null,Vector2(1.25,1.25),0.05,Tween.TRANS_BOUNCE,Tween.EASE_IN_OUT)
			_callback = tween.interpolate_property(option_dict[last_selection],"rect_scale",null,Vector2(1.0,1.0),0.05,Tween.TRANS_BOUNCE,Tween.EASE_IN_OUT)
			_callback = tween.start()
			#option_dict[current_selection].rect_scale = Vector2(1.25,1.25)
			#option_dict[last_selection].rect_scale = Vector2.ONE
			pass
			
		# Change Label text
		label.text = option_order[selection]

		# Check if the current selection has changed
		if(current_selection != last_selection):
			emit_signal("selection_changed",current_selection)
			last_selection = current_selection
			#print("Selection changed to " + str(current_selection))
			pass
	
		pass
	pass


func GetCurrentSelection():
	return current_selection
	pass


# Open the radial menu
func _OpenMenu():

	# Setup tween animations
	var _tween_callback = tween.interpolate_property(ring,"rect_scale",null,ring_initial_scale,0.2,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
	_tween_callback = tween.interpolate_property(label,"rect_position",null,label_initial_position,0.2,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)

	for option in options:
		var option_object = option_dict[option]
		var option_center_offset = Vector2(option_object.rect_size.x/2.0,option_object.rect_size.y/2.0)
		var ring_center = ring.rect_position + Vector2(ring_initial_size.x / 2.0,ring_initial_size.y / 2.0)
		_tween_callback = tween.interpolate_property(option_object,"rect_position",ring_center - option_center_offset,ring_center + target_position_dict[option],0.2,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
		pass

	visible = true
	var _started = tween.start()
	enabled = true

	emit_signal("menu_opened")
		
	pass


func _CloseMenu():
	enabled = false
	# Setup tween animations
	var _tween_callback = tween.interpolate_property(ring,"rect_scale",null,Vector2(0.01,0.01),0.2,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
	var ring_center = ring.rect_position + Vector2(ring_initial_size.x / 2.0,ring_initial_size.y / 2.0)
	_tween_callback = tween.interpolate_property(label,"rect_position",null,ring_center - label.rect_size/2.0,0.2,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)

	for option in options:
		var option_object = option_dict[option]
		var option_center_offset = Vector2(option_object.rect_size.x/2.0,option_object.rect_size.y/2.0)
		_tween_callback = tween.interpolate_property(option_object,"rect_position",null,ring_center - option_center_offset,0.2,Tween.TRANS_QUAD,Tween.EASE_IN_OUT)
		pass


	var _started = tween.start()
	emit_signal("menu_closed")

	# Wait for animation to finish and make invisible
	yield(get_tree().create_timer(0.15),"timeout")
	visible = false
	
	pass

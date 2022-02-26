extends Node

export var label_path:NodePath
var label

export var slider_path:NodePath
var slider

func _ready() -> void:
	slider = get_node(slider_path)
	label = get_node(label_path)
	pass


func OnSliderChange(new_value):
	label.text = str(new_value) + "%"
	pass

func GetCurrentValue():
	return slider.value
	pass


func SetSliderValue(new_value):
	if(slider == null):
		slider = get_node(slider_path)
	slider.value = new_value
	OnSliderChange(new_value)
	pass


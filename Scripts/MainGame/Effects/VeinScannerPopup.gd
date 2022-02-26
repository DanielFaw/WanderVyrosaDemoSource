extends Node

export var type_label_path:NodePath
var type_label


export var density_value_path:NodePath
var density_value_label


func _ready():
	density_value_label = get_node(density_value_path)
	type_label = get_node(type_label_path)
	pass

func SetDisplayData(data):
	density_value_label.text = str(data["density"]).pad_decimals(1)
	var type_text = ""

	# Match the incoming data value
	match(data["type"]):
		"0":
			type_text = "Metal"
			pass
		"1":
			type_text = "Quartz"	
			pass
		"2":
			type_text = "Silicon"	
			pass
		"3":
			type_text = "Boomstone"
			pass
		_:
			pass

	type_label.text = type_text

	pass

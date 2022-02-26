extends HBoxContainer




var current_resource_count = {
	0 : 0,
	1 : 0,
	2 : 0,
	3 : 0
}
var current_resource_generation = {
	0 : 0,
	1 : 0,
	2 : 0,
	3 : 0
}

var current_delta = {
	0 : 0,
	1 : 0,
	2 : 0,
	3 : 0
}

var delta_counter : float = 0
var delta_stepped : float = 3.0


func _ready() -> void:
	var _e = SceneResources.GetResource("BuildingController").connect("resourceAmountChanged",self,"_UpdateResourceCount")
	_e = SceneResources.GetResource("BuildingController").connect("resources_set",self,"_SetDefaultResources")
	pass
	
func _SetDefaultResources(var params):
	for i in params.keys():
		current_resource_count[i] = floor(params[i])
		visualize_data(i, current_resource_count[i])
		pass
	pass
	
func _UpdateResourceCount(var type : int, var new_amount : float):
	var delta_count = new_amount - current_resource_count[type]
	current_resource_count[type] = new_amount
	visualize_data(type, current_resource_count[type])
	if(delta_count > 0):
		delta_increase(type, delta_count)
	pass

func visualize_data(var idx : int, var stepified_amnt : float):
	get_child(idx).get_node("HBoxContainer/Label").text = str(floor(stepified_amnt))

	pass

func delta_increase(var type : int, var amnt : float):
	#Add to the average resource generation
	current_delta[type] += amnt
	pass

func visualize_delta():
	for i in current_delta.keys():
		get_child(i).get_node("HBoxContainer/RichTextLabel").parse_bbcode(str(stepify(current_delta[i] / delta_stepped, 0.1)))
		pass
	pass

func _process(delta: float) -> void:
	delta_counter += delta
	if(delta_counter > delta_stepped):
		#Visualize the data and flush the delta
		visualize_delta()
		current_delta = {0:0, 1:0, 2:0, 3:0}
		delta_counter = 0
		pass
	
	pass
















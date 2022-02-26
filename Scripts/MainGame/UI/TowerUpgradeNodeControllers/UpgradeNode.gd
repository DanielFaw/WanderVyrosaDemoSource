extends Button
#class_name UpgradeNodeBase

#Get a list of objects that came before
#export (Array, NodePath) var previous_nodes = []
var previous_nodes = []

export var is_root = false
#Get a list of objects that come after
export (Array, NodePath) var next_nodes = []

#Get a list of objects that purchasing this will block
export (Array, NodePath) var blocked_nodes = []

#Set a cost
export var upgrade_price : int = 1

#Set a description
export var description : String = "desc"

var formatted_changes : String = "[color=purple]*TODO: ADD CHANGELOG[/color]"

export var specific_changes : Dictionary = {}

#Set a name
export var upgrade_name : String = "defname"

var tower_resource : Resource

export var is_bought = false
var is_blocked = false
var has_loaded = false
var m_stats

var adopted_children = []



#export var my_icon : Image

var description_panel

func _ready():
	connect("pressed", self, "_do_click")
	description_panel = get_node("../../../UpgradeDescription")
	#m_stats = tower_resource.GetAllStats()
	#can_be_viewed()
	if(is_root):
		for i in range(next_nodes.size()):
			get_node(next_nodes[i]).add_prev_node(get_node(next_nodes[i]).get_path_to(self))
			pass
		upgrade_bought()
		can_be_viewed()
		pass
	#try_draw_line()
	has_loaded = true
	pass

func add_prev_node(var n):
	previous_nodes.append(n)
	for i in range(next_nodes.size()):
		if next_nodes[i] != null && !next_nodes[i].is_empty():
			get_node(next_nodes[i]).add_prev_node(get_node(next_nodes[i]).get_path_to(self))
			pass
		pass
	if(can_be_bought()):
		try_draw_line_rev()
		pass
	can_be_viewed()
	pass

func gen_formatted_changes():
	var return_string = ""
	
	#If there are blocked nodes, tell the player what upgrades they won't be able to buy first
	for i in range(blocked_nodes.size()):
		return_string += "[color=yellow]" + "Purchase will block " + get_node(blocked_nodes[i]).upgrade_name + "[/color]\n"
		pass
	
	for var_to_change in specific_changes.keys():
		var str_to_enum = TStat.str_to_enum(var_to_change)
		m_stats = tower_resource.GetAllStats()
		assert(m_stats.size() > 0)
		var b_better = TStat.better_plus(str_to_enum)
		var is_green = false
		var is_plus = false
		var mechanic_unlocker = TStat.mechanic_unlocker(str_to_enum)
		if(specific_changes[var_to_change] > 0):
			is_plus = true
		#If the number gets bigger, use a +
		if(b_better && is_plus):
			is_green = true
		elif(!b_better && !is_plus):
			is_green = true
		#If the number gets smaller, use a -
		#If the upgrade is a new mechanic, wrap it in purple text
		
		#If the upgrade is good, wrap it in green text
		
		#If the upgrade is bad, wrap it in red text
		
		#If the upgrade is a new mechanic, wrap it in purple text
		if(mechanic_unlocker):
			return_string += "[color=purple]"
			pass
		elif(is_green):
			return_string += "[color=green]"
			pass
		else:
			return_string += "[color=red]"
		
		
		
		if(mechanic_unlocker):
			return_string += "*"
			return_string += TStat.get_unlocker_description(str_to_enum)
			pass
		else:
			if(is_plus):
				return_string += "+"
			else:
				return_string += "-"
			return_string += TStat.enum_to_str(str_to_enum) #This is absolutely vile. mined_amount += amount_mined type beat
			return_string += " (" + str(m_stats[str_to_enum]) + " -> " + str(m_stats[str_to_enum] + specific_changes[var_to_change]) + ")"
			pass
		
		
		return_string += "[/color]\n"
		pass

	return return_string
	pass

func _do_click():
	#Tell the panel what information to display
	if !is_bought:
		formatted_changes = gen_formatted_changes()
	send_upgrade_info()
	pass

func adopted_children_visibility(var value):
	for i in range(adopted_children.size()):
		adopted_children[i].visible = value
	pass
func adopt_child(var node):
	adopted_children.append(node)
	pass
func can_be_viewed():
	#Only returns true if all previous_nodes' is_bought are true, or if the list is null
	
	if(can_be_bought()):
		visible = true
		adopted_children_visibility(true)
		pass
	else:
		visible = false
		adopted_children_visibility(false)
		pass
	return
	
	
	
	
	if(is_blocked):
		visible = false
		#disabled = true
		adopted_children_visibility(false)
		
		#print("blocked, invisible")
		return
	
	if(previous_nodes == null || previous_nodes.size() == 0):
		#print("no previous nodes, visible")
		visible = true
		#disabled = false
		return

	for i in range(previous_nodes.size()):
		if get_node(previous_nodes[i]).is_bought == false:
			if(!get_node(previous_nodes[i]).is_root):
				visible = false
				adopted_children_visibility(false)
				return
		pass
	visible = true
	#disabled = false
	adopted_children_visibility(true)
	#print("no reason to not show up, visible")
	return

func send_upgrade_info():
	if can_be_bought():
		formatted_changes = gen_formatted_changes()
	elif !is_root:
		formatted_changes = "[color=yellow]This upgrade has already been purchased![/color]"
	else:
		formatted_changes = ""
		pass
	description_panel.UpdateInformation(upgrade_name, description, formatted_changes, is_bought, upgrade_price, self)
	pass


func upgrade_bought():
	formatted_changes = gen_formatted_changes()
	#try_draw_line()
	apply_upgrade_changes()
	
	for i in range(next_nodes.size()):
		get_node(next_nodes[i]).try_draw_line_rev()
		pass
	
	
	#send_upgrade_info()
	for i in range(blocked_nodes.size()):
		#get_node(blocked_nodes[i]).is_bought = true
		get_node(blocked_nodes[i]).is_blocked = true
	
	if !has_loaded:
		return
		
	for i in range(next_nodes.size()):
		var node = get_node(next_nodes[i])
		if node.can_be_bought() && !node.is_blocked:
			node.send_upgrade_info()
			return
		pass
	send_upgrade_info()

	pass

func apply_upgrade_changes():
	for i in specific_changes:
		#print("applying upgrades...")
		tower_resource.AccessStats(TStat.str_to_enum(i), "addupgrade", specific_changes[i])
		pass
	is_bought = true
	pass

func try_draw_line_rev():
	if(previous_nodes == null || previous_nodes.size() == 0):
		return
	for i in range(previous_nodes.size()):
		#if any nodes aren't bought, return
		if(!get_node(previous_nodes[i]).is_bought || get_node(previous_nodes[i]).is_blocked):
			return
		pass
		
	for i in range(previous_nodes.size()):
		if(previous_nodes[i] == null):
			return
		var prev_node = get_node(previous_nodes[i])
		if(prev_node.is_blocked):
			return
		if(!prev_node.is_bought):
			return
			
			
		var my_line = Line2D.new()
		#add_child(my_line)
		get_parent().call_deferred("add_child", my_line)
		call_deferred("adopt_child", my_line)
		#adopted_children.append(get_node(my_line))
		
		my_line.position = Vector2(0,0)
		my_line.default_color = Color.purple
		my_line.width = 2.0
		my_line.show_behind_parent = true
		
		var mid_this = get_line_pos()
		var mid_that = prev_node.get_line_pos()
	
		
		my_line.add_point(mid_this)
		my_line.add_point(mid_that)
		
		
		pass
	pass

func can_be_bought():
	#Returns true if all of the node's children are enabled and this isn't blocked
	if is_blocked:
		return false
	for i in range(previous_nodes.size()):
		var n = get_node(previous_nodes[i])
		if(!n.is_bought || n.is_blocked):
			return false
		pass
	for i in range(next_nodes.size()):
		var n = get_node(next_nodes[i])
		if(n.is_blocked):
			#return false
			pass
	for i in range(blocked_nodes.size()):
		var n = get_node(blocked_nodes[i])
		if(n.is_bought):
			return false
		pass
	return true

func get_line_pos():
	return rect_position + rect_scale * rect_size/2.0
	pass

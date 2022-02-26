extends Control

export var planet_holder_path:NodePath

var planet_holder

# The space between each colunm of the starmap horizontally
export var planet_column_spacing_horiz:float = 50.0

# The vertical space between each planet in a column of the starmap 
export var planet_column_vert_spacing:float = 0.01

export var planet_ui_prefab:PackedScene


export var scroll_contatiner_path:NodePath
var scroll_container

var planet_icon_dict:Dictionary = {}

var system_generator


export var current_planet_indicator_path:NodePath
var current_planet_indicator

export var navigation_set_path:NodePath
var naviagation_set

var current_planet_id:int = -1
var selected_planet_id:int = -1

var current_planet_is_last = false

var new_planet_set = false

var line_renderers = []

var rng = RandomNumberGenerator.new()

signal new_planet_queued(new_planet_id)


export var systems_wandered_path:NodePath

export var ping_path:NodePath
var ping


func _init():
	SceneResources.RegisterResource("NavigationManager",self)
	pass

func _ready():
	planet_holder = get_node(planet_holder_path)
	system_generator = SceneResources.GetResource("SystemGenerator")
	ping = get_node(ping_path)
	current_planet_indicator = get_node(current_planet_indicator_path)


	# Connect visibility notifier
	var _connection = connect("visibility_changed",self,"OnVisibilityChanged")

	naviagation_set = get_node(navigation_set_path)
	scroll_container = get_node(scroll_contatiner_path)
	#line2d = get_node(line2d_path)

	# TEMP
	system_generator.connect("new_system_generated",self,"DisplayPlanets")
	pass


func DisplayPlanets():

	# System amount display
	var systems_completed = ProgressionManager.GetAmountSystemsCompleted()
	get_node(systems_wandered_path).text = "Systems Wandered: " + str(systems_completed)


	# Set the seed to be deterministic as well
	rng.seed = system_generator.GetSystemSeed()

	var system_information = system_generator.GetCurrentSystem()

	var system_columns = system_generator.GetCurrentSystemColumns()

	
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")


	var most_per_column = 0
	
	var iterator_column = 0
	for c in system_columns.keys():
		# Loop through every planet and draw the lines connecting them
		var current_column = system_columns[c]

		if(system_columns.keys().size() > most_per_column):
			most_per_column = system_columns.keys().size()

		var iterator_planet = 0

		for p in current_column:
			#print(p)
			
			
			var center_y = float(iterator_planet * planet_column_vert_spacing + float(iterator_planet) * 50.0)
			var center_x = float(iterator_column * planet_column_spacing_horiz + float(iterator_planet) * 50.0)
			var new_pos = Vector2(center_x + 50,center_y + 150)

			AddPlanetIconToStarmap(system_information[p],new_pos)
			yield(get_tree(),"idle_frame")
			iterator_planet += 1
			pass

		iterator_column += 1
		pass
	pass


	#var total_height = float(planet_column_vert_spacing) * float(most_per_column)
	#var total_width = float(planet_column_spacing_horiz) * float(system_columns.keys().size())
	
	if(ProgressionManager.GetPlanetsCompleteInSystem() == 0):
		current_planet_id = 0
		pass

	DrawConnectionLines()
	PositionShipIndicator()

	pass

func OnCourseSet():
	# TODO: Set next planet variables
	pass

func GetNewPlanetSet():
	return new_planet_set
	pass

func PositionShipIndicator():
	if(current_planet_id != -1):
		current_planet_indicator.rect_position = planet_icon_dict[current_planet_id].rect_position - Vector2(40,40)
		current_planet_indicator.visible = true
		pass
	elif(ProgressionManager.GetLastPlanetCompletedID() != -1):
		current_planet_indicator.rect_position = planet_icon_dict[ProgressionManager.GetLastPlanetCompletedID()].rect_position - Vector2(40,40)
		current_planet_indicator.visible = true
		pass

	
	else:
		current_planet_indicator.visible = false

	pass

func DrawConnectionLines():

	# Delete all current line renderers
	if(line_renderers.size() > 0):
		for l in line_renderers:
			l.queue_free()
			pass
		pass

	yield(get_tree(),"idle_frame")
	line_renderers = []


	#var current_planet_data = system_generator.GetCurrentSystem()[selected_planet_id]

	# Re-draw lines
	var system_information = system_generator.GetCurrentSystem()
	for pid in system_information.keys():
		#print(system_information[pid])
		var connections = system_information[pid].GetPlanetConnections()
		
		var current_planet_icon = planet_icon_dict[pid]

		
		for c in connections:

			var draw_color = Color.white
			#if((system_generator.GetPlanetData(c).IsPlanetComplete() != system_generator.GetPlanetData(pid).IsPlanetComplete() && (system_generator.GetPlanetData(pid).IsPlanetComplete() ||system_generator.GetPlanetData(c).IsPlanetComplete()) ||    (system_generator.GetPlanetData(pid).IsPlanetComplete() && system_generator.GetPlanetData(c).IsPlanetComplete())) ):
			if(system_generator.GetPlanetData(pid).IsPlanetComplete() && system_generator.GetPlanetData(c).IsPlanetComplete()):
				draw_color = Color.green
				pass
			elif(c == selected_planet_id || pid == selected_planet_id):
				draw_color = Color.white
				pass
			else:
				draw_color = Color.red
				pass

			call_deferred("Add2dLine",current_planet_icon.rect_position + Vector2(34,34),planet_icon_dict[c].rect_position + Vector2(34,34),draw_color)
			pass


	pass


func OnVisibilityChanged():
	if(ping != null):
		# Disable ping
		ping.SetEnabled(false)
		pass

	# Mark checkpoint as complete
	if(!ProgressionManager.GetCheckpointBool("navigation_viewed") || ProgressionManager.GetAmountPlanetsCompleted() >= 1 ):
		ProgressionManager.SetCheckpointBool("navigation_viewed",true)
		pass
	pass

# Draw a new 2d line
func Add2dLine(start,end,color=Color.white):
	var new_line = Line2D.new()

	line_renderers.push_back(new_line)
	new_line.default_color= color
	new_line.show_behind_parent = true
	planet_holder.add_child(new_line)
	new_line.add_point(start)
	new_line.add_point(end)
	pass

# Callback for when a planet is selected in the navigation UI
func PlanetSelected(new_selected_planet_id):
	# TODO: Check if the selected planet is unlocked, and display otherwise

	selected_planet_id = new_selected_planet_id
	DrawConnectionLines()
	#print("Pressed: ",selected_planet_id)
	pass


func SetCourseClicked():
	# TODO: Check if the planet has not yet been completed, and if so go to it
	var current_planet_data = system_generator.GetPlanetData(selected_planet_id)

	var is_connected_to_completed = false
	
	if current_planet_data == null:
		naviagation_set.custom_effects[0].resetTimer = true
		var _result = naviagation_set.parse_bbcode("[center][fadeLine fadeSpeed=1.0 offset=2.0 colorHex=#de0000]You haven't selected a planet![/fadeLine][center]")
		return
	
	
	# Check if the planet is connected to a planet that has been completed
	for p in current_planet_data.GetPlanetConnections():
		var neighbor_planet_data =  system_generator.GetPlanetData(p)
		if(neighbor_planet_data.IsPlanetComplete()):
			is_connected_to_completed = true
			break
			pass
		pass


	if(current_planet_data.IsPlanetComplete()):
		naviagation_set.custom_effects[0].resetTimer = true
		var _result = naviagation_set.parse_bbcode("[center][fadeLine fadeSpeed=1.0 offset=2.0 colorHex=#de0000]You have already been here![/fadeLine][center]")
		pass

	elif((!current_planet_data.IsPlanetComplete() == (selected_planet_id == 0)) || !current_planet_data.IsPlanetComplete() && is_connected_to_completed):
		current_planet_id = selected_planet_id

		PositionShipIndicator()
		# Check if this is the last planet in the system
		#		Completion triggers new generation
		current_planet_is_last = (selected_planet_id == system_generator.GetCurrentSystem().keys().size()-1)
		
		naviagation_set.custom_effects[0].resetTimer = true
		var _result = naviagation_set.parse_bbcode("[center][fadeLine fadeSpeed=1.0 offset=2.0 colorHex=#FFFFFFFF]Navigation Set![/fadeLine][center]")

		# Update listeners
		emit_signal("new_planet_queued",current_planet_id)
		#print("Set sail!")
		pass
	else:
		naviagation_set.custom_effects[0].resetTimer = true
		var _result = naviagation_set.parse_bbcode("[center][fadeLine fadeSpeed=1.0 offset=2.0 colorHex=#de0000]Planet not yet reachable![/fadeLine][center]")

	return

func GetQueuedPlanetData():
	return system_generator.GetPlanetData(current_planet_id)
	pass

func AddPlanetIconToStarmap(planet_information, location:Vector2):
	var new_planet = planet_ui_prefab.instance()

	planet_holder.add_child(new_planet)
	new_planet.rect_position = location

	var _connection = new_planet.connect("planet_button_pressed",self,"PlanetSelected")

	new_planet.SetData(planet_information.GetPlanetId(),rng.randi_range(0,1))

	#print(planet_information.GetPlanetId())
	planet_icon_dict[planet_information.GetPlanetId()] = new_planet
	# TODO: Set information for button
	return

func GetPlanetIsLast():
	return current_planet_is_last
	pass


func TriggerPing():
	ping.SetEnabled(true)
	pass

func OnNavClosed():
	self.visible = false
	SceneResources.GetResource("Player").SetPlayerInputActive(true)
	InputState.ToggleCursor(false)
	pass # Replace with function body.

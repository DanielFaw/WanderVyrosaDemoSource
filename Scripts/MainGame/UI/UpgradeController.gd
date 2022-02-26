extends Control


var is_active = false
export var money_count = 0
onready var money_display = $ResourceAmount

var mortar_resource
var gatling_resource
var drill_resource
var building_resource
var upgrade_holder


var mortar_path = "res://CustomResources/UpgradableStats/Mortar_Stats.tres"
var gatling_path = "res://CustomResources/UpgradableStats/Gatling_Stats.tres"
var drill_path = "res://CustomResources/UpgradableStats/Drill_Stats.tres"
var building_path = "res://CustomResources/UpgradableStats/BuildingController_Stats.tres"
var upgrade_holder_path = "res://CustomResources/UpgradableStats/Upgrade_Holder_Res.tres"


var last_node


export var ping_path:NodePath
var ping


func _ready():
	
	

	
	

	# Set the home ship ping (pong)
	if(ping_path != ""):
		ping = get_node(ping_path)
		pass
	CheckFuelUnlock()
	

	money_count += ProgressionManager.GetBankAmount()
	try_buy_upgrade(0)
	#Tell all nodes what their resource is
	var gat_nodes = $Nodes/Gatling.get_children()
	var mor_nodes = $Nodes/Mortar.get_children()
	var drill_nodes = $Nodes/Drill.get_children()
	var fuel_nodes = $Nodes/FuelShip.get_children()
	for i in gat_nodes:
		i.tower_resource = gatling_resource
	
	for i in mor_nodes:
		i.tower_resource = mortar_resource
	
	for i in drill_nodes:
		i.tower_resource = drill_resource
	
	for i in fuel_nodes:
		i.tower_resource = building_resource
	

	last_node = $Nodes/Gatling
	call_toggles(last_node)

	# Enable the ping after the first planet is complete
	if(ProgressionManager.GetAmountPlanetsCompleted() == 1 && !ProgressionManager.GetCheckpointBool("upgrades_viewed")):
		ping.SetEnabled(true)
		pass

	var _connection = connect("visibility_changed",self,"OnVisibilityUpdated")
	
	
	
	
	
	
	
	
	
	
	pass

func load_me():
	#Mortar
	if ResourceLoader.exists("user://Mortar_Stats.tres"):
		mortar_resource = ResourceLoader.load("user://Mortar_Stats.tres")
		if !mortar_resource is Resource:
			mortar_resource = ResourceLoader.load(mortar_path)
			pass
	else:
		mortar_resource = ResourceLoader.load(mortar_path)
		pass
	
	#Gatling
	if ResourceLoader.exists("user://Gatling_Stats.tres"):
		gatling_resource = ResourceLoader.load("user://Gatling_Stats.tres")
		if !gatling_resource is Resource:
			gatling_resource = ResourceLoader.load(gatling_path)
			pass
	else:
		gatling_resource = ResourceLoader.load(gatling_path)
		pass
	
	#Drill
	if ResourceLoader.exists("user://Drill_Stats.tres"):
		drill_resource = ResourceLoader.load("user://Drill_Stats.tres")
		if !drill_resource is Resource:
			drill_resource = ResourceLoader.load(drill_path)
			pass
	else:
		drill_resource = ResourceLoader.load(drill_path)
		pass
	
	#Ship
	if ResourceLoader.exists("user://BuildingController_Stats.tres"):
		building_resource = ResourceLoader.load("user://BuildingController_Stats.tres")
		if !building_resource is Resource:
			building_resource = ResourceLoader.load(building_path)
			pass
	else:
		building_resource = ResourceLoader.load(building_path)
		pass
	
	#Upgrade holder
	if ResourceLoader.exists("user://Upgrade_Holder_Res.tres"):
		upgrade_holder = ResourceLoader.load("user://Upgrade_Holder_Res.tres")
		if !upgrade_holder is Resource:
			upgrade_holder = ResourceLoader.load(upgrade_holder_path)
			pass
	else:
		upgrade_holder = ResourceLoader.load(upgrade_holder_path)
		pass
	
	
	
	
	
	
	if(!ProgressionManager.upgrades_have_been_initialized):
		mortar_resource.initialize_upgrades()
		gatling_resource.initialize_upgrades()
		drill_resource.initialize_upgrades()
		building_resource.initialize_upgrades()
		get_upgrade_states()
		ProgressionManager.upgrades_have_been_initialized = true
		
		return
	else:
		if(upgrade_holder.has_been_set):
			distribute_upgrade_states()
		else:
			print("Upgrades reset. Oops.")
			get_upgrade_states()
			pass
		
		return

	pass

func OnVisibilityUpdated():
	ping.SetEnabled(false)
	ProgressionManager.SetCheckpointBool("upgrades_viewed",true)
	pass
	pass

func CheckFuelUnlock():
	if ProgressionManager.GetAmountSystemsCompleted() > 0:
		$Nodes/FuelShip.visible = true
		$UpgradeSelection/CargoUpgradeButton.visible = true
		pass
	else:
		$Nodes/FuelShip.visible = false
		$UpgradeSelection/CargoUpgradeButton.visible = false
		pass
	pass

func _input(e):
		#if(e.pressed && e.scancode == KEY_E):
		#	is_active = !is_active
		#	visible = is_active
		#	InputState.ToggleCursor(is_active)
		#	if(is_active):
		#		check_visibility()
		#		pass
		#	pass
		#pass
	pass
	

func try_buy_upgrade(var cost) -> bool:
	if(money_count >= cost):
		money_count -= cost
		money_display.text = "Money count: " + str(money_count)
		return true
	return false

func check_visibility():
	#Click on the last node
	child_check(last_node)
	pass



#On enter/exit tree, init/save upgrades
func _enter_tree() -> void:
	load_me()
	pass

func get_upgrade_states():
	for upgrade_root in $Nodes.get_children():
		upgrade_holder.purchased_upgrades[upgrade_root.name] = {}
		for ug_node in upgrade_root.get_children():
			if ug_node is Button:
				upgrade_holder.purchased_upgrades[upgrade_root.name][ug_node.name] = ug_node.is_bought
			pass
		pass
	#Set the money
	upgrade_holder.money_count = money_count
	upgrade_holder.has_been_set = true
	pass

func distribute_upgrade_states():
	for upgrade_root in $Nodes.get_children():
		#upgrade_holder.purchased_upgrades[upgrade_root.name] = {}
		for ug_node in upgrade_root.get_children():
			ug_node.is_bought = upgrade_holder.purchased_upgrades[upgrade_root.name][ug_node.name]
			pass
		pass
	money_count = upgrade_holder.money_count
	pass

func _exit_tree():
	get_upgrade_states()
	
	
	var error = ResourceSaver.save("user://Mortar_Stats.tres", mortar_resource)
	print(error)
	ResourceSaver.save("user://Gatling_Stats.tres", gatling_resource)
	ResourceSaver.save("user://Drill_Stats.tres", drill_resource)
	ResourceSaver.save("user://BuildingController_Stats.tres", building_resource)
	ResourceSaver.save("user://Upgrade_Holder_Res.tres", upgrade_holder)
	pass


func child_check(var node):
	for n in node.get_children():
		if n is Button:
			n.can_be_viewed()
		pass
	pass

func toggle_upgrade_scene(var node):
	for i in $Nodes.get_children():
		i.visible = false
		pass
	node.visible = true
	
	child_check(node)
	#CheckFuelUnlock()
	last_node.get_node("MainNode")._do_click()
	pass

func call_toggles(var node):
	#child_check(node)
	toggle_upgrade_scene(node)
	pass

func _on_GatlingUpgradeButton_button_down() -> void:
	last_node = $Nodes/Gatling
	call_toggles(last_node)
	pass # Replace with function body.

func _on_MortarUpgradeButton_button_down() -> void:
	last_node = $Nodes/Mortar
	call_toggles(last_node)
	pass # Replace with function body.


func _on_DrillUpgradeButton_button_down() -> void:
	last_node = $Nodes/Drill
	call_toggles(last_node)
	pass # Replace with function body.


func _on_CargoUpgradeButton_button_down() -> void:
	last_node = $Nodes/FuelShip
	call_toggles(last_node)
	pass # Replace with function body.


func ExitUpgrades():
	self.visible = false
	SceneResources.GetResource("Player").SetPlayerInputActive(true)
	InputState.ToggleCursor(false)
	pass

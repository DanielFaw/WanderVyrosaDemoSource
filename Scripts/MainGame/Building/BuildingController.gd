extends Spatial

# Are we in building mode?
var _inBuildingMode = false

# The currently active camera for the scene
var current_camera

const RESOURCE_TYPES = preload("res://Scripts/MainGame/ResourceType.gd")

# A dictionary conatining the current amount of each resource we've collected
var _resourcePool = {}

# Which tower index we currently have selected
var _currentTowerSelected:int = 1

var _currentTowerPrefabRes
var _currentTowerPrefabInst

var placementMask = 0b00000000000000100001

var _collisionArea

# The rotation of the current tower around the Y axis
var _towerYRot = 0

var _placementTransform: Transform

var _firstDrillPlaced = false

# Is the current position a valid build position?
var _isCurrentValidPos = false

export var colArea:PackedScene

var _nextTowerCache
var _previousTowerCache

var world_cursor_position:Vector3

export var validPlaceColor:Color = Color.white
export var invalidPlaceColor:Color = Color.green
export var placementMaterial:Material

var modelMeshes = []

var totalTowerCount = 0
var _towerIndex

# Signal for when build mode is toggled
signal buildModeToggled
signal towerSelectionChanged
signal resources_set(params)

signal resourceAmountChanged(resourceType, newAmout)
#signal towerBuilt(towerPosition, towerName)

var myStats
var tower_stats = preload("res://CustomResources/UpgradableStats/BuildingController_Stats.tres")

var last_pos_was_valid:bool = false

func _init():
	SceneResources.RegisterResource("BuildingController",self)
	pass

	
func _ready():

	# TEMP- Add area for collision checkingcurrentTower = load(testPrefabResPath)
	_collisionArea = colArea.instance()
	add_child(_collisionArea)
	
	
	# Initialize tower resources
	call_deferred("_OnBuildingSelectionChange",0)

	_towerIndex = SceneResources.GetResource("TowerIndex")
	totalTowerCount = _towerIndex.GetTowerCount()
	
	
	call_deferred("set_resources")
	pass

func set_resources():
	myStats = tower_stats.GetAllStats()
	var amnt = myStats[TStat.STARTRESOURCES]
	# Initialize the resource pool
	_resourcePool[RESOURCE_TYPES.TYPE.Metal] = amnt
	_resourcePool[RESOURCE_TYPES.TYPE.Quartz] = amnt
	_resourcePool[RESOURCE_TYPES.TYPE.Silicon] = amnt
	_resourcePool[RESOURCE_TYPES.TYPE.BoomStone] = amnt
	emit_signal("resources_set", _resourcePool)
	pass

func _process(delta):
	# Open/ close Build Mode
	#if(Input.is_action_just_pressed("toggle_build_mode") && InputState.GetCurrentInputState() == "ALL"):
	#	_ToggleBuildMode()

	if(_inBuildingMode && InputState.GetCurrentInputState() == "ALL"):
		# Place the "pre placement display" for the tower
		_PositionTower(delta)

		# Change the tower we're currently placing
		if(Input.is_action_just_pressed("tower_selection+")):
			_currentTowerSelected +=1
			if(_currentTowerSelected >= totalTowerCount):
				_currentTowerSelected = 0
			_OnBuildingSelectionChange(1)

			pass
		elif(Input.is_action_just_pressed("tower_selection-")):
			_currentTowerSelected -=1
			if(_currentTowerSelected < 0):
				_currentTowerSelected = totalTowerCount -1 
			_OnBuildingSelectionChange(-1)
			pass


		# Allow tower to be rotated around the Y axis before placed
		if(Input.is_action_just_released("action_rotate_ccw")):
			_towerYRot -= deg2rad(5.0)
		elif(Input.is_action_just_released("action_rotate_cw")):
			_towerYRot += deg2rad(5.0)

		
		# Place the building on click
		if(Input.is_action_just_pressed("player_action") && _isCurrentValidPos):
			if(!_firstDrillPlaced && _currentTowerPrefabRes.GetTowerName() == "Resource Drill"):
				#self.call_deferred("_PlaceBuilding")
				SceneResources.GetResource("TowerManager").PlaceBuilding(_currentTowerPrefabRes,_currentTowerPrefabInst.global_transform)
				SceneResources.GetResource("WaveManager").StartLevel();
				_firstDrillPlaced = true
				pass

			elif(_HasEnoughResources()):
				var towerResourceCost = _currentTowerPrefabRes.GetBuildCost()

				# Use each resource
				for res in towerResourceCost.keys():
					UseResource(res, towerResourceCost[res])
					pass

				#self.call_deferred("_PlaceBuilding")
				SceneResources.GetResource("TowerManager").PlaceBuilding(_currentTowerPrefabRes,_currentTowerPrefabInst.global_transform)
			pass
			
	pass


func GetBuildingState():
	return _inBuildingMode


func GetCurrentTowerResource():
	return _currentTowerPrefabRes
	

# Load new asset and create an instance for placing
func _OnBuildingSelectionChange(var direction):
	var newTowerName = ""
	# Set new tower model
	if(direction == 1):
		_currentTowerPrefabRes = _nextTowerCache
	elif(direction == -1):
		_currentTowerPrefabRes = _previousTowerCache
	else:
		newTowerName = _towerIndex.GetTowerNameAtIndex(_currentTowerSelected)
		if(newTowerName == ""):
			print("TOWER INDEX " + str(_currentTowerSelected) + " OUT OF BOUNDS")
			print_stack()
			return

		_currentTowerPrefabRes = _towerIndex.GetTower(newTowerName)

	if(_currentTowerPrefabInst != null):
		# Delete the old tower model
		_currentTowerPrefabInst.queue_free()

	# Instantiate new tower instance
	_currentTowerPrefabInst = _currentTowerPrefabRes.GetTowerModel().instance()
	get_tree().get_current_scene().add_child(_currentTowerPrefabInst)
	_currentTowerPrefabInst.global_scale(_currentTowerPrefabRes.GetTowerModelScale())
	_currentTowerPrefabInst.global_transform = _placementTransform
	emit_signal("towerSelectionChanged")


	# Create a list of all children (for material switching) (yay recursion)
	modelMeshes = _RGetMeshChildren(_currentTowerPrefabInst)

	# Set the material to the "build material"
	for c in modelMeshes:
		c.set_surface_material(0,placementMaterial)

	# Load neighbor tower resources
	_PreloadTowerResources("")

	pass


# TODO: Move this to the multitool controller
func GetWorldCursorPosition():
	return world_cursor_position
	pass


func _PositionTower(delta):
	# Allow placement of prefab
	# Calculate raycast points based on position
	var frompos = current_camera.project_ray_origin(get_viewport().get_mouse_position())
	var toPos =  current_camera.project_ray_normal(get_viewport().get_mouse_position()) * 100.0
	
	#TODO - Dynamically calculate physics shape
		# Can probably be set as part of prefab to avoid manual calculation

	#TODO - Try and make this a little less "hacky" if possible
		# Maybe keep placement detectuion area on prefab instead???
		# Then use that to detect valid placements?
		
	var space_state = get_world().direct_space_state
	var rayCollisionInfo = space_state.intersect_ray(frompos,toPos,[],placementMask,true,true)

	# If we have a collision, align the object
	if(rayCollisionInfo.size() != 0):
		_collisionArea.global_transform.origin = rayCollisionInfo.position

		world_cursor_position = rayCollisionInfo.position
		var colBodies = _collisionArea.get_overlapping_bodies()

		var targetTransform = _currentTowerPrefabInst.transform
		targetTransform.origin = rayCollisionInfo.position

		# Check for valid placement 
		if(colBodies.size() >= 1 && !_currentTowerPrefabRes.GetOverridePlacement()):
			_isCurrentValidPos = false
			pass
		else:
			_isCurrentValidPos = true
			pass

		# Calculate the UP vector at the current position
		var upVec = (targetTransform.origin - SceneResources.GetResource("Planet").transform.origin).normalized()
		targetTransform = Utilities.AlignWithNormal(targetTransform,upVec)
		
		# Calculate and set the target Y rotation (local space)
		var targetRot = Quat(current_camera.get_node("../").transform.rotated(upVec,_towerYRot).basis)
		_currentTowerPrefabInst.global_transform = Quat(targetTransform.basis).slerp(targetRot,10*delta)

		# Store the (unscaled) transform in case we end up placing the tower
		_placementTransform = _currentTowerPrefabInst.global_transform
		_currentTowerPrefabInst.global_scale(_currentTowerPrefabRes.GetTowerModelScale())
	
		targetTransform.orthonormalized()

		_currentTowerPrefabInst.global_transform.origin = targetTransform.origin
	else:
		# If the current position is not on planet, dont place
		_isCurrentValidPos = false
		pass

	# Update materials if the valid pos state has changed
	if(last_pos_was_valid != _isCurrentValidPos):
		if(!_isCurrentValidPos):
			for mesh in modelMeshes :
				mesh.get_surface_material(0).set_shader_param("glow_color",invalidPlaceColor)
				mesh.get_surface_material(0).set_shader_param("line_color",invalidPlaceColor)
				pass
			Debug.Report("canPlace","Valid Placement: [color=red]FALSE[/color]")
			pass
		else:
			for mesh in modelMeshes :
				mesh.get_surface_material(0).set_shader_param("glow_color",validPlaceColor)
				mesh.get_surface_material(0).set_shader_param("line_color",Color("#80bfff"))

			Debug.Report("canPlace","Valid Placement: [color=#00f51b]TRUE[/color]")
		
			pass

	# Store whether the pos last frame was valid placement
	last_pos_was_valid = _isCurrentValidPos
	pass


# Recursively get all children meshInstances of this object
func _RGetMeshChildren(var parentObject):
	var meshChildren = []
	if(parentObject is MeshInstance):
		meshChildren.append(parentObject)
		pass
	if(parentObject.get_child_count() >=1):
		for c in parentObject.get_children():
			var childMeshes = _RGetMeshChildren(c)
			if(childMeshes != null):
				meshChildren += childMeshes
			pass
		pass
		return meshChildren
	else:
		if(parentObject is MeshInstance):
			return [parentObject]
	
	pass


# Toggles between build mode and regular mode
func _ToggleBuildMode(is_build_mode_active):
	_inBuildingMode = is_build_mode_active
	# Get the current camera
	current_camera = get_viewport().get_camera()

	# Turn on/off building mode
	if(_inBuildingMode):
		#_OnBuildingSelectionChange(0)
		# Update mouse cursor mode
		InputState.SetCursorModifierActiveState(true)
		#InputState.ToggleCursor(true)

		#Spawn testPrefab  DEBUG
		if(_currentTowerPrefabInst == null):
			_currentTowerPrefabInst.GetTowerModel().instance()
			get_tree().get_current_scene().add_child(_currentTowerPrefabInst)			
			
			# Scale global transform to match the prefab and apply it to the model 
			_currentTowerPrefabInst.global_scale = _currentTowerPrefabRes.GetTowerModelScale()
		else:
			_currentTowerPrefabInst.visible = true
	else:
		InputState.SetCursorModifierActiveState(false)
		#InputState.ToggleCursor(false)
		_currentTowerPrefabInst.visible = false

	# Notify listerners of change
	emit_signal("buildModeToggled",_inBuildingMode)

	pass


# Check if we have enough resources to build the current tower
func _HasEnoughResources():
	var towerResourceCost = _currentTowerPrefabRes.GetBuildCost()

	# Check each resource to see if we have enough
	for res in towerResourceCost.keys():
		if( GetResourceAmount(res) < towerResourceCost[res]):
			return false
		pass
	return true

	pass


func _PreloadTowerResources(var _nullarg):
	# Prevent variables from being changed
	var nextTowerIndex = _currentTowerSelected + 1
	if(nextTowerIndex >= totalTowerCount):
		nextTowerIndex = 0
		pass
	
	var previousTowerIndex = _currentTowerSelected - 1
	if(previousTowerIndex < 0):
		previousTowerIndex = totalTowerCount -1
		pass

	# Load the towers
	var nextTowerName = _towerIndex.GetTowerNameAtIndex(nextTowerIndex)
	var previousTowerName = _towerIndex.GetTowerNameAtIndex(nextTowerIndex)

	if(nextTowerName == "" || previousTowerName == ""):
		for mesh in modelMeshes :
			mesh.get_surface_material(0).set_shader_param("glow_color",validPlaceColor)
			mesh.get_surface_material(0).set_shader_param("line_color",Color("#80bfff"))

		Debug.Report("canPlace","Valid Placement: [color=#00f51b]TRUE[/color]")
		print("BUILDING CONTROLLER COULD NOT LOAD NEIGHBORING TOWERS")
		print_stack()
		return

	_nextTowerCache = _towerIndex.GetTower(nextTowerName)
	_previousTowerCache = _towerIndex.GetTower(previousTowerName)
	#print("Thread finished loading..:")
	#print("TOWER PRELOADING THREAD FINISHED")
	return
	pass


# Add a collected amount of resources to the resource pool (type:RESOURCE_TYPE amount:float) and returns the new amount of that type
func CollectResource(var type, var amount:float):
	if(_resourcePool.has(type)):
		_resourcePool[type] += amount
		emit_signal("resourceAmountChanged",type,_resourcePool[type])
		pass
	pass

# 'Consume' an amount of resources of a given type (type:RESOURCE_TYPE amountToUse:int)
func UseResource(var type, var amountToUse:int):
	if(GetResourceAmount(type) >= amountToUse):
		if(_resourcePool.has(type)):
			#print("USED " + str(amountToUse) + " of resource " +str(type))
			_resourcePool[type] -= amountToUse
			emit_signal("resourceAmountChanged",type,_resourcePool[type])
	pass


# Get the available amount of resources (type:RESOURCE_TYPE)
func GetResourceAmount(var type):
	if(_resourcePool.has(type)):
		return _resourcePool[type]
		pass
	return 0


# Get the cost of the current tower cost
func GetCurrentTowerCost():
	return _currentTowerPrefabRes.GetBuildCost()
	pass

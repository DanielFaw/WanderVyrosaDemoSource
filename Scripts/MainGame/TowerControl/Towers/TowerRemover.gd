extends Spatial

export var removeRadius:float = 1.0

var intersectshape;

export var intersectColliderShape:NodePath

# Only remove on tower layer
var removalMask = 0b0000000000000000100

func _ready():
	# Set data for the physics shape
	intersectshape = PhysicsShapeQueryParameters.new();
	intersectshape.collide_with_areas = true
	intersectshape.collision_mask = removalMask
	intersectshape.transform = global_transform
	intersectshape.exclude = [self,get_node(intersectColliderShape).get_owner()]
	intersectshape.set_shape(get_node(intersectColliderShape).shape)

	pass

func OnVisibilityChange():
	if(visible):	
		CheckAndRemoveTowers()
		self.queue_free()

func CheckAndRemoveTowers():
	var space_state = get_world().direct_space_state

	#intersectshape.transform = global_transform
	intersectshape.transform.origin = global_transform.origin

	var shapeCollisionInfo = space_state.intersect_shape(intersectshape,1)

	# Delete
	if(shapeCollisionInfo.size() > 0):
		# Check if this is part of the "Towers" node group
		if(shapeCollisionInfo[0]["collider"].get_owner() != null):
			if(shapeCollisionInfo[0]["collider"].get_owner().is_in_group("Towers")):
				if(shapeCollisionInfo[0]["collider"].get_owner() != get_tree().get_current_scene()):
				
					var towerToDestroy = shapeCollisionInfo[0]["collider"].get_owner()
					_ReturnResources(towerToDestroy)
				
					SceneResources.GetResource("TowerManager").ReportTowerDestroyed(shapeCollisionInfo[0]["collider"].get_owner())
					shapeCollisionInfo[0]["collider"].get_owner().queue_free()
	return


# If tower was destroyed by the player, return the build cost relative to the current health percentage
func _ReturnResources(var towerToDestroy):
	var nameOfTower = towerToDestroy.GetIndexName()
	var buildCost = SceneResources.GetResource("TowerIndex").GetTowerCost(nameOfTower);

	# For each material
	for r in buildCost.keys():

		# MATH: Amount to build * percentage of health remaining
		var amountToReturn = int(round(float(buildCost[r]) * (float(towerToDestroy.GetHealth()) / float(towerToDestroy.GetMaxHealth()))))

		# Return amount of resources based on health
		SceneResources.GetResource("BuildingController").CollectResource(r,amountToReturn);
		#print("Got " + str(amountToReturn) + " of " + str(r) +" back!");



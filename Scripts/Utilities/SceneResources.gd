extends Node
# USE: Holds a "global" list of resources that may be needed by multiple objects in a scene.
#   This reduces individual dependencies and makes setting up events with multiple listeners
#   easier. Resources should "self report" in their own individual _init() functions
#   List will ideally be cleared when a scene is changed.
var resources = {}


# Add a resource to the list of resources, or update if needed
func RegisterResource(var key:String,var resource:Node):
	resources[key] = resource

	if(OS.is_debug_build()):
		print("Added " + key + " to scene resource list")
		pass
	pass

# Remove a resource from the list of resources
func DeRegisterResourec(var key:String):
	if(resources.has(key)):
		resources.erase(key)
	pass

# Checks to see if a resource is registered
# RETURNS: TRUE if a resource is registered
func HasResource(var key:String)->bool:
	return resources.has(key)
	pass

# Get a resource with a given key
# RETURNS: Node if found, null if not
func GetResource(var key_to_get)-> Node:
	if(resources.has(key_to_get)):
		return resources[key_to_get]
	else:
		return null


# Clear list of resources
func FlushResources():
	if(OS.is_debug_build()):
		print("Flushing Scene Resources")
		pass
	# TODO: Trigger on scene change
	resources.clear()

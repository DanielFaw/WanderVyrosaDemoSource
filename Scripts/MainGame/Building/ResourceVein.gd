extends Spatial
enum TYPE {Metal,Quartz,Silicon,BoomStone}


const RESOURCE_TYPE = preload("res://Scripts/MainGame/ResourceType.gd")
export(TYPE) var type = TYPE.Metal

export var meshs_paths = []
var scanning_material = preload("res://Materials/Scanning_Material.tres")

# TODO: Make this take into account planet resource distribution
export var density:float = 1.0

func _ready():
	for mesh_path in meshs_paths:
		var mesh = get_node(mesh_path)
		mesh.set_surface_material(0,mesh.get_surface_material(0).duplicate())
		pass
	pass

# Get vein info as a dictionary {density:float type:string}
func GetVeinInfo() -> Dictionary:
	return {"density":density, "type":str(type)}
	pass

# Set the density of this resource vein
func SetDensity(new_density):

	# Lowest the vein density should be is 1
	if(new_density < 0.3):
		new_density = 0.3
		pass


	density = new_density
	pass

# Set the proper next_pass material if the vein is being scanned
func SetScanning(is_being_scanned):
	for mesh_path in meshs_paths:
		var mesh = get_node(mesh_path)
		if(is_being_scanned):
			# Make the material local so other instances aren't changed
		
			mesh.get_surface_material(0).next_pass = scanning_material
			pass
		else:
			mesh.get_surface_material(0).next_pass = null
			pass
		pass
	pass

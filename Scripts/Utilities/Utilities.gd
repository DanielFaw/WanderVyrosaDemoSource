extends Node

var rng = RandomNumberGenerator.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	pass # Replace with function body.


# Calculate the gravity direction relative to a given point on a sphere
func CalculateGravityDirection(var from_point:Vector3):
	var planet = SceneResources.GetResource("Planet")
	var dir = (from_point - planet.global_transform.origin).normalized()
	return dir


#Corrects the jitter when moving in _physics_process() by seperating visual object with physics representation
func CorrectJitter(var delta:float,var movement_direction:Vector3, var visual_object:Spatial, var physical_object:Spatial):
	var fps = Engine.get_frames_per_second()
	var lerp_interval = movement_direction/fps
	var lerp_position = physical_object.global_transform.origin + lerp_interval

	#WARNING Increasing this value will make mesh position closer to collider
	#	position, but will increase the amount of visible stutter
	var lag_speed:float = 20

	#Correct for jitter if needed
	if(fps > ProjectSettings.get_setting("physics/common/physics_fps")):
		visual_object.set_as_toplevel(true)
		visual_object.global_transform.origin = visual_object.global_transform.origin.linear_interpolate(lerp_position,lag_speed* delta)
	else:
		visual_object.global_transform = physical_object.global_transform
		visual_object.set_as_toplevel(false)

# Aligns xform transform's y with a vector3 newY
func AlignWithNormal(var x_form,var newY):
	x_form.basis.y = newY
	x_form.basis.x = -x_form.basis.z.cross(newY)
	x_form.basis = x_form.basis.orthonormalized()
	return x_form

	pass

# ------------------------------Spherical Math I Don't Fully Understand---------------------------------------------
# Source - https://en.wikipedia.org/wiki/Spherical_coordinate_system#Unique_coordinates
#		NOTE: Reference uses different coordinate system (Z+ UP), so some variables are switched around


# Convert spherical coordinates to euclidian, where theta is angle(radians) of inclination
 # and phi is around the global-y
func SphericalCoordToCartesian(r:float,theta:float,phi:float):
	
	var x = -r * cos(phi) * sin(theta)
	var y = -r * cos(theta)
	var z = -r * sin(phi) * sin(theta)

	return Vector3(x,y,z)
	pass

# Convert cartesian coordinates to spherical
# 	returns a Vector3 of the form (radius,theta,phi), where theta is inclination (in radians) and phi is rotation around the global-y axis
func CartesianToSpherical(var cartesian_coord)->Vector3:
	
	var r = sqrt(pow(-cartesian_coord.x,2) + pow(cartesian_coord.z,2) + pow(cartesian_coord.y,2))
	var theta = atan( (sqrt(pow(cartesian_coord.x,2) + pow(cartesian_coord.z,2)))  / cartesian_coord.y)
	
	var phi

	if(cartesian_coord.x >= 0.0):
		phi = atan(cartesian_coord.z/cartesian_coord.x)
	else:
		phi = atan(cartesian_coord.z/cartesian_coord.x) + PI

	#print(str(Vector3(r,theta,phi)))
	return Vector3(r,theta,phi)
	pass

#---------------------------------------------------------------------------------------------------------------------

func GetRandInt(min_inclusive : int, max_inclusive : int):
	return rng.randi_range(min_inclusive, max_inclusive)
	pass


# Get a normally distributed random number between 0 and 1
func GetNormalRandomValue(mean_normalized,deviation_normalized):
	return rng.randfn(mean_normalized,deviation_normalized)
	pass


func GetRandomValue(max_value:float, min_value:float):
	return rng.randf_range(min_value,max_value)

func GetRandFloat(min_val : float, max_val : float):
	return rng.randf_range(min_val, max_val)

func OrderAsc(a,b):
	return a > b
	pass

func str_to_v3(input_string) -> Vector3:
	var array = input_string.replace("(", "").replace(")", "").split(",")
	var float_arr = []
	for i in range(3):
		float_arr.append(float(array[i]))
		pass
	return Vector3(float_arr[0], float_arr[1], float_arr[2])


func str_to_basis(input_string) -> Basis:
	var array = input_string.replace("(", "").replace(")", "").split(",")
	var float_arr = []
	for i in range(9):
		float_arr.append(float(array[i]))
		pass
	var x_vec = Vector3(float_arr[0], float_arr[1], float_arr[2])
	var y_vec = Vector3(float_arr[3], float_arr[4], float_arr[5])
	var z_vec = Vector3(float_arr[6], float_arr[7], float_arr[8])
	return Basis(x_vec, y_vec, z_vec)
	
	
	
	
	

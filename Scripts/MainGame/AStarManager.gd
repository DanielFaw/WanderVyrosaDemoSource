extends Node

var points = []

var theta:float = PI - 0.01
export var enabled:bool = false
var current_theta;

var theta_offset

var phi_offset:float
var current_phi = PI
export var planet_radius:float;

export var test_marker:PackedScene;

var a_star_thread = Thread.new()


export var draw_debug_points:bool = false

# Resolution moving up/down the global-y axis
export var vertical_resolution:int = 15

# Resolution rotating the global-y axis
# 	Results in how many "lanes" there are from the bottom to the top of the planet
export var horizontal_resolution:int = 20


var a_star = AStar.new()


func _init(): 
	# Degrees difference around global-Y
	phi_offset= (2.0 * PI) / float(horizontal_resolution)

	# Radians difference horizontally
	theta_offset = PI/ float(vertical_resolution)

	pass

func _ready():

	a_star_thread.start(self,"_GenerateNodes")
	SceneResources.RegisterResource("AStarManager",self)
	pass

func _GenerateNodes(var _null_arg):
	
	var point_id = 0
	var start_time = OS.get_ticks_msec()
	# For each PHI
	for _i in range(horizontal_resolution):
		# For each THETA
		for _v in range(vertical_resolution):
			var new_point = Utilities.SphericalCoordToCartesian(19,_v * theta_offset, _i * phi_offset)
			a_star.add_point(point_id,new_point,1)
			point_id += 1

			if(draw_debug_points):
				call_deferred("DrawDebugCubes",new_point)
			pass

	# Connect all the points
	for p in a_star.get_point_count():
		#print((p % vertical_resolution) != 0 && (p % vertical_resolution) != (vertical_resolution -1))

		if(p < vertical_resolution-1 && p > 0):
			var neighbor = a_star.get_point_count() - vertical_resolution + p
			
			# directly over
			if(!a_star.are_points_connected(p,neighbor,true)):
				a_star.connect_points(p,neighbor,true)

			# Over and Up
			if(!a_star.are_points_connected(p,neighbor + 1,true)):
				a_star.connect_points(p,neighbor + 1,true)

			#Over and down
			if(!a_star.are_points_connected(p,neighbor -1,true)):
				a_star.connect_points(p,neighbor -1,true)
				

			if(OS.is_debug_build()):
				for c in a_star.get_point_connections(p):
					Debug.DrawDebugLineStatic(a_star.get_point_position(p),a_star.get_point_position(c),Color.red)
					pass

		# Connect first in top row to the last
		elif(p == vertical_resolution-1):
			var n = a_star.get_point_count() - 1
			if(!a_star.are_points_connected(p,n,true)):
				a_star.connect_points(p,n,true)
				Debug.DrawDebugLineStatic(a_star.get_point_position(p),a_star.get_point_position(n),Color.red)

		# Connect nodes to other nodes immediately surrounding it
		if((p % vertical_resolution) != 0 && (p % vertical_resolution) != vertical_resolution -1):
			#print("AH")

			# Node Above
			if(!a_star.are_points_connected(p,p+1,true)):
				a_star.connect_points(p,p+1,true)
			# Node below
			if(!a_star.are_points_connected(p,p-1,true)):
				a_star.connect_points(p,p-1,true)

			# Connect Column to the Right
				# Make sure there is a column to the right
			
			if(p <  a_star.get_point_count()-vertical_resolution):
				var _right_index = p + vertical_resolution

				# Direct right
				if(!a_star.are_points_connected(p,_right_index,true)):
					a_star.connect_points(p,_right_index,true)
					
				# Right and up
				if(!a_star.are_points_connected(p,_right_index+1,true)):	
					a_star.connect_points(p,_right_index+1,true)

				# Right and down
				if(!a_star.are_points_connected(p,_right_index-1,true)):
					a_star.connect_points(p,_right_index-1,true)
			
			if(OS.is_debug_build()):
				for c in a_star.get_point_connections(p):
					Debug.DrawDebugLineStatic(a_star.get_point_position(p),a_star.get_point_position(c),Color.red)
					pass
			pass

		# Connect top row
		elif((p +1) % vertical_resolution == 0):
			if(p >= vertical_resolution):
				var right = p - vertical_resolution
				if(!a_star.are_points_connected(p,right,true)):
					a_star.connect_points(p,right,true)
					if(OS.is_debug_build()):
						Debug.DrawDebugLineStatic(a_star.get_point_position(p),a_star.get_point_position(right),Color.red)
					pass
				pass
			pass

	# Log generation time
	if(OS.is_debug_build()):
		var _end_time = OS.get_ticks_msec()
		print("A* Node generation took " + str(_end_time - start_time) + "ms to generate and connect " + str(a_star.get_point_count()) + " nav points")

	# Exit the thread
	#a_star_thread.wait_to_finish()
	return
	pass


func CalculatePath(start_pos:Vector3, end_pos:Vector3) -> PoolVector3Array:

	var closest_start = a_star.get_closest_point(start_pos,true);
	var _closest_end = a_star.get_closest_point(end_pos,true);
	return a_star.get_point_path(closest_start,_closest_end);
	pass

func _exit_tree():
	a_star_thread.wait_to_finish()

func DrawDebugCubes(var _cartesian_coords):
	var _new_marker = test_marker.instance()
	get_tree().get_current_scene().add_child(_new_marker)
	#print(currentPhiIn)
	#print(Utilities.SphericalCoordToCartesian(planet_radius,current_theta,currentPhiIn))
	_new_marker.global_transform.origin = _cartesian_coords
	

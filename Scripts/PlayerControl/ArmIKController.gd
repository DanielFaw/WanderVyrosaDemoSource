extends Spatial

export var skeleton_ik_path:NodePath
var skeleton_ik:SkeletonIK

export var vis_path:NodePath
var vis

var ik_active:bool = false
var new_pos:Vector3
var new_transform:Transform

export var tween_path:NodePath
var tween:Tween

export var line_geometry_path:NodePath
var line_geometry:ImmediateGeometry

export var tool_barrel_path:NodePath
var tool_barrel


var valid_pos_cache:Vector3 = Vector3.ZERO
var last_valid_target_pos:Vector3 = Vector3.ZERO
var last_valid_target_rot:Basis = Basis.IDENTITY

var is_multitool_active

# The range of the min/max reference target distances from the player
var distance_modifier_range = Vector2(1.0,8.0)

func _ready():
	skeleton_ik = get_node(skeleton_ik_path)
	vis = get_node(vis_path)
	#if(SceneResources.GetResource("BuildingController") == null):
	#	return
	#var _connection_result = SceneResources.GetResource("BuildingController").connect("buildModeToggled",self,"BuildModeChanged")

	if(SceneResources.GetResource("Multitool") == null):
		return

	var _connection_result = SceneResources.GetResource("Multitool").connect("multi_tool_toggled",self,"MultitoolModeChanged")
	tween = get_node(tween_path)
	line_geometry = get_node(line_geometry_path)
	tool_barrel  = get_node(tool_barrel_path)

	_connection_result = tween.connect("tween_completed",self,"OnTweenComplete")
	pass

func _exit_tree():
	if(SceneResources.GetResource("Multitool") != null):
		if(SceneResources.GetResource("Multitool").is_connected("multi_tool_toggled",self,"MultitoolModeChanged")):
			SceneResources.GetResource("Multitool").disconnect("multi_tool_toggled",self,"MultitoolModeChanged")
		pass
	pass

# Callback for when the build mode is changed
func MultitoolModeChanged(new_tool_mode_state):
	# Cache new state
	is_multitool_active = new_tool_mode_state

	# Cleanup any previous laser lines
	line_geometry.clear()
	if(is_multitool_active):
		# Transition between tool down and tool up
		var _tween_hand = tween.interpolate_property(skeleton_ik,"interpolation",null,0.89,0.2,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		_tween_hand = tween.start()
		skeleton_ik.start()

		# Call once to "jumpstart" before process kicks in
		MoveArm(get_process_delta_time())
		pass
	else:
	
		# Transition between tool down and tool up
		var _tween_hand = tween.interpolate_property(skeleton_ik,"interpolation",null,0.0,0.2,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		_tween_hand = tween.start()

		
		pass
	pass

func _process(delta: float):

	#Debug.DrawDebugTransform(global_transform)
	if(skeleton_ik.is_running()):
		MoveArm(delta)
		pass
	pass

# Move the arm IK target to point the arm towards the worldspace mouse position
func MoveArm(delta):

	var current_mouse_world_pos = SceneResources.GetResource("Multitool").GetWorldMousePositionMultitool()
	if current_mouse_world_pos == null:
		return
	var vec_to_target = vis.global_transform.origin - current_mouse_world_pos
	var right_dot_target = vis.global_transform.basis.x.normalized().dot(vec_to_target.normalized())
	var fwd_dot_target = vis.global_transform.basis.z.normalized().dot(vec_to_target.normalized())
	var local_up = Utilities.CalculateGravityDirection(global_transform.origin)

	if(right_dot_target > -0.6 && right_dot_target < 0.91 && fwd_dot_target < 0.0 && vec_to_target.length() > 1.5):

		# Point arm towards target
		new_pos = vis.global_transform.origin - vec_to_target.normalized()
		
		new_pos += local_up * 0.8

		# Move the arm farther out from the player body as the target gets closer to the player
		var modifier_range = inverse_lerp(distance_modifier_range.x,distance_modifier_range.y,vec_to_target.length())
		var modifier = lerp(1.0, 0.05,modifier_range)
		new_pos = new_pos + vec_to_target.normalized() * (modifier - 0.05) + vis.global_transform.basis.x * ( -modifier * 0.3)

		# Rotate IK target to point towards world mouse pos (to align hand)
		var vec_from_hand = global_transform.origin - current_mouse_world_pos
		new_transform = global_transform.looking_at(global_transform.origin - vec_from_hand.normalized(),local_up.normalized()) 
		new_transform = new_transform.rotated(new_transform.basis.x,1.5 * PI)

		# Set new rotation/ position for the hand target
		last_valid_target_rot = new_transform.basis
		last_valid_target_pos = vis.global_transform.xform_inv(new_pos)
		global_transform.basis = global_transform.basis.orthonormalized().slerp(new_transform.basis.orthonormalized(),15.0 * delta)
		

		#DrawLaserLine(tool_barrel.global_transform.origin, current_mouse_world_pos,0.04,Color.red)

		pass

	# Smooth movement
	transform.origin = transform.origin.linear_interpolate(last_valid_target_pos * 3.9,5.0 * delta)
	
	
	# Draw lines from the barrel of the multitool
	# TODO: Check if this even needs implemented ¯\_(ツ)_/¯
	#DrawLaserLine(tool_barrel.global_transform.origin, tool_barrel.global_transform.origin + tool_barrel.global_transform.basis.z.normalized() * 10,0.04,Color.red)
	
	# TODO: Make player vis face towards the target point if its outside the range
	#else:
	#	var new_vis_transform = vis.global_transform.looking_at(vis.global_transform.origin + vec_to_target.normalized(),local_up)
	#	vis.global_transform.basis = vis.global_transform.basis.orthonormalized().slerp(new_vis_transform.basis.orthonormalized(),10.0 * delta).scaled(Vector3(0.252,0.252,0.252))

	pass
	

# Draw the laser lines of the multitool
func DrawLaserLine(start:Vector3, end:Vector3, width:float,color:Color):
	var camera_pos = get_viewport().get_camera().global_transform.origin

	# Subtract camera from line midpoint to get the normal
	#var plane_normal = (camera_pos - (start + ((end - start)/2.0))).normalized();
	var plane_normal = (camera_pos - end).normalized();
	var line_dir = (end - start).normalized()
	var up_dir = plane_normal.normalized().cross(line_dir).normalized()

	start = line_geometry.global_transform.xform_inv(start)
	end = line_geometry.global_transform.xform_inv(end)

	line_geometry.clear()
	line_geometry.begin(Mesh.PRIMITIVE_TRIANGLES);

	line_geometry.set_normal(plane_normal)
	line_geometry.set_color(color)

	#	1---------------------------------------2
	#	|										|
	#   s- - - - - - - - - - - - - - - - - - - -e
	#	|										|
	#	3---------------------------------------4

	# 1 -> 2 -> 3
	line_geometry.add_vertex(start + up_dir * width)
	line_geometry.add_vertex(end + up_dir * width)
	line_geometry.add_vertex(start - up_dir * width)

	line_geometry.set_color(color)
	# 2 -> 3 -> 4
	line_geometry.add_vertex(end + up_dir * width)
	line_geometry.add_vertex(start - up_dir * width)
	line_geometry.add_vertex(end - up_dir * width)


	line_geometry.end()

	pass


# Check when the tween is complete
func OnTweenComplete(object,_key):
	if(object == skeleton_ik && !is_multitool_active):
		skeleton_ik.stop()
	pass

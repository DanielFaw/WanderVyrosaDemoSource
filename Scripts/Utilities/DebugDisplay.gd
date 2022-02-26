extends Node
var reports = {}

var text_label

var debug_timer:Timer

var show_debug = false

const DEBUG_FONT = preload("res://Rendering/Fonts/DebugFont.tres")

var line_draw_queue = {}
var line_draw_static_list = {}

var debug_static_lines_dirty = true

var line_draw = ImmediateGeometry.new()
var line_draw_static = ImmediateGeometry.new()


func _ready():

	# Make sure this is a debug build
	if(OS.is_debug_build()):
		debug_timer = Timer.new()
		add_child(debug_timer)
		_InstantiateDebug()

		# Add debug resources to the ROOT of the game
		get_tree().get_root().call_deferred("add_child",line_draw)
		get_tree().get_root().call_deferred("add_child",line_draw_static)

		var lineMat = SpatialMaterial.new()
		lineMat.flags_unshaded = true
		lineMat.flags_transparent = true
		lineMat.vertex_color_use_as_albedo = true
		
		line_draw.material_override = lineMat
		line_draw_static.material_override = lineMat
	pass


func _input(_event):
	if(OS.is_debug_build()):
		if(Input.is_action_just_pressed("debug_Toggle")):
			show_debug = !show_debug
			if(show_debug):
				_UpdateDebug()
				if(text_label == null):
					_InstantiateDebug()
					text_label.visible = true
				else:
					text_label.visible = true
			else:
				text_label.visible = false
				pass
			pass

# Loops forever
func _UpdateDebug():
	while(show_debug):
		
		# Report the current FPS
		var fps = ""
		if(Performance.get_monitor(0) < 30):
			fps = "[color=red]" + str(Performance.get_monitor(0)) + "[/color]"
			
		else:
			fps = "[color=#00f51b]" + str(Performance.get_monitor(0)) + "[/color]"

		# Report objects rendered and fps
		Report("FPS","FPS: " + fps)
		Report("RenderObjects","Objects Rendered: " + str(Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME)))
		#Report("Resolution",str(OS.get_real_window_size()))
		
		# Wait 0.5 seconds
		debug_timer.start(0.5)
		yield(debug_timer, "timeout")

		# Clear bbcode and parse new
		text_label.parse_bbcode(_BuildReport())
		
	pass

func _InstantiateDebug():
	if(text_label == null):
		# Label creation
		text_label = RichTextLabel.new()
		text_label.rect_size = Vector2(250,300)
		text_label.rect_global_position = Vector2(10,10)
		text_label.scroll_active = true
		text_label.set("custom_fonts/normal_font",DEBUG_FONT)
		# Ignore mouse input
		text_label.mouse_filter = 2

		# Theme creation 
		var theme = StyleBoxFlat.new()
		theme.bg_color = Color('#95262626')
		theme.set_border_width_all(10.0)
		theme.border_color = Color('#95262626')
		theme.set_corner_radius_all(5.0)

		text_label.set("custom_styles/normal",theme)
		text_label.mouse_filter = 2
		add_child(text_label)
		text_label.visible = false
	pass

# Build list of reports
func _BuildReport() ->String:
	var report_string = "[center][u]-DEBUG-[/u][/center]\n"
	for key in reports.keys():
		report_string += reports[key] + "\n"

	reports.clear()
	return report_string
	

func _process(_delta):
	if(OS.is_debug_build()):
		if(show_debug):
			_DrawDebugLines()
			if(debug_static_lines_dirty):
				_DrawDebugStaticLines()
		else:
			if(!debug_static_lines_dirty):
				line_draw.clear()
				line_draw_static.clear()
				debug_static_lines_dirty = true



func _DrawDebugLines():
	line_draw.clear()
	
	line_draw.begin(Mesh.PRIMITIVE_LINES)

	line_draw.set_normal(Vector3.UP)

	# Add vertices for drawing
	for l in line_draw_queue.keys():
		var line_data = line_draw_queue[l]
		line_draw.set_color(line_data[2])
		line_draw.add_vertex(line_data[0])
		line_draw.add_vertex(line_data[1])
		pass

	line_draw.end()
	line_draw_queue.clear()
	
	pass


func _DrawDebugStaticLines():
	line_draw_static.clear()
	
	line_draw_static.begin(Mesh.PRIMITIVE_LINES)

	line_draw_static.set_normal(Vector3.UP)
	
	# Add vertices for drawing
	for l in line_draw_static_list.keys():
		var line_data = line_draw_static_list[l]
		line_draw_static.set_color(line_data[2])
		line_draw_static.add_vertex(line_data[0])
		line_draw_static.add_vertex(line_data[1])
		pass

	line_draw_static.end()
	debug_static_lines_dirty = false
	


# Draw a line for debugging between start and end (in world space) with a certain color
func DrawDebugLine(var start,var end,var color):

	var start_local = line_draw.transform.xform(start)
	var end_local = line_draw.transform.xform(end)
	# Add to queue to be drawn
	line_draw_queue[line_draw_queue.size()] = [start_local,end_local,color]
	

func DrawDebugLineStatic(var start,var end,var color):
	var start_local = line_draw_static.transform.xform(start)
	var end_local = line_draw_static.transform.xform(end)
	# Add to queue to be drawn
	line_draw_static_list[line_draw_static_list.size()] = [start_local,end_local,color]
	debug_static_lines_dirty = true


func DrawDebugTransform(var transformIn:Transform):
	DrawDebugLine(transformIn.origin, transformIn.origin + transformIn.basis.x,Color.red)
	DrawDebugLine(transformIn.origin, transformIn.origin + transformIn.basis.y,Color.green)
	DrawDebugLine(transformIn.origin, transformIn.origin + transformIn.basis.z,Color.blue)
	pass

# Add a string to be reported in the debug display
func Report(var key:String ,var infoToReport:String):
	reports[key] = infoToReport
	pass

func _exit_tree():
	line_draw_static.queue_free()
	line_draw.queue_free()

extends Control

export(Array,Texture) var slide_images

export(Array,String,MULTILINE) var slide_descriptions

export(Array,String) var slide_titles

export(Array,NodePath) var dots

const dot_text_filled = preload("res://Textures/UI/TutorialSS/dot_filled.png")
const dot_text_empty = preload("res://Textures/UI/TutorialSS/dot_empty.png")
# UI Refs

export var slide_title_path:NodePath
var slide_title:Label

export var slide_image_path:NodePath
var slide_image:TextureRect

export var slide_desc_path:NodePath
var slide_desc:RichTextLabel

var current_slide:int = 0


export var home_ship_ping_path:NodePath
var home_ship_ping

func _ready():
	slide_title = get_node(slide_title_path)
	slide_image = get_node(slide_image_path)
	slide_desc = get_node(slide_desc_path)


	# Enable the homeship ping if needed
	if(home_ship_ping_path != ""):
		home_ship_ping = get_node(home_ship_ping_path)

		if(ProgressionManager.GetCheckpointBool("tutorial_viewed") || ProgressionManager.GetAmountPlanetsCompleted() >= 1 ):
			home_ship_ping.SetEnabled(false)
		else:
			home_ship_ping.SetEnabled(true)
			pass

	var _connection = connect("visibility_changed",self,"ActivateCheckpoint")
	ChangeSlide()

	
	pass

# Player has looked at tutorial for the first time
func ActivateCheckpoint():
	if(!ProgressionManager.GetCheckpointBool("tutorial_viewed")):
		ProgressionManager.SetCheckpointBool("tutorial_viewed",true)
		pass
	
	# Disable the ping after the player views the tutorial
	if(home_ship_ping != null):
		home_ship_ping.SetEnabled(false)
		pass
	pass

func ChangeSlideLeft():
	current_slide -=1
	if(current_slide < 0):
		current_slide = slide_titles.size()-1
		pass
	ChangeSlide()
	return

func ChangeSlideRight():
	current_slide += 1
	if(current_slide > slide_titles.size()-1):
		current_slide = 0
		pass
	ChangeSlide()
	return

func ChangeSlide():
	slide_title.text = slide_titles[current_slide]

	# Modify bbcode string using essentially macros
	var new_slide = slide_descriptions[current_slide].replace("[but]","[code][color=#e53b44]").replace("[/but]","[/color][/code]")

	var _parse_result = slide_desc.parse_bbcode(new_slide)
	slide_image.texture = slide_images[current_slide]

	# Fill in dots
	var index = 0
	for d in dots:
		if(index == current_slide):
			get_node(d).texture = dot_text_filled
			pass
		else:
			get_node(d).texture = dot_text_empty
			pass
		index += 1
	pass


func CloseTutorial():
	self.visible = false
	SceneResources.GetResource("Player").SetPlayerInputActive(true)

	# Trigger the navigation ping if it hasn't been viewed yet
	if(SceneResources.HasResource("NavigationManager")):
		if(!ProgressionManager.GetCheckpointBool("navigation_viewed")):
			SceneResources.GetResource("NavigationManager").TriggerPing()
			pass

		pass

	# Enable the homeship ping if needed
	if(home_ship_ping_path != null):
		home_ship_ping = get_node(home_ship_ping_path)
		if(ProgressionManager.GetCheckpointBool("tutorial_viewed")):
			home_ship_ping.SetEnabled(false)
		else:
			home_ship_ping.SetEnabled(true)
			pass
	
	if(!InputState.GetIsGamePaused()):
		InputState.ToggleCursor(false)
	
	pass

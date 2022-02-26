extends Control

export var wave_display_path:NodePath

var wave_display:RichTextLabel
var max_waves


func _ready():
	wave_display = get_node(wave_display_path)
	var _null = SceneResources.GetResource("WaveManager").connect("waveChanged",self,"_UpdateWaveDisplay")
	var _null2 = SceneResources.GetResource("WaveManager").connect("timerStarted", self, "_DisplayWaveTimer")
	var _null3 = SceneResources.GetResource("GameStateManager").connect("onGameOver", self, "_DisplayPlayerWon")
	call_deferred("get_waves")
	pass

func get_waves():
	max_waves = SceneResources.GetResource("WaveManager").max_waves
	pass

func _exit_tree():
	if(SceneResources.GetResource("WaveManager").is_connected("waveChanged",self,"_UpdateWaveDisplay")):
		SceneResources.GetResource("WaveManager").disconnect("waveChanged",self,"_UpdateWaveDisplay")
	if(SceneResources.GetResource("WaveManager").is_connected("timerStarted",self,"_DisplayWaveTimer")):
		SceneResources.GetResource("WaveManager").disconnect("timerStarted",self,"_DisplayWaveTimer")
	if(SceneResources.GetResource("WaveManager").is_connected("timerStarted",self,"_DisplayPlayerWon")):
		SceneResources.GetResource("WaveManager").disconnect("timerStarted",self,"_DisplayPlayerWon")

	pass

func _UpdateWaveDisplay(newWave):
	wave_display.custom_effects[0].resetTimer = true
	var _null = wave_display.parse_bbcode("[center][fadeLine fadeSpeed=1.0 offset=5.0 colorHex=#FFFFFFFF]Wave " + str(newWave) + " of " +str(max_waves)+ "[/fadeLine][center]")
	
	pass

func _DisplayWaveTimer(time, is_first_wave):
	wave_display.custom_effects[0].resetTimer = true
	
	if(is_first_wave):
		#Give some slight instructions
		var _null = wave_display.parse_bbcode("[center][fadeLine fadeSpeed=10.0 offset=5.0 colorHex=#FFFFFFFF]You have " + str(time) + " seconds until enemies spawn and try to defeat your base. Build up your resources and defenses to protect yourself![/fadeLine][center]")
		pass
	else:
		var _null = wave_display.parse_bbcode("[center][fadeLine fadeSpeed=1.0 offset=5.0 colorHex=#FFFFFFFF]" + str(time) + " seconds until enemies send additional reinforcements[/fadeLine][center]")
		pass
	pass
 
func _DisplayPlayerWon(var truefalse):
	if truefalse:
		var _null = wave_display.parse_bbcode("[center][color=white]You have sucessfully defended your fuel ship from the enemies. Head back to go on your next mission [/color][center]")
	pass

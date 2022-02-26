extends Control


onready var my_progress : ProgressBar = $ProgressBar
onready var my_number = $WaveNumDisplay
var max_waves

var spawning_wave : bool = false

var first_wave_done = false

func _ready() -> void:
	var _null = SceneResources.GetResource("WaveManager").connect("waveChanged",self,"display_wave")
	#var _null3 = SceneResources.GetResource("GameStateManager").connect("onGameOver", self, "_DisplayPlayerWon")
	_null = SceneResources.GetResource("WaveManager").connect("total_wave_length", self, "display_wave_timer_real")
	my_progress.value = 0
	call_deferred("get_max_waves")
	pass

func get_max_waves():
	max_waves = SceneResources.GetResource("WaveManager").max_waves
	display_wave(0)
	pass

func display_wave(var curr):
	my_number.text = "Wave " + str(curr) + "/" + str(max_waves)
	if curr == max_waves:
		#Show the text over the progress bar
		$DestroyTroops.visible = true
		pass
	pass

func display_wave_timer_real(var wave_time, var enemy_time):
	if(first_wave_done):
		my_progress.max_value = wave_time + enemy_time
		my_progress.value = my_progress.max_value
		spawning_wave = true
		pass
	else:
		my_progress.max_value = wave_time
		my_progress.value = wave_time
		spawning_wave = true
		first_wave_done = true
		pass

	pass

func _process(delta: float) -> void:
	if !spawning_wave || get_tree().paused:
		return
	my_progress.value -= delta
	if my_progress.value <= my_progress.min_value:
		spawning_wave = false
	
	pass

extends Spatial

export var max_waves:int = 1
var current_wave:int = 0

var _rand = RandomNumberGenerator.new()

export(Array,String) var level_one_enemies
export(Array,String) var level_two_enemies
export(Array,String) var level_three_enemies


# How many enemies should spawn in the first wave
export var base_enemies_per_wave:int = 1

#A curve describing how quickly the amount of enemies increases per wave (0- None 1-Magnitude)
export var enemies_per_wave_increase_rate:Curve

# How fast the amount of enemies per wave increases (multipled by increase rate at the current wave completion percentage)
export var enemies_per_wave_increase_magnitude:float = 0.5

# Defines the 'mean' for the average for each stage with (0-lvl1 and 1-lvl3)
#   mean of 0 will generate mostly lvl1 enemies
export var enemy_difficulty_curve:Curve

export var enemy_standard_deviation:float = 0.15

# How long the delay should be after the easiest wave
export var wave_base_delay:float = 20.0
var current_wave_delay : float
export var first_wave_delay = 40.0

# How much shorter each wave should be for each completed wave
#		Calculated: waveDelay = wave_base_delay - (wave_base_delay * wave_base_delay_change.interpolate(%wavesComplete))
export var wave_base_delay_change:Curve


# The base delay between enemies
export var enemy_spawn_base_delay = 1.5
# How much shorter the enemy spawn delay should be for each completed wave
#		Calculated: enemy_spawn_delay = enemy_spawn_base_delay - (enemy_spawn_base_delay * enemy_spawn_delay_curve.interpolate(%wavesComplete))
export var enemy_spawn_delay_curve:Curve


var enemies_in_wave = []
var current_level_progress = 0.0
var enemy_calculation_thread = Thread.new()
var first_wave = true

var enemy_spawn_delay

var done_adding_enemies = false

# Timers for wave and enemy spawn
var enemy_spawn_timer
var wave_delay_timer

export var music_crossfade_path:NodePath
var music_crosssfade


export var boss_music_audio_path:NodePath

var final_wave_spawned = false

signal waveChanged(newWave)
signal timerStarted(time)
signal total_wave_length(wave_time, enemy_time)

func _init():
	SceneResources.RegisterResource("WaveManager",self)
	pass


func _ready():
	enemy_spawn_timer = Timer.new()
	wave_delay_timer = Timer.new()
	enemy_spawn_timer.one_shot = true
	wave_delay_timer.one_shot = true

	add_child(enemy_spawn_timer)
	add_child(wave_delay_timer)

	music_crosssfade = get_node(music_crossfade_path)

	var _connection = SceneResources.GetResource("GameStateManager").connect("onGameOver",self,"OnGameOver")
	SetWaveParamters()
	pass


# Calculate all the enemies for the next wave
func _CalculateEnemiesForNextWave(var _nullArg):
	done_adding_enemies = false
	enemies_in_wave.clear()
	current_level_progress = float(current_wave) / float(max_waves) 
	#print(current_level_progress)

	# Calculate how many enemies should be in the new wave
	var enemy_amount_in_new_wave = round(base_enemies_per_wave + (enemies_per_wave_increase_rate.interpolate(current_level_progress) * enemies_per_wave_increase_magnitude))

	#print("Adding " + str(enemy_amount_in_new_wave) + " enemies")
	for _i in range(enemy_amount_in_new_wave):

		# Generate a random number using a bell curve/ normal distribution
		# This is used to determine what "level" of enemy should be spawned next
		var normal_rand_value = _rand.randfn(enemy_difficulty_curve.interpolate(current_level_progress),enemy_standard_deviation)
		#print(normal_rand_value)


		# Get a random enemy from each spawn
		if(normal_rand_value >= 0.66):
			#print("Added lvl-3 enemy")
			enemies_in_wave.push_back(level_three_enemies[_rand.randi_range(0,level_three_enemies.size()-1)])
			pass
		elif(normal_rand_value >= 0.33):
			#print("Added lvl-2 enemy")
			enemies_in_wave.push_back(level_two_enemies[_rand.randi_range(0,level_two_enemies.size()-1)])
			pass
		elif(normal_rand_value >= 0.0):
			#print("Added lvl-1 enemy")
			enemies_in_wave.push_back(level_one_enemies[_rand.randi_range(0,level_one_enemies.size()-1)])
			pass
		#print(i)
		yield(get_tree().create_timer(0.01),"timeout")

		pass
	pass
	done_adding_enemies = true
	#print("Done adding enemies")


func OnGameOver(player_won):

	music_crosssfade.SetFadeData([],[get_node(boss_music_audio_path).get_path()],[],2)
	music_crosssfade.StartCrossFade(5.0)
	pass


# Handle end of wave logic
func _WaveComplete():
	#print("Wave " + str(current_wave) + " complete!")

	current_wave += 1
	current_level_progress = float(current_wave) / float(max_waves)

	if(current_wave <= max_waves):
		
		current_wave_delay -= current_wave#= wave_base_delay + (wave_base_delay * wave_base_delay_change.interpolate(current_level_progress))
		current_wave_delay = clamp(current_wave_delay, 5.0, 60.0)

		# Calculate the enemies for the next wave
		if(enemy_calculation_thread.is_active()):
			enemy_calculation_thread.wait_to_finish()
		enemy_calculation_thread.start(self,"_CalculateEnemiesForNextWave")
		
		# Wait for delay, then start the new wave
		enemy_spawn_delay = enemy_spawn_base_delay - (enemy_spawn_base_delay * enemy_spawn_delay_curve.interpolate(current_level_progress))
	
		if first_wave:
			#Wait a while
			wave_delay_timer.start(first_wave_delay)
			emit_signal("timerStarted", first_wave_delay, first_wave)
			emit_signal("total_wave_length", first_wave_delay, enemy_spawn_delay * enemies_in_wave.size())
			#yield(wave_delay_timer,"timeout")
		
			
			current_wave_delay = 20.0
			#print("Base wave delay : " + str(wave_base_delay))
			pass
		else:
			wave_delay_timer.start(current_wave_delay)
			emit_signal("timerStarted", current_wave_delay, first_wave)
			
			pass
		
		
		yield(wave_delay_timer,"timeout")
		_StartNewWave()
		pass

	else:
		# Mark that the last wave has been spawned
		final_wave_spawned = true
		pass

	pass


# Start a new wave
func _StartNewWave():
	
	emit_signal("waveChanged", current_wave)
	emit_signal("total_wave_length", current_wave_delay, enemy_spawn_delay * enemies_in_wave.size())
	play_wave_sound()
	
	#print("Starting wave " + str(current_wave) + " with enemy delay: " + str(enemy_spawn_delay))
	while(enemies_in_wave.size() > 0):
		enemy_spawn_timer.stop()
		# Tell the enemy manager to spawn a specified enemy
		SceneResources.GetResource("EnemyManager").SpawnEnemy(enemies_in_wave.pop_front())
		enemy_spawn_timer.start(enemy_spawn_delay)
		yield(enemy_spawn_timer,"timeout")
		
		pass

	# Once we've spawned all the enemies, mark the wave as complete
	first_wave = false
	_WaveComplete()
	pass


func _exit_tree():
	if(enemy_calculation_thread.is_active()):
		enemy_calculation_thread.wait_to_finish()
	enemy_spawn_timer.queue_free()
	wave_delay_timer.queue_free()
	

func SetWaveParamters():
	var current_difficulty = ProgressionManager.GetCurrentDifficulty()
	print("Current difficulty: " + str(current_difficulty))
	max_waves = int(pow(current_difficulty /3.0,1.2) + 3)
	max_waves = int(clamp(max_waves,1,25))

	base_enemies_per_wave = int(floor((current_difficulty/3) + 5))
	enemies_per_wave_increase_magnitude = ceil(sqrt(current_difficulty))
	print("base enemies per wave: " + str(base_enemies_per_wave))
	print("increase of enemies per wave: " + str(enemies_per_wave_increase_magnitude))

	pass

func play_wave_sound():
	if !first_wave:
		$WaveSound.play()
	pass


# Start the new level
func StartLevel():
	music_crosssfade.StartCrossFade(5,4)
	_WaveComplete()

	
#-------------ACCESSORS------------------

func GetFinalWaveSpawned():
	return final_wave_spawned

#-----------------------------------------

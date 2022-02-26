extends Node

enum GAMESTATE {PLAYING,PAUSED,GAMEOVER}

var current_state = GAMESTATE.PLAYING

var player_won = false

export var player_win_label_path:NodePath
var _player_win_label;

signal gameStateChanged(new_state)
signal onGameOver(win_loss)

var current_planet_id:int = -1

func _init():
	SceneResources.RegisterResource("GameStateManager",self);

func _ready():
	var _null = SceneResources.GetResource("EnemyManager").connect("enemyListEmpty",self,"CheckForGameOver")
	_player_win_label = get_node(player_win_label_path)

	# Set the id of the current planet
	if(SceneManager.GetActiveSceneArgs().has("current_planet_id")):
		current_planet_id = SceneManager.GetActiveSceneArgs()["current_planet_id"]
		pass
	pass

# Set the current Game state
func SetGameState(var new_state:String):

	match(new_state):
		"PLAYING":
			current_state = GAMESTATE.PLAYING
			pass
		"PAUSED":
			current_state = GAMESTATE.PAUSED
			pass
		"GAMEOVER":
			current_state = GAMESTATE.GAMEOVER
			pass
		# Default- Do nothing and print error
		_:
			printerr("ERROR: Gamestate " + str(new_state) + " is not a valid state!")
			print_stack()
			return
	
	# Update any listeners
	emit_signal("gameStateChanged",new_state);
	
	pass

# Check if the level has ended
func CheckForGameOver():
	if(SceneResources.GetResource("WaveManager").GetFinalWaveSpawned()):
		GameOver(true)
		pass
	pass

# Trigger Game over logic
func GameOver(var has_player_won:bool = false):
	player_won = has_player_won
	SetGameState("GAMEOVER")

	# Notify other listeners
	emit_signal("onGameOver",has_player_won)

	if(current_planet_id == -1):
		printerr("Planet id was never set!")
		print_stack()
		return
		
	# Mark that the planet was completed
	if(has_player_won):
		ProgressionManager.PlanetComplete(current_planet_id)
		if(SceneManager.GetActiveSceneArgs().has("planet_is_last")):
			if(SceneManager.GetActiveSceneArgs()["planet_is_last"]):
				ProgressionManager.SystemComplete()
			pass
		pass
	pass
	

func _exit_tree():
	SceneResources.GetResource("EnemyManager").disconnect("enemyListEmpty",self,"CheckForGameOver")
	pass

# ---------------------------------ACCESSORS---------------------------------
func GetCurrentState():
	match(current_state):
		GAMESTATE.PLAYING:
			return "PLAYING"
			pass
		GAMESTATE.PAUSED:
			return "PAUSED"
			pass
		GAMESTATE.GAMEOVER:
			return "GAMEOVER"
			pass

	pass

func GetPlayerWin():
	if(current_state == GAMESTATE.GAMEOVER):
		return player_won
	return false
# ---------------------------------------------------------------------------

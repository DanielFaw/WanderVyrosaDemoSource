extends Button


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

var playernum = "../MaxPlayerOptions/MaxPlayersInput"
var diffnum = "../DifficultyOptions/DifficultyChoice"
var planetnum = "../PlanetOptions/PlanetChoice"

signal server_changes(playerCount, difficultyNumber, planetNumber)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_SubmitButton_pressed() -> void:
	emit_signal("server_changes", get_node(playernum).get_text(), get_node(diffnum).get_text(), get_node(planetnum).get_text())
	get_node("../..").visible = false
	get_node("../../../MultiplayerOptions").visible = true
	pass # Replace with function body.

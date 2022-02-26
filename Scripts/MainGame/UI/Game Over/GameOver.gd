extends Control




func _ready() -> void:
	SceneResources.GetResource("GameStateManager").connect("onGameOver", self, "commence_game_over")
	
	pass


func commence_game_over(var over):
	#True if the player won, which we don't care about
	if(over):
		return
	SceneResources.GetResource("Player").SetPlayerInputActive(false)
	#If the player didnt win
	visible = true
	#Fade to black
	$AnimationPlayer.play("fade_to_black")
	

	pass

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	match(anim_name):
		"fade_to_black":
			display_message("first")
			pass
		"fade_in_first":
			#Start message 2 after 0.5 seconds
			yield(get_tree().create_timer(1.3), "timeout")
			display_message("second")
			pass
		"fade_out_first":
			#Display message 3
			display_message("third")
			pass
		"fade_in_second":
			#Fade out first message
			$message_1/AnimationPlayer.play("fade_out_first")
			pass
		"fade_out_second":
			#Send to home screen
			yield(get_tree().create_timer(0.8), "timeout")
			get_tree().paused = false
			SceneManager.LoadScene("mainMenu")
			pass
		"fade_in_third":
			$message_2/AnimationPlayer.play("fade_out_second")
			pass
		"fade_out_third":
			#Yeah
			pass

			pass#End match
	
	pass # Replace with function body.

func display_message(var name):
	#Display the messages
	if name == "first":
		$message_1/AnimationPlayer.play("fade_in_first")
		pass
	elif name == "second":
		$message_2/AnimationPlayer.play("fade_in_second")
		pass
	elif name == "third":
		$message_3/AnimationPlayer.play("fade_in_third")
		pass
	
	#Display the menu button
	
	pass

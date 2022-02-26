extends Control

#export var chatDisplayPath:NodePath
export var chatBackgroundPath:NodePath
export var chatInputPath:NodePath
export var promptPath:NodePath
export var chatLogTweenPath:NodePath
export var chatLogWrapperPath:NodePath

export var _playerName = "Bunkus Dunkus"
export var _playerColor: Color

#var chatDisplay:RichTextLabel
var chatBackground;
var chatInput:TextEdit
var chatPrompt:TextEdit
var chatLogTween:Tween
var chatLogWrapper

signal chatPushed(message)
func _init():
	SceneResources.RegisterResource("PlayerChat",self);

# Set the user info to be displayed in chat
func SetPlayerChatInfo(username:String,color:Color):
	_playerName = username
	_playerColor = color;
	pass

func _ready():
	#chatDisplay = get_node(chatDisplayPath)
	chatBackground = get_node(chatBackgroundPath)
	chatInput = get_node(chatInputPath)
	chatPrompt = get_node(promptPath)
	chatLogTween = get_node(chatLogTweenPath)
	chatLogWrapper = get_node(chatLogWrapperPath)

	chatPrompt.visible = true;
	chatInput.visible = false;
	var _null = InputState.connect("inputStateChanged",self,"_OnInputStateChange")
	
	_CloseChat();
	pass

#func _process(_delta: float):
	#if(Input.is_action_just_pressed("chat_open") && InputState.GetCurrentInputState() == "ALL"):
	#	_OpenChat()
#
	#if(Input.is_action_just_pressed("ui_cancel") && InputState.GetCurrentInputState() == "UI_CONTROL"):
	#	#_CloseChat()
	#	pass
#
	#if(Input.is_action_just_pressed("chat_submit") && InputState.GetCurrentInputState() == "UI_CONTROL"):
#
	#	var sanitized = chatInput.text.trim_prefix(" ").trim_suffix(" ")
	#	if(!sanitized.replace('\n',"").replace(" ","").empty()):
#
	#		# Log the message in chat 
	#		# TODO: ROB- Add event to listener to network manager 
	#		emit_signal("chatPushed",sanitized)
	#		SceneResources.GetResource("ChatDisplay").PushMessage(_playerName,_playerColor,sanitized)
	#	_CloseChat()
#
	#pass

func _CloseChat():
	chatBackground.visible = false
	if(InputState.GetCurrentInputState() != "ALL"):
		InputState.ChangeInputState("ALL")
		
	chatInput.visible = false
	chatPrompt.visible = true
	_PlayCloseAnim();
	
	pass

func _OnInputStateChange(newState):
	if(newState == 0):
		_CloseChat()

func _OpenChat():
	chatBackground.visible = true
	chatInput.text = ""
	chatInput.visible = true
	chatPrompt.visible = false
	chatInput.grab_focus()
	InputState.ChangeInputState("UI_CONTROL")
	#var animTime = 0.2
	#var _null = chatLogTween.interpolate_property(chatLogWrapper,"rect_size",chatLogWrapper.rect_size,Vector2(chatLogWrapper.rect_size.x,200),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);
	#_null = chatLogTween.interpolate_property(chatLogWrapper,"rect_position",chatLogWrapper.rect_position,Vector2(chatLogWrapper.rect_position.x,0),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);
	#_null = chatLogTween.interpolate_property(chatDisplay,"rect_size",chatDisplay.rect_size,Vector2(chatDisplay.rect_size.x,180),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);
	#_null = chatLogTween.interpolate_property(chatDisplay,"rect_position",chatDisplay.rect_position,Vector2(chatDisplay.rect_position.x,4),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);

	#_null = chatLogTween.start()
	pass



func _PlayCloseAnim():
	#var animTime = 0.2
	#var _null = chatLogTween.interpolate_property(chatLogWrapper,"rect_size",chatLogWrapper.rect_size,Vector2(chatLogWrapper.rect_size.x,65),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);
	#_null = chatLogTween.interpolate_property(chatLogWrapper,"rect_position",chatLogWrapper.rect_position,Vector2(chatLogWrapper.rect_position.x,130),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);
	#_null = chatLogTween.interpolate_property(chatDisplay,"rect_size",chatDisplay.rect_size,Vector2(chatDisplay.rect_size.x,70),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);
	#_null = chatLogTween.interpolate_property(chatDisplay,"rect_position",chatDisplay.rect_position,Vector2(chatDisplay.rect_position.x,-5),animTime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT);
#
	#_null = chatLogTween.start()
	pass

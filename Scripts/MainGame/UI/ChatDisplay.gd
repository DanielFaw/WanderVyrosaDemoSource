extends RichTextLabel

var chat_backup = "";

func _init():
	SceneResources.RegisterResource("ChatDisplay",self)
	pass

func _ready():
	var _null = get_tree().get_root().connect("size_changed",self,"_OnResize")
	chat_backup = bbcode_text

func _OnResize():
	# Backup of chat is kept and readded on window resize to mitigate bug report below
	# https://github.com/godotengine/godot/issues/22203
	var _null = parse_bbcode(chat_backup);

	pass

func PushMessage(username,color:Color,message):
	message = message.replace("[","").replace("]","")
	var newMessage =  "\n" + "[color=#" + str(color.to_html()) + "]" + str(username) + "[/color]: " + message.trim_prefix(" ")
	var _null = append_bbcode(newMessage);	
	chat_backup += newMessage
	pass

func _exit_tree():
	if( get_tree().get_root().is_connected("size_changed",self,"_OnResize")):
		get_tree().get_root().disconnect("size_changed",self,"_OnResize")

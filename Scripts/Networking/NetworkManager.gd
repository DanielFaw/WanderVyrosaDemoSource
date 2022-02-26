extends Node

const SERVER_STATUS = {
	JOINED = 0,
	DISCONNECTED = 1,
	WAITING_FOR_CONNECTION = 2,
	DECLINED = 3,
	FAILED = 4
}



var SERVER_IP : String
var SERVER_PORT = 42069
var CLIENT_PORT = 45054
var portNum : int = 0
var myPeer : myUDPClient
var myServer : myUDPServer
var created = false
var username : String
var pickedColor
var mpath = "../../UI/MarginContainer/Container/MultiplayerOptions/MarginContainer/VBoxContainer"
var cpath = "../../UI/MarginContainer/Container/Chat"
var server_settings = {
	"maxPlayers" : DEFAULT_PLAYER_COUNT,
	"difficulty" : DEFAULT_DIFF,
	"planet" : DEFAULT_PLANET
}

const MIN_PLAYER_COUNT = 2
const DEFAULT_PLAYER_COUNT = 4
const MAX_PLAYER_COUNT = 8


const MIN_DIFF = 1
const DEFAULT_DIFF = 3
const MAX_DIFF = 5

const MIN_PLANET = 1
const DEFAULT_PLANET = 1
const MAX_PLANET = 20


func _ready():
	SceneResources.GetResource("PlayerChat").connect("chatPushed", self, "_send_message")
	pass


func _do_server_status(newStatus):
	match(newStatus):
		SERVER_STATUS.WAITING_FOR_CONNECTION:
			#Don't do anything just yet
			toggle_multiplayer_ui(false)
			print("\tWaiting for connection to server...")
			pass
		SERVER_STATUS.JOINED:
			toggle_multiplayer_ui(false)
			print("\tSuccessfully joined the server!")
			pass
		SERVER_STATUS.DISCONNECTED:
			toggle_multiplayer_ui(true)
			print("\tYou have been disconnected from the server.")
			_shutdown_client()
			pass
		SERVER_STATUS.DECLINED:
			toggle_multiplayer_ui(true)
			_shutdown_client()
			print("\tDeclined from joining the server. It's probably full, but who REALLY knows")
			pass
		SERVER_STATUS.FAILED:
			toggle_multiplayer_ui(true)
			_shutdown_client()
			print("\tFailed to join server. No connection established.")
			pass
	pass

func _process_server_changes(players, diff, plan):

	#Check the player count
	var pcount = int(players)
	print("pcount: " + str(pcount))
	if pcount >= MIN_PLAYER_COUNT && pcount <= MAX_PLAYER_COUNT:
		server_settings["maxPlayers"] = pcount
		pass
	
	#Check the difficulty (does nothing rn)
	var dval = int(diff)
	if dval > MIN_DIFF && dval < MAX_DIFF:
		server_settings["difficulty"] = dval
		pass
	
	#Check the planet (does nothing rn)
	var pval = int(plan)
	if pval > MIN_PLANET && pval < MAX_PLANET:
		server_settings["planet"] = pval
		pass
	
	print("Server properties were changed. playercount=" + str(server_settings["maxPlayers"]))
	pass
	

#True: show UI
#False: hide UI
func toggle_multiplayer_ui(bruh : bool):
	#True means show the multiplayer UI (hasn't joined a server yet)
	created = !bruh
	#Make the following UI elements invisible: Username, IP, and create/join server buttons
	get_node(mpath + "/UsernameInput").visible = bruh
	get_node(mpath + "/ServerStuff").visible = bruh
	get_node(mpath + "/IPInput").visible = bruh
	get_node(mpath + "/JoinServer").visible = bruh
	get_node(mpath + "/ColorList").visible = bruh
	
	
	get_node(mpath + "/IPAddr").visible = !bruh
	
	#Make the chat visible (or not)
	get_node("../../UI/MarginContainer/Container/Chat").visible = !bruh
	var myColor = get_node(mpath + "/ColorList").get_item_custom_fg_color(pickedColor)
	SceneResources.GetResource("PlayerChat").SetPlayerChatInfo(username, myColor)
	get_node(mpath + "/IPAddr").text = SERVER_IP
	
	if myServer == null:
		#This is a client
		get_node(mpath + "/LeaveButton").visible = !bruh
		get_node(mpath + "/CloseServerButton").visible = false
		pass
	else:
		#This is a server
		get_node(mpath + "/LeaveButton").visible = false
		get_node(mpath + "/CloseServerButton").visible = !bruh
		pass

	pass



func SetAsClient() -> String:
	#Set up the two clients to connect to eachother?
	#send to the client port and listen though the server port
	if !created:
		#myPeer = null
		username = get_node(mpath + "/UsernameInput").text
		
		if username.length() == 0:
			username = "Unnamed Crewmate"
			
		var colorarr = get_node(mpath + "/ColorList").get_selected_items()
		pickedColor = colorarr[0]
		
		myPeer = myUDPClient.new(SERVER_PORT, CLIENT_PORT, SERVER_IP, username, pickedColor)
		myPeer.connect("server_status", self, "_do_server_status")
		add_child(myPeer)

		return "Client created"
	else:
		return "As much as I appreciate the enthusiasm, you can't make another client/server right now"
	
	
	pass

	
func SetAsServer() -> String:
	if !created:
		#myServer = null
		var ipIndex : int
		
		#Check the OS of the server, since different (OSes? OSs? OS'? OSs'? bruh) have their IPv4 in different places in their array, because OS developers literally hate everyone and everything
		if(OS.get_name() == "Windows"):
			ipIndex = 3
		else:
			ipIndex = 2
		
		#Set the server settings :-)
		
		SERVER_IP = IP.get_local_addresses()[ipIndex]
		myServer = myUDPServer.new(SERVER_PORT, SERVER_IP, CLIENT_PORT, server_settings)
		add_child(myServer)
		SetAsClient()
		return "Server was created"
	else:
		return "As much as I appreciate the enthusiasm, you can't make another client/server right now"
	pass
	

func _send_message(message) -> void:
	#Send the server a message via the client
	#Clear out the message text
	if myPeer != null:
		myPeer.send_message(message)
	pass # Replace with function body.


func _on_CreateServer_pressed() -> void:
	print(SetAsServer())
	pass # Replace with function body.


func _on_JoinServer_pressed() -> void:
	SERVER_IP = get_node(mpath + "/IPInput").text
	print(SetAsClient())
	pass # Replace with function body.


func _on_SubmitButton_server_changes(playerCount, difficultyNumber, planetNumber) -> void:
	#TODO: I got lazy and should have 
	_process_server_changes(playerCount, difficultyNumber, planetNumber)
	pass # Replace with function body.


func _on_CloseServerButton_pressed() -> void:
	#Talk to the server to send the clients a message saying goodbye
	_shutdown_server()
	pass # Replace with function body.


func _on_LeaveButton_pressed() -> void:
	#Talk to the client to send a message to the server saying goodbye
	_shutdown_client()
	pass # Replace with function body.

func _shutdown_server():
	myServer.disband_lobby()
	
	myServer.queue_free()
	myServer = null
	pass

func _shutdown_client():
	if myPeer != null:
		myPeer.disconnect_me()
		if myPeer.is_connected("server_status", self, "_do_server_status"):
			myPeer.disconnect("server_status", self, "_do_server_status")
		myPeer.queue_free()
		myPeer = null
	pass

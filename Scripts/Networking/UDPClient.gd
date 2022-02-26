class_name myUDPClient
extends Node

const MSG_TYPE = {
	MESSAGE = "msg",
	PORTCHANGE = "ptc",
	UPDATEPOS = "udpos",
	DISCONNECT = "dc",
	ADDME = "add",
	ADDOTHER = "addo",
	BUILDTOWER = "bt",
	DECLINED = "bozo",
	KICKED = "bruh",
	HEARTBEAT = "hb"
}

const SERVER_STATUS = {
	JOINED = 0,
	DISCONNECTED = 1,
	WAITING_FOR_CONNECTION = 2,
	DECLINED = 3,
	FAILED = 4
}

var personalPeer : PacketPeerUDP
var counter = 0
var myNum : int #This will get set by the server
var SERVER_IP
var SERVER_LISTEN
var SERVER_SEND

const TICK_RATE = 1.0/16.0

var hasPortChanged = false
var readyToSend = false
var connectionTimer = 0
const CONNECTION_TIME = 5.0
const DISCONNECTION_TIME = 3.0
var timeSincePacket = 0
var heartbeat = 0

var playerData = {
	"num" : {
		"username" : "name",
		"color" : "color",
		"model" : "model",
		"position" : "position"
	}
}

var playerNums = [] #array of player IDs

var playerPath = "/root/_PROTO_SCENE/Player/_VIS"
#onready var chatLabel = get_node("/root/_PROTO_SCENE/NetAndUIManager/UIManager/ChatLabel")
onready var otherPlayerScripts = load("res://Scripts/Networking/ClientSide/NonLocalCharacterController.gd")

var towerPaths = {
	"gat" : "res://Prefabs/Towers/T_Gattling.tscn",
	"drill" : "res://Prefabs/Towers/T_ResourceDrill.tscn"
}


var myHandshake

var myUsername : String
var colorInt : int
var myColor : Color
var myColorPickerPath = "/root/_PROTO_SCENE/UI/MarginContainer/Container/MultiplayerOptions/MarginContainer/VBoxContainer/ColorList"

var currentServerStatus

signal server_status(currentStatus)


#INIT FUNCTIONS
func _ready() -> void:
	
	SceneResources.GetResource("BuildingController").connect("towerBuilt", self, "build_tower")
	#Emit WAITING_FOR_CONNECTION, and if no PORT_CHANGE is received within a certain time, kill the connection
	emit_signal("server_status", SERVER_STATUS.WAITING_FOR_CONNECTION)
	
	myHandshake = reliableUDP.new()
	add_child(myHandshake)
	
	_add_myself()
	pass

func _init(send_port : int, listen_port : int, server_ip : String, username : String, selectedColor : int) -> void:
	SERVER_IP = server_ip
	SERVER_LISTEN = listen_port
	SERVER_SEND = send_port
	personalPeer = PacketPeerUDP.new()
	personalPeer.listen(SERVER_LISTEN)
	personalPeer.set_dest_address(SERVER_IP, SERVER_SEND)
	myUsername = username
	colorInt = selectedColor
	pass

func _add_myself() -> void:
	var myJson = {
		"name" : myUsername,
		"color" : colorInt
	}
	_message_server(myJson, MSG_TYPE.ADDME)
	pass

#UPDATE FUNCTIONS

func _process(delta : float) -> void:
	_check_connection(delta)
	counter += delta
	if(counter >= TICK_RATE):
		counter -= TICK_RATE
		_send_stuff()
		pass
	_get_stuff()
	_update_player_positions()
	pass

func _check_connection(delta):
	#Update the timer if needed
	if !hasPortChanged:
		connectionTimer += delta
		if connectionTimer > CONNECTION_TIME:
			#Tell the client the conneciton failed
			emit_signal("server_status", SERVER_STATUS.FAILED)
			personalPeer.close()
			pass
		pass
	else:
		timeSincePacket += delta
		if timeSincePacket > DISCONNECTION_TIME:
			emit_signal("server_status", SERVER_STATUS.DISCONNECTED)
			personalPeer.close()
			pass
		
		#Sometimes there isn't a whole lot being sent back and forth, so make sure the server knows you're alive
		heartbeat += delta
		if heartbeat > 1:
			heartbeat = 0
			_message_server("", MSG_TYPE.HEARTBEAT)
			pass
		pass
	pass


#MESSAGING FUNCTIONS
	#GET
func _get_stuff() -> void:
	if personalPeer.get_available_packet_count() > 0:
		while personalPeer.get_available_packet_count() > 0:
			var message = personalPeer.get_packet().get_string_from_utf8()
			_process_stuff(message)

	pass

	#SEND
func _send_stuff() -> void:

	#Send an UPDATEPOS to the server, correctly formatted
	if(hasPortChanged):
		_message_server(_send_update_position(), MSG_TYPE.UPDATEPOS)
	var allPackets = myHandshake.send_packet()
	if allPackets != null:
		for i in range(allPackets.size()):
			#Send message to server with the header and stuff
			var json = {
				"head" : allPackets[i]["head"],
				"body" : allPackets[i]["body"]
			}
			_actually_message_server(json)
			pass
		pass
	
	pass
	
func _message_server(message, command : String) -> void:
	var messageToSend = {
		"mt" : command,
		"data" : {
			"msg" : message
		}
	}
	#for send in range(3):
	myHandshake.push_msg(messageToSend)
	pass

func _actually_message_server(info):
	
	###LAGGER###
	if Utilities.GetRandomValue(1,0) <= 0.05:
		print("client skipped #" + str(info["head"]["s"]))
		return
	###LAGGER###
	personalPeer.put_packet(JSON.print(info).to_utf8())
	pass

func _send_update_position():
	#var myPosition : String = str(myNum) + "," + _encode_position(get_node(playerPath).get_global_transform())
	#print("position being sent: " + myPosition)
	var myNode : Node = get_node(playerPath)
	var myPosition = {
		"pos" : var2str(myNode.get_owner().get_global_transform().origin),
		"bas" : var2str(myNode.get_global_transform().basis)
	}
	return myPosition

#PROCESSING DATA - IN ORDER
	
func _process_stuff(pkt : String) -> void:
	#split up the packet to get wanted info
	var thisData = parse_json(pkt)
	
	timeSincePacket = 0
	heartbeat = 0
	#We're disregarding the head for rn sadly
	
	var allInfo = myHandshake.receive_packet(thisData)
	if allInfo == null:
		#The client was send a dead header, so they're probably going to be kicked
		_process_msg_type(thisData["body"])
		return #Exit da function
	
	for i in range(allInfo.size()):
		var thisPacket = allInfo[i]
		for k in range(thisPacket.size()):
			var packetmsg = thisPacket[k]
			_process_msg_type(packetmsg)
			pass #End of loop k
		pass #End of loop i
	pass #End of function

func _process_msg_type(recInfo) -> void:
	match(recInfo["mt"]):
		MSG_TYPE.MESSAGE:
			#This is what is called for a message to be printed/displayed
			_process_message(recInfo["data"])
		MSG_TYPE.PORTCHANGE:
			#This is what is called for a port change, basically an init
			_process_port_change(recInfo["data"])
		MSG_TYPE.UPDATEPOS:
			#This is what is called for a position update
			_process_update_position(recInfo["data"])
		MSG_TYPE.DISCONNECT:
			_process_disconnect(recInfo["data"])
		MSG_TYPE.ADDME:
			print("No pkt type ADDME accepted by CLIENT right now")
		MSG_TYPE.ADDOTHER:
			#This is what is called for adding another client
			_process_new_client(recInfo["data"])
		MSG_TYPE.BUILDTOWER:
			#Build a tower :D
			_process_new_tower(recInfo["data"])
			pass
		MSG_TYPE.DECLINED:
			#The server was full, so don't really do anything other than let them know they might have to try again later
			_process_declined(recInfo["data"])
			pass
		MSG_TYPE.KICKED:
			_process_kick(recInfo["data"])
			pass
		MSG_TYPE.HEARTBEAT:
			#This is intentionally blank
			pass
		_:
			print("Client received incorrectly formatted packet")
			pass
			pass #End of match
	pass

func _process_new_tower(info) -> void:
	var myData = info["msg"]
	
	var towerPos = myData["pos"]
	var towerType = myData["type"]
	
	var thisTower = load(towerPaths[towerType])
	var newTower = thisTower.instance()
	get_tree().get_current_scene().add_child(newTower)
	
	
	var towerTrans = Transform(Utilities.str_to_basis(towerPos["bas"]), Utilities.str_to_v3(towerPos["org"]))
	
	newTower.global_transform = towerTrans
	newTower.rotation_degrees = Utilities.str_to_v3(towerPos["rot"])
	
	
	pass

func _process_message(info) -> void:
	#Get the username
	var username = playerData[int(info["num"])]["username"]
	
	var message : String
	if info["msg"] is String:
		message = info["msg"]
	else:
		message = info["msg"]["msg"]
		pass
	
	var pColor = playerData[int(info["num"])]["color"]
	SceneResources.GetResource("ChatDisplay").PushMessage(username,pColor,message)
	pass
	
func _process_port_change(info) -> void:
	#change listening port to the given port
	if hasPortChanged:
		return
	SERVER_LISTEN = int(info)
	personalPeer.close()
	personalPeer.listen(SERVER_LISTEN)
	personalPeer.set_dest_address(SERVER_IP, SERVER_SEND)
	print("listening port changed to " + info)
	hasPortChanged = true
	emit_signal("server_status", SERVER_STATUS.JOINED)
	#I was added! :D
	pass
	
func _process_update_position(info) -> void:
	playerData[int(info["num"])]["position"] = {
		"pos" : str2var(info["msg"]["pos"]),
		"bas" : str2var(info["msg"]["bas"])
	}
	#print(info["msg"])
	pass

func _process_new_client(info) -> void:
	var clientNum : int = int(info["num"])
	if playerNums.size() > 0 && playerNums.has(int(info["num"])):
		return
	playerData[clientNum] = {}
	
	playerData[clientNum]["username"] = info["name"]
	playerData[clientNum]["color"] = get_node(myColorPickerPath).get_item_custom_fg_color(info["color"])
	
	#print("Creating a non-local character for #" + str(clientNum))
	_add_another_client(clientNum)
	pass

func _process_kick(info) -> void:
	emit_signal("server_status", SERVER_STATUS.DISCONNECTED)
	personalPeer.close()
	#Nothing else needs to be done i think right? a new client will get created after. idk tho.
	pass

func _process_declined(info) -> void:
	#Make a popup or alert box thing maybe?
	emit_signal("server_status", SERVER_STATUS.DECLINED)
	personalPeer.close()
	#print(info)
	pass

func _process_disconnect(info) -> void:
	#The message doesn't matter for disconnects. Just kinda remove every single reference to them. :c
	var numToRemove = int(info["num"])
	var numCopy = playerNums.duplicate(true)
	for i in range(numCopy.size()):
		if numCopy[i] == numToRemove:
			var removeMessage = "I guess that " + playerData[numToRemove]["username"] + " either rage quit, lagged out, had their mom yell at them that dinner is ready, or maybe did a little bit of all of those things. They will be missed very much."
			SceneResources.GetResource("ChatDisplay").PushMessage("SERVER", Color.seashell, removeMessage)
			playerNums.remove(i)
			playerData[numToRemove]["model"].queue_free()
			playerData.erase(numToRemove)
			
			pass
		pass
	
	
	pass
	
#EXITING FUNCTIONS
func _exit_tree() -> void:
	personalPeer.close()
	pass

#UTILITY FUNCTIONS
func build_tower(towerTrans, rotationDeg, towerType):
	print("building tower of type " + towerType)
	var towerString = ""
	if(towerType == "Resource Drill"):
		towerString = "drill"
		pass
	elif (towerType == "Gattling Tower"):
		towerString = "gat"
		pass
	
	var json = {
		"pos" : {
			"org" : towerTrans.origin,
			"bas" : towerTrans.basis,
			"rot" : rotationDeg
		},
		"type" : towerString
	}
	_message_server(json, MSG_TYPE.BUILDTOWER)
	pass

func _add_another_client(playerNum : int) -> void:
	var playerLoad = load("res://Prefabs/Multiplayer/P_RemotePlayer.tscn")
	var playerObject = playerLoad.instance()
	playerObject.on_ready(playerNum)
	playerNums.append(playerNum)
	var basePosition = {
		"pos" : Vector3.ZERO,
		"bas" : Basis.IDENTITY
	}
	get_tree().get_current_scene().add_child(playerObject)
	
	playerData[playerNum]["model"] = playerObject
	playerData[playerNum]["position"] = basePosition
	
	pass
	
func _update_player_positions():
	for i in range(playerNums.size()):
		if(playerData[playerNums[i]]["position"]["pos"] == Vector3.ZERO && playerData[playerNums[i]]["position"]["bas"] == Basis.IDENTITY):
			return
		var position = playerData[playerNums[i]]["position"]
		var newTransform = Transform(position["bas"], position["pos"])
		#playerDataDict[playerData[i]]["model"].global_transform = newTransform
		playerData[playerNums[i]]["model"].UpdateTargetPosition(newTransform)
		pass
	pass

func disconnect_me():
	#Called from NetworkManager
	_message_server("bye bye", MSG_TYPE.DISCONNECT)
	pass

func send_message(info : String) -> void:
	_message_server(info, MSG_TYPE.MESSAGE)
	pass
	

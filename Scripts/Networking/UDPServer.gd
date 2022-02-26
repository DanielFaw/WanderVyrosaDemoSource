class_name myUDPServer
extends Node
#UDPServer takes in data and sends it to the other clients

"""
todo:
	the server shouldnt really handle any handshakes, just getting data from all clients, and then spreading it out to all clients as well
	the only thing it should handle is connecting each client to their own ID, and not sending them their own data
"""

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

const TARGET = {
	EVERYONE = "e"
}

const dchead = {
	"s" : -1
}

var mySocket : PacketPeerUDP

var SERVER_IP : String #IP of the server
var SERVER_PORT : int #listening port of the server
var DEF_CLIENT_PORT : int
var clientInfo = {} #holds clientNum : {stuffObject}
var clientNums = [] #holds client nums for looping
var MAX_PLAYERS = 4 #This is just the default value that IS NOT THE FINAL SAY

var lastpacket


const INITIAL_CLIENT_PORT = 46921

var disconnectTime : float = 3.0
const TICK_RATE = 1.0/16.0
var counter = 0

"""
clientNum : {
	clientPort : PORT,
	clientIP : IP,
	username : NAME,
	color : COLOR,
	time : TIME SINCE LAST RECEIVED PACKET,
	id : clientNum,
	"alive" : "y",
	"handshake" : reliableUDP
}

"""
#INIT FUNCTIONS#########################################################

func _init(server_port : int, server_ip : String, default_client_port : int, serverSettingsObj) -> void:
	SERVER_IP = server_ip
	SERVER_PORT = server_port
	DEF_CLIENT_PORT = default_client_port
	mySocket = PacketPeerUDP.new()
	mySocket.listen(SERVER_PORT)
	#Throw away any old data that may be sitting around from a previous creation
	while mySocket.get_available_packet_count() > 0:
		var message = mySocket.get_packet()
	MAX_PLAYERS = serverSettingsObj["maxPlayers"]

	pass

#UPDATE LOOPS###########################################################
func _process(delta: float) -> void:
	_get_stuff()
	_update_timers(delta)
	counter += delta
	if counter >= TICK_RATE:
		counter -= TICK_RATE
		_send_stuff()
		pass
	_clean_clients()
	pass

func _update_timers(deltaTime):
	for i in range(clientNums.size()):
		#Add to the time since a packet was last received
		clientInfo[clientNums[i]]["time"] += deltaTime
		if clientInfo[clientNums[i]]["time"] > disconnectTime:
			#Kick the client out. sorry buddy. i think you died :(
			_process_disconnect(clientNums[i])
			
			pass
		pass
	pass

#MESSAGING##############################################################
	
	#GETTING MESSAGES
func _get_stuff() -> void:
	
	while(mySocket.get_available_packet_count() > 0):
		var message = mySocket.get_packet()
		_parse_pkt(message.get_string_from_utf8(), mySocket.get_packet_ip(), mySocket.get_packet_port())
	
	pass
	
	#SENDING MESSAGES
func _low_msg_client_with_header(clientIP : String, clientPort : int, header, bodyArray):
	###LAGGER###
	if Utilities.GetRandomValue(1,0) <= 0.05:
		print("server skipped #" + str(header["s"]))
		return
	###LAGGER###
	
	mySocket.set_dest_address(clientIP, clientPort)
	var myjson = {
		"head" : header,
		"body" : bodyArray
	}
	mySocket.put_packet((JSON.print(myjson)).to_utf8())
	pass

func _handshake_msg(myNum, info, target):
	if target == TARGET.EVERYONE:
		#All of the clients (that aren't the sending client) will get this
		for i in range(clientNums.size()):
			if clientNums[i] != myNum:
				clientInfo[clientNums[i]]["handshake"].push_msg(info)
				pass
			pass
		pass
	else:
		#This is meant for a specific client
		clientInfo[int(target)]["handshake"].push_msg(info)
		pass
	pass

func _send_stuff() -> void:
	for i in range (clientNums.size()):
		var thisHandshake = clientInfo[clientNums[i]]["handshake"]
		#Each client has anything they need in their handshake, so that is the only thing that needs to be called!
		var allPackets = thisHandshake.send_packet()
		if allPackets != null:
			for k in range(allPackets.size()):
				#Send the packet
				var sendIP = clientInfo[clientNums[i]]["clientIP"]
				var sendPort = clientInfo[clientNums[i]]["clientPort"]
				
				#If the message type is a port change, be sure to send that to the default port!
				var thisthing = allPackets[k]["body"]
				for j in range(thisthing.size()):
					if thisthing[j]["mt"] == MSG_TYPE.PORTCHANGE:
						sendPort = DEF_CLIENT_PORT
						pass
					pass
				
				#for send in range(3):
					#Send each message 3 times to help reduce the amount of packets lost
				_low_msg_client_with_header(sendIP, sendPort, allPackets[k]["head"], allPackets[k]["body"])
					#pass
				pass
			pass
		pass
		
	pass

#PROCESSING DATA - IN ORDER#############################################

func _parse_pkt(info : String, clientIP, clientPort) -> void:
	#Do stuff to the collected info
	#current info will be a string of info, in the format of: MSG_TYPE,message
	
	#Save the string as a JSON object
	lastpacket = parse_json(info)
	
	#Have the client receive the packet if they exist. If they don't this will be done later.
	var thisClient = get_client_by_connection(clientIP, clientPort)
	if thisClient != null:
		clientInfo[thisClient]["handshake"].receive_packet(lastpacket)
		pass
	
	var header = lastpacket["head"]
	var msgarr = lastpacket["body"]
	
	for i in msgarr.size():
		_process_body(msgarr[i], header, clientIP, clientPort)
		pass
	pass

func _process_body(info, header, ip : String, port : int):
	var myData = info["data"]
	
	if info["mt"] == MSG_TYPE.ADDME && get_client_by_connection(ip, port) == null:
		
		#Check if there is room in the lobby
		if _playercount() < MAX_PLAYERS:
			#Do a few things to add the person then bail
			_process_addme(myData, header, ip, port)
			return
		else:
			#If the server is full, let them know
			var rejection_letter = "Hold this L bozo. Blocked + ratio + you fell off + yb better + too sus + server is full"
			#_lowlevel_message_client(ip, port, rejection_letter, MSG_TYPE.DECLINED)
			_low_msg_client_with_header(ip, port, dchead, _make_msg(rejection_letter, MSG_TYPE.DECLINED))
			return
		pass

	var clientNum = get_client_by_connection(ip, port)
	if clientNum == null:
		#Tell them to h*ck off
		_remove_unknown_client(ip, port)
		return
	
	#You've gotten a message from them, so reset the timer
	clientInfo[clientNum]["time"] = 0
	
	
	match(info["mt"]):
		MSG_TYPE.MESSAGE:
			_process_msg(myData, clientNum)
			#Send this to everyone else
			_handshake_msg(clientNum, climsg_to_servmsg(info, clientNum), TARGET.EVERYONE)
			pass
		MSG_TYPE.PORTCHANGE:
			_process_portchange(myData, clientNum)
			pass
		MSG_TYPE.UPDATEPOS:
			_process_updatepos(myData, clientNum)
			_handshake_msg(clientNum, climsg_to_servmsg(info, clientNum), TARGET.EVERYONE)
			pass
		MSG_TYPE.DISCONNECT:
			_process_disconnect(clientNum)
			_handshake_msg(clientNum, climsg_to_servmsg(info, clientNum), TARGET.EVERYONE)
			pass
		MSG_TYPE.ADDOTHER:
			_process_addother(myData)
			pass
		MSG_TYPE.BUILDTOWER:
			_process_buildtower(myData, clientNum)
			_handshake_msg(clientNum, info, TARGET.EVERYONE)
			pass
		MSG_TYPE.HEARTBEAT:
			clientInfo[clientNum]["handshake"].push_msg(_make_msg({}, MSG_TYPE.HEARTBEAT))
			pass
		_:
			print("Server received incorrectly formatted packet")
			pass
		
	pass

func _process_msg(info, clientNum):
	#_push_data(clientNum, info["msg"], MSG_TYPE.MESSAGE)
	pass

func _process_portchange(info, clientNum):
	print("\tNo pkt type PORTCHANGE accepted by SERVER right now")
	pass

func _process_updatepos(info, clientNum):
	#_push_data(clientNum, info["msg"], MSG_TYPE.UPDATEPOS)
	pass

func _process_addme(info, header, ip : String, port : int):
	var setClientNum : int = _gen_client_num()

	#This inits if the client hasn't been met before, so add them
	#Also tell the client to use a new port for listening
	clientNums.append(setClientNum)
	var clientHandshake = reliableUDP.new()
	add_child(clientHandshake)
	
	#Init the handshake by sending the last received packet
	clientHandshake.receive_packet(lastpacket)
	
	clientInfo[setClientNum] = {
		"clientPort" : int(port),
		"clientIP" : ip,
		"id" : setClientNum,
		"username" : info["msg"]["name"],
		"color" : info["msg"]["color"],
		"time" : 0,
		"alive" : "y",
		"handshake" : clientHandshake
	}
	print("\tAdded " + clientInfo[setClientNum]["username"] + "#" + str(setClientNum))
	
	_update_client_port(setClientNum)
	
	
	var newguyJson = {
		"name" : info["msg"]["name"],
		"num" : setClientNum,
		"color" : info["msg"]["color"]
	}
	_handshake_msg(setClientNum, _make_msg(newguyJson, MSG_TYPE.ADDOTHER), TARGET.EVERYONE)
	
	for i in range(clientNums.size() - 1):
		var oldmanJson = {
			"num" : clientInfo[clientNums[i]]["id"],
			"name" : clientInfo[clientNums[i]]["username"],
			"color" : clientInfo[clientNums[i]]["color"]
		}
		clientInfo[setClientNum]["handshake"].push_msg(_make_msg(oldmanJson, MSG_TYPE.ADDOTHER))
		pass
	pass

func _process_disconnect(clientNum):
	#Lose all reference to the player
	clientInfo[clientNum]["alive"] = "n"
	pass

func _process_addother(info):
	print("/tAddother does nothing for server rn")
	pass

func _process_buildtower(info, clientNum):
	#_push_data(clientNum, info["msg"], MSG_TYPE.BUILDTOWER)
	pass

#REMOVING PLAYERS AND THEIR DATA########################################

func disband_lobby():
	#Send a message to all clients with a type of KICKED so they know to look elsewhere
	var json = {
		"msg" : "Lobby disbanded."
	}
	for i in range(clientNums.size()):
		var thisclient = clientInfo[clientNums[i]]
		#Probably the only time this is valid
		#_lowlevel_message_client(thisclient["clientIP"], thisclient["clientPort"], json, MSG_TYPE.KICKED)
		_low_msg_client_with_header(thisclient["clientIP"], thisclient["clientPort"], dchead, _make_msg(json, MSG_TYPE.KICKED))
		thisclient["alive"] = "n"
		#_disconnect_client(clientNums[i])
		pass
	
	_clean_clients()
	mySocket.close()
	pass

func _kick_client(clientNum):
	#Tell everyone but the client that they're disconnected. That guy is getting nae nae'd.
	var kickMsg = {
		"msg" : "Removed by host"
	}
	var thisClient = clientInfo[clientNum]
	#_lowlevel_message_client(thisclient["clientIP"], thisclient["clientPort"], kickmsg, MSG_TYPE.KICKED)
	thisClient["handshake"].push_msg(_make_msg(kickMsg, MSG_TYPE.KICKED))
	clientInfo[clientNum]["alive"] = "n"
	#_disconnect_client(clientNum)
	pass

func _remove_unknown_client(ip, port):
	var kickmsg = {
		"msg" : "You're not allowed in here bro"
	}
	#_lowlevel_message_client(ip, port, kickmsg, MSG_TYPE.KICKED)
	_low_msg_client_with_header(ip, port, dchead, _make_msg(kickmsg, MSG_TYPE.KICKED))
	pass

func _clean_clients():
	#Remove all references to a given client. They can still reconnect later, though!
	var clientCheck = clientNums.duplicate(true)
	for i in range(clientCheck.size()):
		if clientInfo[clientCheck[i]]["alive"] == "n":
			clientInfo[clientCheck[i]]["handshake"].queue_free()
			clientNums.remove(i)
			clientInfo.erase(clientCheck[i])
			pass
		pass
	pass

func _exit_tree() -> void:
	
	mySocket.close()
	for i in range (clientNums.size()):
		clientInfo[clientNums[i]]["handshake"].queue_free()
		pass
	pass


#UTILITY FUNCTIONS######################################################
func _make_msg(info, msgtype : String):
	var myInfo = {
		"data" : info,
		"mt" : msgtype
	}
	return myInfo

func climsg_to_servmsg(info, num):
	#Read a client packet and add in their num for when sending to other clients
	var myInfo = {
		"data" : {
			"msg" : info["data"]["msg"],
			"num" : num
		},
		"mt" : info["mt"],
	}
	return myInfo

func _update_client_port(clientNum : int):
	#send packet to client telling it to change the port it listens to in the future
	var thisClient = clientInfo[clientNum]
	var newport = INITIAL_CLIENT_PORT + (_playercount() - 1)

	#_lowlevel_message_client(thisClient["clientIP"], DEF_CLIENT_PORT, str(newport), MSG_TYPE.PORTCHANGE)
	thisClient["handshake"].push_msg(_make_msg(str(newport), MSG_TYPE.PORTCHANGE))
	clientInfo[clientNum]["clientPort"] = newport
	pass

func _gen_client_num():
	#RNG create a number 0-1,000
	var clientNum = int(Utilities.GetRandomValue(0, 1000))
	#Make sure that number doesn't already exist in client_nums
	while clientNums.has(clientNum):
		#Gen another number
		clientNum = int(Utilities.GetRandomValue(0, 1000))
		print("There was a number collision while adding this client, nothing broke but kinda cool tbh")
		pass
	
	#Add it to the person! :-)
	return clientNum

func get_client_by_connection(ip : String, port : int):
	#Search through the dictionary to find the clientnum by its ip/port combo
	for i in range(clientNums.size()):
		if clientInfo[clientNums[i]]["clientPort"] == port && clientInfo[clientNums[i]]["clientIP"] == ip:
			return clientNums[i]
		pass
	return null

func _playercount() -> int:
	return clientNums.size()

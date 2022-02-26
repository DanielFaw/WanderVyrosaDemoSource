class_name reliableUDP
extends Node

const BUFFER_SIZE : int = 256 #Amount of data stored for anti-lag purposes


var local_seq : int = 0 #Sequence: current packet number, from 0-intmax. Keeps everything synchronized.
var local_ack : int = 0 #Ack: most recently recieved packet number from the other end
var missing_seq = []    #Missing_seq: any messages this end has missed

var local_game_state = [] #Local data that can be requested by the other end. Rolling buffer; data just gets replaced, never resized
var foreign_game_state = [] #Foreign data for local purposes (missing an input, going back to fix it, etc). Rolling buffer
var states_to_send = [] #Data to send down the pipeline for processing; gotten from foreign_game_state
var msg_send_buffer = [] #New data to be sent to the other end. Gets packaged up, saved in local_game_state, and lightbeamed out of your router
var sendex = [] #Old data that got lost in the sauce. Gets packaged up and lightbeamed out of your router

var gotFirstPacket = false #Variable to link up

func _ready():

	#Init the gamestates
	for i in range(BUFFER_SIZE):
		local_game_state.insert(i, ["localdefault" + str(i)])
		foreign_game_state.insert(i, ["foreigndefault" + str(i)])
		pass
	pass

#INPUT: none
#OUTPUT: An array of correctly formatted packets, each with their own head & body for data sync purposes
#USAGE: Call this function and save the output. Loop through each array and send accordingly.
func send_packet():
	
	#If there is nothing in the msg_send_buffer and nothing in the sendex, then there is nothing to send, so bail
	if(msg_send_buffer.size() == 0 && sendex.size() == 0):
		return null
	#Init the message array
	var msgArr = []
	
	#Send the message buffer and an up-to-date header to UDPClient/UDPServer
	if(msg_send_buffer.size() > 0):
		#This only gets updated since there was new info sent
		local_seq += 1
		var index = _index(local_seq)
		local_game_state[index] = msg_send_buffer.duplicate(true)
		msgArr.append(_make_pkt(_generate_pkt_header(local_seq), local_game_state[index]))
		pass

	#Any old info will be sent as well
	for i in range(sendex.size()):
		#Add the old information
		msgArr.append(_make_pkt(_generate_pkt_header(sendex[i]), local_game_state[_index(sendex[i])]))
		pass
	
	#Clear both buffers for next time
	msg_send_buffer.clear()
	sendex.clear()
	
	#Finally, send out the msgObject with all sending data
	return msgArr
	
#INPUT: A head object and a body object (which is an array of messages)
#OUTPUT: A correctly formatted packet
#USAGE: Called from send_packet to make life easier
func _make_pkt(head, body):
	return {"head": head, "body" : body}
	
	
#INPUT: An entire, correctly-formatted networking packet
#OUTPUT: An array of useable data for the client/server to process
#USAGE: Pass in a packet with a body and head, and get back any 
	#current data or old data we've been waiting on that just came in
func receive_packet(full_packet):
	#Clear the array that holds requested data to make sure it's empty
	states_to_send.clear()
	
	#Capture the header from the packet
	var incoming_header = full_packet["head"]
	
	if incoming_header["s"] == -1:
		#This is probably a DC message or something similar, so just break out
		#Anything with a sequence of -1 isn't tracked
		return
	
	#Read in the header
	var foreign_seq : int = incoming_header["s"] #The sequence number the other end is on
	var foreign_ack : int = incoming_header["a"] #The last received information the other end has confirmed gotten
	var foreign_missing_sequences = incoming_header["m"] #The data they have missed from us
	
	#If this end just initialized, set the ack equal to the foreign_seq
	#since we've obviously gotten that data
	if !gotFirstPacket:
		local_ack = foreign_seq
		gotFirstPacket = true
		pass

	#If the seq in the header is less than the seq we've received
	if foreign_seq < local_ack:
		#Check if we have said data
		if missing_seq.has(foreign_seq):
			#Getting here means we missed this packet and have been looking for it
			#Remove it from the "missing packet" array
			missing_seq.erase(foreign_seq)
			#Save the new data in its missing gamestate
			foreign_game_state[_index(foreign_seq)] = full_packet["body"].duplicate(true)
			#Package it up for the client/server to use
			if !states_to_send.has(foreign_seq):
				states_to_send.append(foreign_seq)
			pass
		else:
			#Otherwise, if missing_seq doesn't have foreign_seq, we've already received this data
			#so we do nothing
			pass
	else:
		#Since the sequence in the header is greater than our last acked packet
		#Mark anything between the last gotten packet and this new packet as unreceived
		var missed_packet_count = foreign_seq - local_ack
		#If the missed packet count is 0, we have already gotten this data. If it's 1, that's just the natural order of things
		if missed_packet_count < 2:
			#You received new info in the order expected, don't mark anything as false
			#0 means they just sent the same thing, while 1 means it's next in line
			pass
		else:
			#If we missed more than 1 packet, mark anything between them as unreceived
			for i in range(missed_packet_count - 1):
				#Mark everything from local_ack through foreign_seq as unreceived
				var indexToFalsify = (local_ack + i + 1)
				if !missing_seq.has(indexToFalsify):
					missing_seq.append(indexToFalsify)
				#Also change the data since we overwrite things here and this makes it easier to know something is wrong
				foreign_game_state[_index(indexToFalsify)] = ["missed packet"]
				pass
			pass
		#Now that the missing data stuff has been sorted out, update our current ack and send down the pipeline
		foreign_game_state[_index(foreign_seq)] = full_packet["body"].duplicate(true)
		if !states_to_send.has(foreign_seq):
			states_to_send.append(foreign_seq)
		local_ack = foreign_seq
		pass
		
	#Now, for each packet we're missing
	for i in range(foreign_missing_sequences.size()):
		#Make sure we actually have the data
		if foreign_missing_sequences[i] < (local_seq - (BUFFER_SIZE + 1)):
			#The 1 is added because data gets overwritten when a new message is sent. This is probably too late anyways, though
			print("A handshake is requesting a packet that doesn't exist anymore")
			return
		else:
			#If we do have the data, add it to our send list
			if !sendex.has(foreign_missing_sequences[i]):
				sendex.append(foreign_missing_sequences[i])
			pass
		pass
	
	#Finally, return any new data for the client/server to process
	return _get_foreign_game_states()

#INPUT: A message to send
#OUTPUT: none
#USAGE: Called from the client or server to add data to the send buffer
func push_msg(info):
	msg_send_buffer.append(info)
	pass
#INPUT: A sequence number
#OUTPUT: A correctly formatted packet header
#USAGE: Makes life easier for sending data to the client/server for processing
func _generate_pkt_header(seq):
	#Create an object with the most up-to-date info and return it
	var header = {
		"s" : seq, #Sequence
		"a" : local_ack,  #Ack
		"m" : missing_seq  #Missing sequences
	}
	return header

#INPUT: A sequence number
#OUTPUT: The index the data would be at
#USAGE: Used anywhere that accesses an array containing information, so no array needs to be recreated
func _index(seq : int):
	#Returns the sequence % buffer
	return seq % BUFFER_SIZE

#INPUT: none
#OUTPUT: Array of data for the client/server to use
#USAGE: Called from receive_packet, this is just a helper function to keep code a little cleaner.
	#all it does is return the values at the given foreign_game_state's index
func _get_foreign_game_states():
	var myStates = []
	for i in range(states_to_send.size()):
		myStates.append(foreign_game_state[_index(states_to_send[i])])
		pass
	return myStates

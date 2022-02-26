extends Node
class_name UDPInterpreter
#UDPInterpreter contains all of the code for turning user data into sendable strings, or vise-versa

"""
todo:
	this class should transform any data into commands that get sent to the client/server
	and vise-versa, so real data gets put through UDPInterp, and returns data formatted for packets
	
"""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	


func pkt_to_msgarr(info):
	
	#Split the packet into an array of messages and return that
	pass

func msgarr_to_pkt(info, header):
	#Take in an array of messages and a header from UDPHandshake and send it to the client/server for correct use
	
	pass	

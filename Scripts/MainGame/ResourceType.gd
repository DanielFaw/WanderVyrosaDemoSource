extends Node
enum TYPE {Metal,Quartz,Silicon,BoomStone,Random}


func IndexToString(var enumIndex:int) ->String:

	match(enumIndex):
		0:
			return "Metal"
			pass
		1:
			return "Quartz"
			pass
		2:
			return "Silicon"
			pass
		3:
			return "BoomStone"
			pass
		4:
			return "BoomStone"
			pass
			
	return ""

	pass

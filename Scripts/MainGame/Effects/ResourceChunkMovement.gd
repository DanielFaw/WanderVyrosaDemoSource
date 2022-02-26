extends Spatial

var basePos;

var travelVec;

export var movementSpeed = 2.0
func _ready():
	basePos =  SceneResources.GetResource("PlayerBase").global_transform.origin
	pass


func CalculateTargetVec():
	travelVec = (basePos - global_transform.origin).normalized()

func _process(delta: float):
	
	var distToTarget = global_transform.origin.distance_to(basePos)
	if(distToTarget > 2.0):
		global_transform.origin += travelVec * movementSpeed * delta
	else:
		self.queue_free()

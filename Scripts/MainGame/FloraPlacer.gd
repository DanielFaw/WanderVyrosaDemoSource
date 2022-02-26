extends Spatial

export(Array,PackedScene) var trees;
export(Array,PackedScene) var rocks;

export var max_flora = 25
export var horizontal_path_finding_resolution:int = 20;
export var vertical_path_finding_resolution:int = 15;
var flora_generation_thread = Thread.new();

var vertical_no_place;
var horizontal_no_place;

func _ready():
	# Calculate the deltas the node generation uses
	#		to avoid placing flora there
	vertical_no_place = PI/ float(vertical_path_finding_resolution);
	horizontal_no_place =  (2.0 * PI) / float(horizontal_path_finding_resolution)
	flora_generation_thread.start(self,"GenerateFlora")
	pass


func GenerateFlora(var _null_arg):
	for _i in range(max_flora):

		var theta = Utilities.GetRandomValue(float(PI) - 0.5,0.5);
		var phi = Utilities.GetRandomValue(2.0 * float(PI),0);

		if(fmod(theta,vertical_no_place) == 0):
			theta += vertical_no_place / 2.0
			pass

		if(fmod(phi, horizontal_no_place) == 0):
			phi += horizontal_no_place / 2.0
			pass


		var rand = Utilities.GetRandomValue(1.0,0.0)
		var newLocation = Utilities.SphericalCoordToCartesian(18.8,theta,phi)

		# Place a new decoration next idle frame
		if(rand > 0.5):
			call_deferred("PlaceTree",newLocation);
		else:
			if(rocks.size() > 0):
				call_deferred("PlaceRock",newLocation);

		#yield(get_tree().create_timer(0.001),"timeout")
		pass;

	print("Flora placed")
	return
	pass

func PlaceTree(var new_origin):

	var rand = round(Utilities.GetRandomValue(trees.size()-1,0))
	var new_tree = trees[rand].instance();
	get_tree().get_current_scene().add_child(new_tree)

	new_tree.global_transform.origin = new_origin;
	new_tree.global_transform = Utilities.AlignWithNormal(new_tree.global_transform, Utilities.CalculateGravityDirection(new_origin))
	pass


func PlaceRock(var new_origin):
	var rand = round(Utilities.GetRandomValue(rocks.size()-1,0))
	var new_rock = rocks[rand].instance();
	get_tree().get_current_scene().add_child(new_rock)

	new_rock.global_transform.origin = new_origin;
	new_rock.global_transform = Utilities.AlignWithNormal(new_rock.global_transform, Utilities.CalculateGravityDirection(new_origin))
	pass
	

func _exit_tree():
	flora_generation_thread.wait_to_finish()
	pass

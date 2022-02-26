extends KinematicBody

var currentVel = Vector3.ZERO
var gravityStrength = -9.8
var timeSinceFired = 0.0
var deletionTime = 3.0
var damageLayers = []

var damageAmount


var planet
# Set inital values
func SetValues(var travelDirectionInit,var layersToDamage,amountOfDamage):
	currentVel = travelDirectionInit * 10.0
	self.damageLayers = layersToDamage
	self.damageAmount = amountOfDamage
	#print(currentVel)
	planet = SceneResources.GetResource("Planet").global_transform.origin
	pass


	
func _physics_process(delta):

	# Look towards velocity
	# Do some physics stuff idk I'm tired
	#var localUp = -Utilities.CalculateGravityDirection(global_transform.origin);

	
	var localUp = planet- global_transform.origin
	
	if(transform.basis.z.normalized().dot(currentVel.normalized()) != 0 && (global_transform.origin - currentVel).normalized() != Vector3.UP):
		look_at(global_transform.origin + currentVel.normalized(),localUp.normalized())

	# Apply Gravity
	#currentVel += gravityStrength * delta * localUp.normalized()

	currentVel = move_and_slide(currentVel,Vector3.UP)

	timeSinceFired += delta

	#TODO - Probably add pooling of some sort
	if(get_slide_count() > 0 || timeSinceFired > deletionTime):
		if(get_slide_count() > 0):

			# Is the collided object on a layer this projectile can damage?
			if(damageLayers.has(get_slide_collision(0).collider.collision_layer)):

				# Check if the collided object can take damage
				if(get_slide_collision(0).collider.has_method("TakeDamage")):
					#print(get_slide_collision(0).collider.name)
					get_slide_collision(0).collider.TakeDamage(damageAmount);
					pass;

				# If not, check its owner
				elif(get_slide_collision(0).collider.get_owner() != null):
					if(get_slide_collision(0).collider.get_owner().has_method("TakeDamage")):
						#print(get_slide_collision(0).collider.get_owner().name)
						get_slide_collision(0).collider.get_owner().TakeDamage(damageAmount);

				pass;
		self.queue_free()
	pass

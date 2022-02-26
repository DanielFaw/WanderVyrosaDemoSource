extends "res://Scripts/MainGame/Enemies/EnemyBase.gd"

export var animatorPath:NodePath;
var animTree;

export var firingPointPath:NodePath;

export var projectilePrefab:PackedScene;

var _firingPoint;

var bullet_damage

func _ready():
	._ready()
	animTree = get_node(animatorPath)
	_firingPoint = get_node(firingPointPath);
	pass

func _Attack():
	animTree["parameters/playback"].travel("A_AttackFire")

	# Create and add new projectile
	var newBullet = projectilePrefab.instance()
	get_tree().get_current_scene().add_child(newBullet)

	newBullet.global_transform.origin = _firingPoint.global_transform.origin

	# Add vertical offset
	var targetPoint =  _firingPoint.global_transform.origin - (Utilities.CalculateGravityDirection( _firingPoint.global_transform.origin) * 0.5)
	var projectileVel = (currentTargetTower.global_transform.origin - targetPoint).normalized()

	# Set values of the projectile
	newBullet.SetValues(projectileVel,[4,516],bullet_damage)

	#TODO - Fire missle
	._Attack()

	pass

func SetStats(var params):
	maxHealth = params["hp"]
	currentHealth = maxHealth
	attackCooldown = params["atkspd"]
	chargeTime = params["atkspd"]
	bullet_damage = params["dmg"]
	moveSpeed = params["spd"]
	
	pass
func GetStats():
	var params = {}
	params["hp"] = maxHealth
	params["atkspd"] = attackCooldown
	params["dmg"] = bullet_damage
	params["spd"] = moveSpeed
	
	return params
	pass



func _EndAttackCoolDown():
	._EndAttackCoolDown()
	pass

func _OnBodyEnter(var body):
	._OnBodyEnter(body)
	pass;

func TakeDamage(var damageToTake, var params = {}):
	.TakeDamage(damageToTake, params)

func _OnBodyExit(var body):
	._OnBodyExit(body)
	pass;

func _SelectNewTarget():
	._SelectNewTarget()
	pass

# Move towards the targeted tower
func _MoveToTower():
	._MoveToTower()
	pass;

# If there is no active tower we're attacking, move towards the base
func _WanderState(var localUp):
	._WanderState(localUp)
	pass
	
func SetSpawnID(var newId:int):
	.SetSpawnID(newId)
	pass

func _physics_process(delta):
	# Main "state machine"
	match(currentEnemyState):
		enemyState.WANDERING:
			animTree.set("parameters/Default/B_Walk_Run/blend_amount",1.0);
			animTree.set("parameters/conditions/atTarget",false);
			animTree.set("parameters/conditions/newTargetSelected",true);
			pass;
		enemyState.ENEMY_FOUND:
			animTree.set("parameters/Default/B_Walk_Run/blend_amount",1.0);
			animTree.set("parameters/conditions/atTarget",false);
			animTree.set("parameters/conditions/newTargetSelected",true);
			pass;
		enemyState.ATTACKING:
			animTree.set("parameters/conditions/atTarget",true);
			animTree.set("parameters/Default/B_Walk_Run/blend_amount",0);
			animTree.set("parameters/conditions/newTargetSelected",false);
			pass;

	._physics_process(delta)
	pass
	
func _exit_tree():
	._exit_tree()

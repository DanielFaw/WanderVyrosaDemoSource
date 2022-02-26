extends Spatial


var _maxHealth:float = 100
var _currentHealth:float
var is_alive = true

signal baseTookDamage(newHealthPercent);


func _init():
	SceneResources.RegisterResource("PlayerBase",self)
	pass

func _ready():
	_currentHealth = _maxHealth
	emit_signal("baseTookDamage",float(_currentHealth)/float(_maxHealth))

func TakeDamage(var amount:float):
	if !is_alive:
		#This just makes sure nothing weird is happening
		return
	_currentHealth -= amount
	emit_signal("baseTookDamage",float(_currentHealth)/float(_maxHealth))
	#print("base took damage!")

	if(_currentHealth <= 0 ):
		is_alive =false
		_OnDeath()

func _OnDeath():
	SceneResources.GetResource("GameStateManager").GameOver(false);
	#print("GAME OVER!!!!!!!!!!")
	pass

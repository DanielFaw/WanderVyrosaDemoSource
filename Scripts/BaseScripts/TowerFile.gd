extends Resource

enum TOWER_TYPE {BEAM,RIFLE,PROJECTILE,DEFENSE,RESOURCE}

# The time (in seconds) between attacks
export var attackCooldown:float = 0;

# The ID of this tower
export var towerID:int = -1

# The type of this tower
export(TOWER_TYPE) var towerType = TOWER_TYPE.DEFENSE

# The resource path for this tower's prefab
export var prefabPath:String = ""

# The attack radius of this tower
export var attackRadius:float = 0



func _ready():
	pass

extends Node

const ATTACKSPEED = 1 #Fire rate of towers
const DAMAGE = 2 #Damage per shot of towers
const HP = 3 #Health of towers
const BUILDTIME = 4 #Build time for towers
const WINDTIME = 5 #How long it takes the Gatling to begin shooting
const COOLDOWN = 6 #Cooldown for Gatling after shooting
const SHOOTTIME = 7 #Time Gatling can constantly shoot
const EXPLOSIONRADIUS = 8 #Explosion radius
const DRILLSPEED = 9 #Drill mining speed (how fast)
const DRILLEFF = 10 #Drill efficiency (how much)
const STARTRESOURCES = 11 #Starting amount of resources
const BULLETSPREAD = 12 #How much bullets spread

const NAPALM_ENABLED = 13 #Toggles fire effect
const STUN_ENABLED = 14 #Toggles stun effect
const FIREDAMAGE = 15 #Damage per tick of fire
const FIRETICKAMOUNT = 16 #Amount of ticks for fire
const TIMEBETWEENTICKS = 17 #Time between damage ticks for fire
const STUNDURATION = 18 #Time enemies are stunned
const BUCKETSIZE = 19 #Amount of resources drills hold before releasing
const DRONECOUNT = 20 #Amount of drones to build towers
const DRONESPEED = 21 #Speed of drones 

func get_all_stats() -> Array:
	var stat_list = [
	ATTACKSPEED,
	DAMAGE,
	HP,
	BUILDTIME,
	WINDTIME,
	COOLDOWN,
	SHOOTTIME,
	BULLETSPREAD,
	EXPLOSIONRADIUS,
	NAPALM_ENABLED,
	FIREDAMAGE,
	FIRETICKAMOUNT,
	TIMEBETWEENTICKS,
	STUN_ENABLED,
	STUNDURATION,
	DRILLSPEED,
	DRILLEFF,
	BUCKETSIZE,
	STARTRESOURCES,
	DRONECOUNT,
	DRONESPEED]
	return stat_list
	pass



func str_to_enum(var s):
	#Converts a string to a TS.TYPE
	match(s):
		"ATTACKSPEED", "ATKSPD":
			return ATTACKSPEED
		"DAMAGE", "DMG":
			return DAMAGE
		"HP":
			return HP
		"BUILDTIME", "BLDTIME":
			return BUILDTIME
		"WINDTIME", "WNDTIME":
			return WINDTIME
		"COOLDOWN":
			return COOLDOWN
		"SHOOTTIME":
			return SHOOTTIME
		"EXPLOSIONRADIUS", "EXPLR":
			return EXPLOSIONRADIUS
		"DRILLSPEED", "DRLSPD":
			return DRILLSPEED
		"DRILLEFF", "DRLEFF":
			return DRILLEFF
		"STARTRESOURCES", "STARTR":
			return STARTRESOURCES
		"BULLETSPREAD", "BLTSPRD":
			return BULLETSPREAD
		"NAPALM_ENABLED":
			return NAPALM_ENABLED
		"STUN_ENABLED":
			return STUN_ENABLED
		"FIREDAMAGE", "FIREDMG":
			return FIREDAMAGE
		"FIRETICKAMOUNT", "FIRETICKAMNT":
			return FIRETICKAMOUNT
		"TIMEBETWEENTICKS", "TBT":
			return TIMEBETWEENTICKS
		"STUNDURATION":
			return STUNDURATION
		"BUCKETSIZE", "BKTSIZE":
			return BUCKETSIZE
		"DRONECOUNT":
			return DRONECOUNT
		"DRONESPEED", "DRONESPD":
			return DRONESPEED
		
	pass

func enum_to_str(var e):
	#Converts a TS.TYPE to a string
	match(e):
		ATTACKSPEED:
			return "Attack Speed"
		DAMAGE:
			return "Damage"
		HP:
			return "Health"
		BUILDTIME:
			return "Build Time"
		WINDTIME:
			return "Windup Time"
		COOLDOWN:
			return "Cooldown Time"
		SHOOTTIME:
			return "Constant Fire Time"
		EXPLOSIONRADIUS:
			return "Explosion Radius"
		DRILLSPEED:
			return "Mining Speed"
		DRILLEFF:
			return "Mining Efficiency"
		STARTRESOURCES:
			return "Starting Resources"
		BULLETSPREAD:
			return "Bullet Spread"
		STUN_ENABLED: 
			return "Stunning Shells"
		NAPALM_ENABLED:
			return "Napalm Shells"
		FIREDAMAGE:
			return "Fire Damage"
		FIRETICKAMOUNT:
			return "Fire Damage Amount"
		TIMEBETWEENTICKS:
			return "Fire Damage Time"
		STUNDURATION:
			return "Stun Duration"
		BUCKETSIZE:
			return "Bucket Size"
		DRONECOUNT:
			return "Drone Amount"
		DRONESPEED:
			return "Drone Speed"

	pass


func get_unlocker_description(var d):
	match(d):
		NAPALM_ENABLED:
			return "Shells set enemies ablaze"
			pass
		STUN_ENABLED:
			return "Shells temporarily stun enemies"
			pass
		_:
			return "Error parsing unlocker description"
	pass


#If the variable gets better as it increases, returns true
#else returns false
func better_plus(var d):
	match(d):
		DAMAGE, HP, SHOOTTIME, EXPLOSIONRADIUS, DRILLEFF, STARTRESOURCES, FIREDAMAGE, FIRETICKAMOUNT, BUCKETSIZE, STUNDURATION, DRONECOUNT, DRONESPEED:
			return true
	#Anything not in the above is assumed to get better on decrease
	return false

func mechanic_unlocker(var d):
	#If the variable is a mechanic unlocker (aka a bool), returns true
	match(d):
		NAPALM_ENABLED, STUN_ENABLED:
			return true
	return false
	

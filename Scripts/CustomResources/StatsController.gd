class_name BaseTowerUpgradeResource
extends Resource

#All stat controllers will inherit from this and only take values they need in their GetAllStats() calls

#signal upgrade_added



export var has_been_set = false
export var stat_list : Array

export var my_stats : Dictionary


func initialize_upgrades() -> void:
	if true:
		stat_list = TStat.get_all_stats()
		my_stats = {}
		GenerateStatList()
		SetBaseStats()
		has_been_set = true
		pass
	pass

func GetAllStats():
	#Return the dictionary
	var temp_dict = {
		
	}
	#print("statlist size: " + str(stat_list.size()))
	if(stat_list.size() == 0):
		print("You're trying to get stats from an empty object!")
		print("Setting stats back to default")
		#stat_list = TStat.get_all_stats()
		initialize_upgrades()
		pass
	for i in range(stat_list.size()):
		temp_dict[stat_list[i]] = AccessStats(stat_list[i], "gettotal")
		pass
	return temp_dict
	pass

func ResetUpgrades():
	for i in stat_list:
		AccessStats(i, "setupgrade", 0)
		pass
	pass

func GenerateStatList():
	for i in stat_list:
		my_stats[i] = {
			"basevalue" : 0,
			"upgradevalue" : 0
		}
	has_been_set = false
	pass

func AccessStats(var upgrade, var command, var value = 0):
	var mod : Dictionary = my_stats[upgrade]
	match(command):
		"addupgrade":
			if(mod.has("upgradevalue")):
				mod["upgradevalue"] += value
			else:
				mod["upgradevalue"] = value
			pass
		"setupgrade":
			mod["upgradevalue"] = value
			pass
		"getupgrade":
			if(mod.has("upgradevalue")):
				return mod["upgradevalue"]
			else:
				print("no upgrade value found, setting to 0")
				mod["upgradevalue"] = 0
				return mod["upgradevalue"]
			pass
		"setbase":
			mod["basevalue"] = value
			pass
		"getbase":
			return mod["basevalue"]
			pass
		"gettotal":
			if(!mod.has("basevalue") || !mod.has("upgradevalue")):
				if(!mod.has("basevalue") && !mod.has("upgradevalue")):
					#Both are null
					print(str(upgrade) + " is null in StatController")
					return 0
					pass
				elif(!mod.has("basevalue")):
					#Only basevalue is null (how lol)
					print(str(upgrade) + " basevalue is null in StatController")
					return mod["upgradevalue"]
					pass
				else:
					#Only upgradevalue is null
					print(str(upgrade) + "upgradevalue is null in StatController")
					return mod["basevalue"]
					pass
				
				pass
			return mod["basevalue"] + mod["upgradevalue"]

			pass
	pass


func SetBaseStats():
	#Get every base value into an array and call AccessStats.setbase on them
	
	#############################This should mirror the get_all_stats function in TStat!!!!!!!!!!!!!!!!!!!
	var base_stat_list = [
		base_attack_speed,
		base_damage,
		base_health,
		base_build_time,
		base_windup_time,
		base_cooldown_time,
		base_shoot_time,
		base_bullet_spread,
		base_explosion_radius,
		base_napalm_enabled,
		base_fire_damage,
		base_fire_tick_amount,
		base_time_between_fire_ticks,
		base_stun_enabled,
		base_stun_duration,
		base_drill_speed,
		base_drill_efficiency,
		base_drill_bucket_size,
		base_starting_resources,
		base_drone_count,
		base_drone_speed
	]
	for i in range(base_stat_list.size()):
		AccessStats(stat_list[i], "setbase", base_stat_list[i])
		pass
	pass


#All towers
export var base_attack_speed : float
export var base_damage : float
export var base_health : float
export var base_build_time : float

#Gatling
export var base_windup_time : float
export var base_cooldown_time : float
export var base_shoot_time : float
export var base_bullet_spread : float

#Mortar
export var base_explosion_radius : float
export var base_napalm_enabled : int
export var base_fire_damage : float
export var base_fire_tick_amount : int
export var base_time_between_fire_ticks : float
export var base_stun_enabled : int
export var base_stun_duration : float

#Drill
export var base_drill_speed : float
export var base_drill_efficiency : float
export var base_drill_bucket_size : float

#Fuel ship
export var base_starting_resources : int
export var base_drone_count: int
export var base_drone_speed : float




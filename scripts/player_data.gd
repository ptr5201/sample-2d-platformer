extends Node


# Player state variables
var score: int = 0
var lives: int = 3


# Upgrades/collectibles storage - structure: { "upgrade_name": {"active": bool, "level": int} }
var upgrades: Dictionary = {}


# Signals for state changes
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal upgrade_activated(upgrade_name: String)


func _ready() -> void:
	# Singleton initialization
	pass


#################
# SCORE MANAGEMENT
#################
func add_score(amount: int = 1) -> void:
	score += amount
	score_changed.emit(score)


func reset_score() -> void:
	score = 0
	score_changed.emit(score)


#################
# LIVES MANAGEMENT
#################
func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)


func reset_lives() -> void:
	lives = 3
	lives_changed.emit(lives)


#################
# PLAYER STATE MANAGEMENT
#################
func reset_player_state() -> void:
	"""Reset player state when starting a new game or level"""
	reset_score()
	reset_lives()


#################
# UPGRADE/COLLECTIBLE MANAGEMENT
#################
func has_upgrade(upgrade_name: String) -> bool:
	"""Check if an upgrade is active"""
	if upgrade_name not in upgrades:
		return false
	return upgrades[upgrade_name].get("active", false)


func add_upgrade(upgrade_name: String, level: int = 1) -> void:
	"""Activate an upgrade with optional level tracking"""
	if upgrade_name not in upgrades:
		upgrades[upgrade_name] = {"active": true, "level": level}
	else:
		upgrades[upgrade_name]["active"] = true
		upgrades[upgrade_name]["level"] = level
	upgrade_activated.emit(upgrade_name)


func remove_upgrade(upgrade_name: String) -> void:
	"""Deactivate an upgrade"""
	if upgrade_name in upgrades:
		upgrades[upgrade_name]["active"] = false


func get_upgrade_level(upgrade_name: String) -> int:
	"""Get the level of an upgrade, or 0 if not active"""
	if not has_upgrade(upgrade_name):
		return 0
	return upgrades[upgrade_name].get("level", 1)

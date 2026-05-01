extends Node2D
@onready var score_label: Label = $HUD/ScorePanel/ScoreLabel
@onready var fade: ColorRect = $HUD/fade

@export var debug_start_level: int = -1
static var has_started_once: bool = false

var level: int = 1
var score: int = 0
var current_level_root: Node = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# setup the level
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	if not has_started_once and debug_start_level != -1:
		level = debug_start_level
		has_started_once = true
	else:
		level = 1
	await _load_level(level, true, false)


##################
# LEVEL MANAGEMENT
##################
func _load_level(level_number: int, first_load: bool, reset_score: bool) -> void:
	# Block mouse clicks, then fade out to black
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	if not first_load:
		await _fade(1.0)

	if reset_score:
		score = 0
		score_label.text = "SCORE: 0"

	if current_level_root:
		current_level_root.queue_free()

	# Change level
	var level_path = "res://scenes/levels/level%s.tscn" % level_number
	if not FileAccess.file_exists(level_path):
		level_path = "res://scenes/victory.tscn"
		current_level_root = load(level_path).instantiate()
		current_level_root.name = "victory_node"
		add_child(current_level_root)
	else:
		current_level_root = load(level_path).instantiate()
		current_level_root.name = "LevelRoot"
		add_child(current_level_root)
		_setup_level(current_level_root)

	# Fade in to clear, then allow mouse clicks
	await _fade(0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_level(level_root: Node) -> void:
	# connect exit
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)
	
	# connect apples
	var apples = level_root.get_node_or_null("Apples")
	if apples:
		for apple in apples.get_children():
			apple.collected.connect(increase_score)

	# connect enemies
	var enemies = level_root.get_node_or_null("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			enemy.player_died.connect(_on_player_died)

	# connect hazards
	var hazards = level_root.get_node_or_null("Hazards")
	if hazards:
		for hazard in hazards.get_children():
			hazard.player_died.connect(_on_player_died)


#################
# SIGNAL HANDLERS
#################
func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		level += 1
		body.can_move = false
		await _load_level(level, false, false)


func _on_player_died(body) -> void:
	body.die()
	await _load_level(level, false, true)


#################
# SCORE
#################
func increase_score() -> void:
	score += 1
	score_label.text = "Score: %s" % score


func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.5)
	await tween.finished

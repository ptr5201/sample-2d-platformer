extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var rectangle_collider: CollisionShape2D = $CollisionShape2D
@onready var circle_collider: CollisionShape2D = $CollisionShape2D2


signal player_died
const SPEED = 50.0
var wall_check_distance = 5.0
var ledge_check_distance = 5.0
var direction = -1.0
var is_moving = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	wall_check.enabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_moving:
		wall_check.target_position.x = wall_check_distance * direction
		ledge_check.target_position.x = ledge_check_distance * direction

		if wall_check.is_colliding():
			turn_around()
			return # Exit function to apply new direction immediately

		if not ledge_check.is_colliding():
			turn_around()
			return

		position.x += direction * SPEED * delta


func turn_around() -> void:
	direction *= -1.0
	wall_check.position.x *= -1.0
	ledge_check.position.x *= -1.0
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
	rectangle_collider.position.x *= -1.0
	circle_collider.position.x *= -1.0


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		emit_signal("player_died", body)

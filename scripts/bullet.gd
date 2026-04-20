extends Area2D

@export var speed: float = 800.0
@export var damage: int = 1

var direction : int = 1 # 1 for right, -1 for left

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Move in a straight line based on the direction set by the player
	position.x += speed * direction * delta

# The "Self-Destruct" logic
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Deletes the bullet once it leaves the player's view
	queue_free()


# The "Impact" logic for areas, etc.
func _on_area_entered(area: Area2D) -> void:
	# Check if the thing we hit has a function to take damage
	if area.has_method("take_damage"):
		area.take_damage(damage)

	# Delete the bullet after it hits an enemy
	queue_free()

# The "Impact" logic for world objects
func _on_body_entered(_body: Node2D) -> void:
	# Delete the bullet after it hits a world object (e.g., a wall)
	queue_free()

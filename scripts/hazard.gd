extends Area2D

signal player_died

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
			emit_signal("player_died", body)

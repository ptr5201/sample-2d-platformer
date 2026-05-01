extends Node2D
@onready var play_again_button: Button = $play_again_button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_button_pressed)


func _on_play_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

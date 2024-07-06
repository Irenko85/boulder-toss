extends Node3D

@onready var player_2: Player = $Player2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await Transitions.hide_fade()
	player_2.lock_player()
	player_2.sensitivity = 0

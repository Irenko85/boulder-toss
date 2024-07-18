extends Node3D

@onready var player_2: Player = $Player2
@onready var rogue_hooded = $Rogue_Hooded

@onready var cactus: Node3D = $World/cactus

@export var cactus1_scene: PackedScene
@export var cactus2_scene: PackedScene
const CACTUS_INSTANCES: int = 75

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rogue_hooded.tutorial = true
	player_2.tutorial = true
	player_2.lock_player()
	player_2.sensitivity = 0
	# Spawn cactus in random positions
	for i in range(CACTUS_INSTANCES):
		var rand_x = randf_range(-50, 50)
		var rand_z = randf_range(-50, 50)
		var random_position = Vector3(rand_x, 0, rand_z)
		var random_rotation = randf_range(-180, 180)
		var random_scale = randf_range(0.1, 0.25)
		var cactus_instance = [cactus1_scene, cactus2_scene].pick_random().instantiate()
		cactus.add_child(cactus_instance)
		cactus_instance.global_position = random_position
		cactus_instance.global_rotation.y = random_rotation
		cactus_instance.scale = Vector3(random_scale, random_scale, random_scale)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://game/lobby.tscn")
	

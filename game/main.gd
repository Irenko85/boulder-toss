extends Node3D

@export var player_scene: PackedScene
@onready var players: Node3D = $Players
@onready var ground: MeshInstance3D = $Ground

@onready var player_a: Marker3D = $Spawn/PlayerA
@onready var player_b: Marker3D = $Spawn/PlayerB
@onready var cactus: Node3D = $World/cactus

@export var cactus1_scene: PackedScene
@export var cactus2_scene: PackedScene
const CACTUS_INSTANCES: int = 75

func  _ready() -> void:
	# Same seed for both players
	seed("Irenko".hash())
	Game.players.sort_custom(func(a, b): return a.id < b.id)
	for player_data in Game.players:
		var player = player_scene.instantiate()
		players.add_child(player)
		player.setup(player_data)

		if len(players.get_children()) == 1:
			player.global_position = player_a.global_position

		if len(players.get_children()) == 2:
			player.rig.global_rotation.y += PI
			player.global_position = player_b.global_position
	
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

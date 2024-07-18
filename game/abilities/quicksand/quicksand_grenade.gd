extends RigidBody3D

@export var quicksand: PackedScene
@onready var explosion_timer: Timer = $ExplosionTimer
@onready var explosion_sfx: AudioStreamPlayer3D = $Explosion
var valid = true


func _on_body_entered(body: Node) -> void:
	if body is StaticBody3D and valid:
		explosion_timer.start()
		valid = false


func _on_explosion_timer_timeout() -> void:
	spawn_quicksand()


func spawn_quicksand() -> void:
	explosion_sfx.play()
	var quicksand_instance = quicksand.instantiate()
	add_sibling(quicksand_instance)
	quicksand_instance.global_position.x = global_position.x
	quicksand_instance.global_position.z = global_position.z
	
	# TODO: Another way to do this?
	quicksand_instance.global_rotation.y += PI/2
	quicksand_instance.appear()
	visible = false
	await get_tree().create_timer(1).timeout
	queue_free()

extends Node3D

var direction: Vector3
const SPEED: float = 20.0
const ROTATION_SPEED: float = 5.0
const DAMAGE: float = 25.0
var valid = true

@export var projectile_particles: PackedScene

@onready var break_sfx: AudioStreamPlayer3D = $Break
@onready var hola: AudioStreamPlayer3D = $hola


func _process(delta) -> void:
	global_position += delta * direction * SPEED
	rotation.x += delta * ROTATION_SPEED
	rotation.z += delta * ROTATION_SPEED / 2


func _on_timer_timeout() -> void:
	add_particles()
	queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not valid:
		return
	if body is Player:
		body.take_damage(DAMAGE)
	valid = false
	break_sfx.play()
	add_particles()
	visible = false
	await get_tree().create_timer(1).timeout
	queue_free()


func add_particles() -> void:
	var particles_instance = projectile_particles.instantiate() as GPUParticles3D
	add_sibling(particles_instance)
	particles_instance.global_position = global_position
	particles_instance.emitting = true

extends CharacterBody3D
class_name Player

@export var speed: float = 5.0
@export var jump_velocity: float = 10.0
@export var LERP_VALUE: float = 0.15
@export var acceleration: float = 4.0
@export var sensitivity: float = 0.3
@export var player_health: float = 100.0
@export var grenade_throw_force: float = 15.0

@export_category("Abilities")
@export var player_shield: PackedScene
@export var projectile: PackedScene
@export var quicksand_grenade: PackedScene

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var jumping: bool = false
var can_move: bool = true
var was_on_floor: bool = true
var can_jump: bool = true
var can_throw_grenade: bool = true
var is_dancing: bool = false
var dashing: bool = false

@onready var spring_arm_pivot: Node3D = $Rig/SpringArmPivot
@onready var spring_arm_3d: SpringArm3D = $Rig/SpringArmPivot/SpringArm3D
@onready var rig: Node3D = $Rig
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var camera_3d: Camera3D = $Rig/SpringArmPivot/SpringArm3D/Camera3D
@onready var shield_spawner: Node3D = %ShieldSpawner
@onready var projectile_spawner: Node3D = %ProjectileSpawner

#HUD
@onready var hud: Control = %HUD
@onready var hud_projectile_charges = $HUD/Cooldowns/Projectile/Charges
@onready var hud_shield_charges = $HUD/Cooldowns/Shield/Charges
@onready var hud_quicksand_charges = $HUD/Cooldowns/Quicksand/Charges
@onready var hud_cooldowns_charges = $HUD/Cooldowns/Dash/Charges
@onready var hud_projectile_timer = $HUD/Cooldowns/Projectile/Timer
@onready var hud_shield_timer = $HUD/Cooldowns/Shield/Timer
@onready var hud_grenade_timer = $HUD/Cooldowns/Quicksand/Timer
@onready var hud_dash_timer = $HUD/Cooldowns/Dash/Timer
@onready var hud_projectile_img = $HUD/Cooldowns/Projectile
@onready var hud_shield_img = $HUD/Cooldowns/Shield
@onready var hud_grenade_img = $HUD/Cooldowns/Quicksand
@onready var hud_dash_img = $HUD/Cooldowns/Dash


# Timers
@onready var dash_timer: Timer = %DashTimer
@onready var projectile_timer: Timer = %ProjectileTimer
@onready var shield_timer: Timer = %ShieldTimer
@onready var grenade_timer: Timer = %GrenadeTimer
@onready var dash_duration: Timer = %DashDuration

# Cooldown variables
const MAX_SHIELD_CHARGES: int = 2
var shield_charges: int = MAX_SHIELD_CHARGES

const MAX_PROJECTILES_AMMO: int = 3
var projectile_ammo: int = MAX_PROJECTILES_AMMO

const MAX_GRENADE_CHARGES: int = 1
var grenade_charges: int = MAX_GRENADE_CHARGES

const MAX_DASH_CHARGES: int = 1
var dash_charges: int = MAX_DASH_CHARGES

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud_projectile_charges.maximun = MAX_PROJECTILES_AMMO
	hud_shield_charges.maximun = MAX_SHIELD_CHARGES
	hud_quicksand_charges.maximun = MAX_GRENADE_CHARGES
	hud_cooldowns_charges.maximun = MAX_DASH_CHARGES
	
	

func _manage_camera(event: InputEvent) -> void:
	if is_multiplayer_authority() and event is InputEventMouseMotion:
		rig.rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		spring_arm_pivot.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		spring_arm_pivot.rotation.x = clamp(spring_arm_pivot.rotation.x, -PI/3, PI/3)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
	_manage_camera(event)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_animations()
	update_hud()

	if can_move:
		movement(delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

	if Input.is_action_just_pressed("throw") and is_multiplayer_authority():
		shoot()

	# Can't block on air
	if Input.is_action_just_pressed("block") and is_on_floor() and is_multiplayer_authority():
		block()
		
	if Input.is_action_just_pressed("quicksand") and is_multiplayer_authority():
		var grenade_direction = -camera_3d.get_global_transform().basis.z.normalized()
		throw_grenade.rpc(grenade_direction)
		
	if Input.is_action_just_pressed("dance") and is_multiplayer_authority() and is_on_floor():
		dance.rpc()

	if is_multiplayer_authority():
		send_data.rpc(global_position, velocity, rig.quaternion)
	move_and_slide()


func apply_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta


@rpc("call_local")
func spawn_shield() -> void:
	animation_tree.get("parameters/playback").travel("Block")

	var shield_instance = player_shield.instantiate()
	add_sibling(shield_instance)
	shield_instance.global_position = shield_spawner.global_position
	shield_instance.global_rotation = shield_spawner.global_rotation
	shield_instance.appear()


func block() -> void:
	if shield_charges <= 0:
		return
		
	spawn_shield.rpc()

	# Timer is started automatically when
	# shields charges are missing, so it only 
	# needs to be called when charges are full
	if shield_charges == MAX_SHIELD_CHARGES:
		shield_timer.start()

	shield_charges -= 1


func _on_shield_timer_timeout() -> void:
	shield_charges += 1
	if shield_charges < MAX_SHIELD_CHARGES:
		shield_timer.start()


func shoot() -> void:
	if projectile_ammo == 0:
		return

	spawn_projectile.rpc(-camera_3d.get_global_transform().basis.z)
	if projectile_ammo == MAX_PROJECTILES_AMMO:
		projectile_timer.start()

	projectile_ammo -= 1


@rpc("call_local")
func spawn_projectile(camera_dir) -> void:
	# change the animation to throw
	animation_tree.get("parameters/playback").travel("Throw")

	var projectile_instance = projectile.instantiate()
	add_sibling(projectile_instance)
	projectile_instance.global_position = projectile_spawner.global_position
	projectile_instance.global_rotation = projectile_spawner.global_rotation
	projectile_instance.direction = camera_dir


func _on_projectile_timer_timeout() -> void:
	projectile_ammo += 1
	if projectile_ammo < MAX_PROJECTILES_AMMO:
		projectile_timer.start()


func movement(delta) -> void:
	if is_multiplayer_authority():
		var vy = velocity.y
		velocity.y = 0
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
		var direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, rig.rotation.y)
		velocity = lerp(velocity, direction * speed, acceleration * delta)
		velocity.y = vy
		if Input.is_action_just_pressed("jump") and is_on_floor() and can_jump:
			jump()
		if Input.is_action_just_pressed("dash"):
			dash(direction)
		if direction != Vector3.ZERO or not is_on_floor():
			stop_dance.rpc()


func jump() -> void:
	velocity.y = jump_velocity
	jumping = true


func dash(direction) -> void:
	if dash_timer.time_left > 0:
		return
	dash_charges = 0
	dashing = true
	velocity = direction * speed * 5
	dash_timer.start()
	dash_duration.start()



func handle_animations() -> void:
	if jumping:
		animation_tree.set("parameters/conditions/jumping", true)
		animation_tree.set("parameters/conditions/grounded", false)
	if is_on_floor() and not was_on_floor:
		jumping = false
		animation_tree.set("parameters/conditions/jumping", false)
		animation_tree.set("parameters/conditions/grounded", true)

	if not is_on_floor() and not jumping:
		animation_tree.get("parameters/playback").travel("Jump_Idle")
		animation_tree.set("parameters/conditions/grounded", false)

	var vl = velocity * rig.transform.basis
	
	if dashing:
		animation_tree.set("parameters/Dash/blend_position", Vector2(vl.x, -vl.z).normalized())
		animation_tree.get("parameters/playback").travel("Dash")
	elif not jumping:
		animation_tree.get("parameters/playback").travel("Movement")
		animation_tree.set("parameters/Movement/blend_position", Vector2(vl.x, -vl.z) / speed)
	was_on_floor = is_on_floor()


func setup(player_data: Statics.PlayerData) -> void:
	name = str(player_data.id)
	set_multiplayer_authority(player_data.id)
	camera_3d.current = is_multiplayer_authority()
	if is_multiplayer_authority():
		hud.visible = true


@rpc("unreliable_ordered")
func send_data(pos: Vector3, vel: Vector3, quaternion):
	global_position = lerp(global_position, pos, 0.75)
	velocity = lerp(velocity, vel, 0.75)
	rig.quaternion = rig.quaternion.slerp(quaternion, 0.75)
	


func take_damage(amount: float) -> void:
	player_health -= amount
	if player_health <= 0:
		player_health = 0
		if is_multiplayer_authority():
			die.rpc()


@rpc("call_local")
func die() -> void:
	animation_tree.get("parameters/playback").travel("Death")
	#can_move = false
	set_physics_process(false)
	set_process_input(false)


@rpc("call_local")
func throw_grenade(grenade_direction) -> void:
	if not can_throw_grenade:
		return
	grenade_charges = 0

	var up_direction: float = 5.0
	animation_tree.get("parameters/playback").travel("Throw")
	var grenade_instance = quicksand_grenade.instantiate() as RigidBody3D
	grenade_instance.position = projectile_spawner.global_position
	add_sibling(grenade_instance)
	
	grenade_instance.apply_central_impulse(
		grenade_direction * grenade_throw_force
	)
	grenade_timer.start()
	can_throw_grenade = false


func _on_grenade_timer_timeout() -> void:
	can_throw_grenade = true
	grenade_charges = 1


@rpc("call_local")
func dance() -> void:
	is_dancing = true
	animation_tree.get("parameters/playback").travel("Cheer")


@rpc("call_local")
func stop_dance() -> void:
	if is_dancing:
		is_dancing = false
		animation_tree.get("parameters/playback").travel("Movement")

func update_hud() -> void:
	hud_projectile_charges.amount = projectile_ammo
	hud_shield_charges.amount = shield_charges
	hud_quicksand_charges.amount = grenade_charges
	hud_cooldowns_charges.amount = dash_charges
	
	hud_projectile_timer.text = ""
	hud_projectile_img.modulate.a = 1
	if projectile_ammo == 0:
		hud_projectile_img.modulate.a = 0.5
		hud_projectile_timer.modulate.a = 2
		hud_projectile_timer.text = "[center][font_size=25]" + str(snapped(projectile_timer.time_left, 0.1)) + "[/font_size][/center]"


	hud_shield_timer.text = ""
	hud_shield_img.modulate.a = 1
	if shield_charges == 0:
		hud_shield_img.modulate.a = 0.5
		hud_shield_timer.modulate.a = 2
		hud_shield_timer.text = "[center][font_size=25]" + str(snapped(shield_timer.time_left, 0.1)) + "[/font_size][/center]"
		
	hud_grenade_timer.text = ""
	hud_grenade_img.modulate.a = 1
	if grenade_charges == 0:
		hud_grenade_img.modulate.a = 0.5
		hud_grenade_timer.modulate.a = 2
		hud_grenade_timer.text = "[center][font_size=25]" + str(snapped(grenade_timer.time_left, 0.1)) + "[/font_size][/center]"
		
	hud_dash_timer.text = ""
	hud_dash_img.modulate.a = 1
	if dash_charges == 0:
		hud_dash_img.modulate.a = 0.5
		hud_dash_timer.modulate.a = 2
		hud_dash_timer.text = "[center][font_size=25]" + str(snapped(dash_timer.time_left, 0.1)) + "[/font_size][/center]"

func _on_dash_duration_timeout() -> void:
	dashing = false


func _on_dash_timer_timeout():
	dash_charges = 1

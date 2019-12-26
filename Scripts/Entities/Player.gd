extends KinematicBody

const GRAVITY = 5
const JUMP_SPEED = 25

const WALK_ACCEL = 200
const AIR_ACCEL = 75
const JUMP_BOOST = 1.5

const WALK_FRICTION = 8
const AIR_FRICTION = 2
const FALL_FRICTION = 0.75

var MOUSE_SENSITIVITY = 0.5

var vel = Vector3()


const SHIELD_RELOAD = 0.25
const ROCKET_RELOAD = 0.1
const SHIELD_COST = 25
const ROCKET_COST = 10

var health = 100
var dead = false
var reload = 0
var energy = 100

const Rocket = preload("res://Entities/Rocket.tscn")
const Shield = preload("res://Entities/Shield.tscn")

var camera
var rotation_helper
var animation_player

var rotation_helper_orig_transform

var shoot_pos
var shield_pos

var shoot_sound
var shield_sound
var hit_sound

var hand_mat

signal died

func _ready():
	camera = $RotationHelper/Camera
	rotation_helper = $RotationHelper
	animation_player = $RotationHelper/Gun/AnimationPlayer

	rotation_helper_orig_transform = rotation_helper.transform

	shoot_pos = $RotationHelper/ShootPos
	shield_pos = $RotationHelper/ShieldPos

	shoot_sound = $ShootSound
	shield_sound = $ShieldSound
	hit_sound = $HitSound

	hand_mat = $RotationHelper/Gun/Hand.mesh.surface_get_material(0)

func reset():
	vel = Vector3()
	rotation_helper.transform = rotation_helper_orig_transform

	health = 100
	dead = false
	reload = 0
	energy = 100

	hand_mat.emission_energy = pow(energy/100, 2)
	HUD.set_health(health)

func _physics_process(delta):
	var cam_xform = camera.global_transform

	var input_movement_vector = Vector2()

	if not dead and Game.running:
		if Input.is_action_pressed("movement_forward"):
			input_movement_vector.y += 1
		if Input.is_action_pressed("movement_backward"):
			input_movement_vector.y -= 1
		if Input.is_action_pressed("movement_left"):
			input_movement_vector.x -= 1
		if Input.is_action_pressed("movement_right"):
			input_movement_vector.x += 1

	var dir = Vector3()
	dir = -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	dir.y = 0

	dir = dir.normalized()

	if is_on_floor():
		vel += delta * dir * WALK_ACCEL
		vel.x -= delta * (vel.x*WALK_FRICTION)
		vel.z -= delta * (vel.z*WALK_FRICTION)

		if Input.is_action_just_pressed("movement_jump") and not dead and Game.running:
			vel.y = JUMP_SPEED
			vel.x *= JUMP_BOOST
			vel.z *= JUMP_BOOST
	else:
		vel += delta * dir  * AIR_ACCEL
		vel.x -= delta * (vel.x*AIR_FRICTION)
		vel.z -= delta * (vel.z*AIR_FRICTION)

	vel.y -= delta * (vel.y*FALL_FRICTION)

	var state = PhysicsServer.body_get_direct_state(get_rid())
	vel += delta * state.get_total_gravity() * GRAVITY

	vel = move_and_slide(vel, Vector3(0, 1, 0), true)

	if Game.running and Game.connected:
		rpc_unreliable("update", global_transform, vel)


sync func _do_shoot(transform):
	var clone = Rocket.instance()
	clone.player = self
	clone.global_transform = transform

	self.get_parent().add_child(clone)

sync func _do_shield(transform):
	var clone = Shield.instance()
	clone.global_transform = transform

	self.get_parent().add_child(clone)


func _process(delta):
	if not dead and Game.running:
		if reload <= 0:
			if Input.is_action_just_pressed("player_shoot") and energy > ROCKET_COST:
				animation_player.seek(0)
				animation_player.play("Shoot")
				shoot_sound.play()

				if Game.connected:
					rpc("_do_shoot", shoot_pos.global_transform)
				else:
					_do_shoot(shoot_pos.global_transform)

				reload = ROCKET_RELOAD
				energy -= ROCKET_COST

			if Input.is_action_just_pressed("player_shield") and energy > SHIELD_COST:
				shield_sound.play()

				if Game.connected:
					rpc("_do_shield", shield_pos.global_transform)
				else:
					_do_shield(shield_pos.global_transform)

				reload = SHIELD_RELOAD
				energy -= SHIELD_COST
		else:
			reload -= delta

	if energy < 100:
		energy += delta * 15

	hand_mat.emission_energy = pow(energy/100, 2)

	if global_transform.origin.y < -50:
		health = 0

	if health <= 0 and not dead:
		dead = true
		if Game.connected:
			rpc("_killed")
		emit_signal("died", true)


func _input(event):
	if not dead and Game.running:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
			self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

			var camera_rot = rotation_helper.rotation_degrees
			camera_rot.x = clamp(camera_rot.x, -89.9, 89.9)
			rotation_helper.rotation_degrees = camera_rot

sync func _do_hit(damage):
	hit_sound.volume_db = linear2db(damage/25.0)
	hit_sound.play()

func splash_damage(damage, origin):
	health -= damage
	HUD.set_health(health)

	var away = (global_transform.origin-origin).normalized()
	vel += away * damage * 2

#	var angle = atan2(away.x, away.z)-deg2rad(rotation_degrees.y)
	HUD.hurt_flash(damage)

	if Game.connected:
		rpc("_do_hit", damage)
	else:
		_do_hit(damage)

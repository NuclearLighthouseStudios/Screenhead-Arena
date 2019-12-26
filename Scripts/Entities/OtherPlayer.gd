extends KinematicBody

const GRAVITY = 5

const WALK_FRICTION = 8
const AIR_FRICTION = 2
const FALL_FRICTION = 0.75

var vel = Vector3()

var Rocket = preload("res://Entities/Rocket.tscn")
var Shield = preload("res://Entities/Shield.tscn")

var shoot_sound
var shield_sound
var hit_sound

signal died

func _ready():
	shoot_sound = $ShootSound
	shield_sound = $ShieldSound
	hit_sound = $HitSound

puppet func update(transform, velocity):
	global_transform = transform
	vel = velocity

puppet func _killed():
	emit_signal("died", false)

func _physics_process(delta):
	if is_on_floor():
		vel.x -= delta * (vel.x*WALK_FRICTION)
		vel.z -= delta * (vel.z*WALK_FRICTION)
	else:
		vel.x -= delta * (vel.x*AIR_FRICTION)
		vel.z -= delta * (vel.z*AIR_FRICTION)

	vel.y -= delta * (vel.y*FALL_FRICTION)

	var state = PhysicsServer.body_get_direct_state(get_rid())
	vel += delta * state.get_total_gravity() * GRAVITY

	vel = move_and_slide(vel, Vector3(0, 1, 0), true)


sync func _do_shoot(transform):
	shoot_sound.play()

	var clone = Rocket.instance()
	clone.player = self
	clone.global_transform = transform

	self.get_parent().add_child(clone)

sync func _do_shield(transform):
	shield_sound.play()

	var clone = Shield.instance()
	clone.global_transform = transform

	self.get_parent().add_child(clone)

# warning-ignore:unused_argument
sync func _do_hit(damage):
	hit_sound.play()

func splash_damage(damage, origin):
	var away = (global_transform.origin-origin).normalized()
	vel += away * damage * 2

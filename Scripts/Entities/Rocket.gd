extends KinematicBody

var BULLET_SPEED = 50

const KILL_TIMER = 5
var timer = 0

var player

var Explosion = preload("res://Entities/Explosion.tscn")

func _ready():
	add_collision_exception_with(player)

func _physics_process(delta):
	var forward_dir = global_transform.basis.z.normalized() * -1
	var collision = move_and_collide(forward_dir * BULLET_SPEED * delta, false)

	if collision != null:
		if collision.collider.has_method("bounce"):
			collision.collider.bounce()

		var clone = Explosion.instance()
		self.get_parent().add_child(clone)

		clone.global_translate(collision.position + collision.normal*0.5)

		var trail = $Particles
		self.remove_child(trail)
		clone.add_child(trail)
		trail.set_owner(clone)
		trail.emitting = false

		queue_free()

# warning-ignore:unused_argument
func _process(delta):
	if timer == 0:
		$Particles.emitting = true
		$MeshInstance.show()

	timer += delta
	if timer >= KILL_TIMER:
		queue_free()

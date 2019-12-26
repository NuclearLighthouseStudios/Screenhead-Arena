extends Spatial

const EXPLOSION_DAMAGE = 45
const MAX_DISTANCE = 5

var wait = true
var done = false

# warning-ignore:unused_argument
func _physics_process(delta):
	wait = false

# warning-ignore:unused_argument
func _process(delta):
	if wait or done:
		return

	var targets = $Area.get_overlapping_bodies()
	for target in targets:
		if target.has_method("splash_damage"):
			var distance = (target.global_transform.origin-global_transform.origin).length()

			if distance>MAX_DISTANCE:
				continue

			var damage = lerp(EXPLOSION_DAMAGE, 0, distance/MAX_DISTANCE)

			target.splash_damage(damage, global_transform.origin)

	done = true

extends MeshInstance

func _process(delta):
	rotate_x(delta)
	rotate_y(delta*0.7)
	rotate_z(delta*1.2)

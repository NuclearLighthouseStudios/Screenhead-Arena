extends Control

func set_value(health):
	$Bar.rect_size.x = rect_size.x * health / 100

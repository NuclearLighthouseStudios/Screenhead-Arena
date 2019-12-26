extends Control

func set_damage(damage):
	$Flash.color.a = min(damage/50.0, 1)

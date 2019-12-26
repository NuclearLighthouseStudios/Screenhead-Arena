extends Node

const HealthBar = preload("res://UI/HUD/HealthBar.tscn")
const HurtFlash = preload("res://UI/HUD/HurtFlash.tscn")

var health_bar = null

func hide_hud():
	health_bar = null

	for i in get_children():
		i.queue_free()

func show_hud():
	for i in get_children():
		i.queue_free()

	health_bar = HealthBar.instance()
	add_child(health_bar)

func hurt_flash(damage):
	var flash = HurtFlash.instance()
	flash.set_damage(damage)
	add_child(flash)

func set_health(health):
	if health_bar:
		health_bar.set_value(max(health,0))

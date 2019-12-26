extends Node

enum {START, CONNECTING, GAME_OVER}

const menus = {
	START: preload("res://UI/Menus/Start.tscn"),
	CONNECTING: preload("res://UI/Menus/Connecting.tscn"),
	GAME_OVER: preload("res://UI/Menus/GameOver.tscn")
}

var menu_visible = false
var current_menu = null
var auto_lock = false

func _input(ev):
	if ev.is_action_pressed('ui_toggle_fullscreen'):
		OS.window_fullscreen = !OS.window_fullscreen

	if (Game.debug or current_menu == START) and ev.is_action_pressed('ui_cancel') and OS.get_name() != "HTML5":
		get_tree().quit()

	if ( not menu_visible or auto_lock ) and ev.is_action_pressed("ui_capture_mouse_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if not menu_visible and ev.is_action_pressed("ui_capture_mouse"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_menu():
	for i in get_children():
		i.queue_free()

	menu_visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func show_menu(menu):
	for i in get_children():
		i.queue_free()

	add_child(menus[menu].instance())

	menu_visible = true
	auto_lock = false
	current_menu = menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func allow_lock():
	auto_lock = true

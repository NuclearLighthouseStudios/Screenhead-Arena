extends Node

var loader
var wait = true

var all_deps = []

func _ready():
	Game.debug = false

	randomize()

	loader = ResourceLoader.load_interactive("res://Levels/Arena.tscn")
	if loader == null:
		return

	set_process(true)

# warning-ignore:unused_argument
func _process(delta):
	if loader == null:
		set_process(false)
		return

	if wait:
		wait = false
		return

	var err = loader.poll()

	if err == ERR_FILE_EOF:
	# warning-ignore:return_value_discarded
		$VBoxContainer/ProgressBar.value = 100
		get_tree().change_scene_to(loader.get_resource())
		Menu.show_menu(Menu.START)
		loader = null
	elif err == OK:
		var progress = float(loader.get_stage()) / loader.get_stage_count()
		$VBoxContainer/ProgressBar.value = progress * 100
	else:
		loader = null

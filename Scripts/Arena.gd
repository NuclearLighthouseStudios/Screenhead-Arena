extends Spatial

const Player = preload("res://Entities/Player.tscn")
const OtherPlayer = preload("res://Entities/OtherPlayer.tscn")

const Shield = preload("res://Entities/Shield.tscn")

var this_player = null
var other_player = null

var ready = 0

var shield_dealay = 0

func _ready():
# warning-ignore:return_value_discarded
	Game.connect("game_connected", self, "_on_game_connected")
# warning-ignore:return_value_discarded
	Game.connect("game_restart", self, "_on_game_restart")
# warning-ignore:return_value_discarded
	Game.connect("game_disconnected", self, "_on_game_disconnected")
# warning-ignore:return_value_discarded
	Game.connect("game_training", self, "_on_training")
# warning-ignore:return_value_discarded
	Game.connect("game_training_end", self, "_on_training_end")

	if Game.debug:
		_on_training()

func _process(delta):
	if $Figure.visible:
		shield_dealay -= delta
		if shield_dealay <= 0:
			shield_dealay = rand_range(1,2.5)
			var clone = Shield.instance()
			clone.global_transform = Transform()\
			.rotated(Vector3(0,1,0), deg2rad(randf()*360))\
			.translated(Vector3(0,rand_range(10,30),rand_range(5,10)))

			add_child(clone)

# warning-ignore:unused_argument
func _on_training_player_died(me):
	$WinSound.play()

	this_player.reset()
	this_player.global_transform = Transform().rotated(Vector3(0,1,0), deg2rad(randf()*360))
	this_player.global_transform = this_player.global_transform.translated(Vector3(0,5,40))

func _on_player_died(me):
	_win(not me)

func _win(me):
	$WinSound.play()

	Game.over(me)
	Menu.show_menu(Menu.GAME_OVER)

	this_player.hide()
	other_player.hide()
	HUD.hide_hud()

	$IdlePivot/IdleCam.current = true

remote func _ring_collected():
	_win(false)

func _on_WinArea_body_entered(body):
	if body == this_player:
		if Game.debug or Game.training:
			_on_training_player_died(false)
		else:
			_win(true)
			rpc("_ring_collected")

func _on_training():
	$IdlePivot/IdleCam.current = false
	$Figure.hide()

	get_tree().call_group("shields", "queue_free")

	this_player = Player.instance()
	this_player.connect("died", self, "_on_training_player_died")
	add_child(this_player)

	this_player.global_transform = Transform().rotated(Vector3(0,1,0), deg2rad(randf()*360))
	this_player.global_transform = this_player.global_transform.translated(Vector3(0,5,40))

	Menu.hide_menu()
	HUD.show_hud()
	Game.start()

func _on_training_end():
	Menu.show_menu(Menu.START)

	this_player.queue_free()
	HUD.hide_hud()

	$Figure.show()

	$IdlePivot/IdleCam.current = true

func _on_game_disconnected():
	Menu.show_menu(Menu.START)

	this_player.queue_free()
	other_player.queue_free()
	HUD.hide_hud()

	$Figure.show()

	$IdlePivot/IdleCam.current = true


remotesync func _setup_done(player_transform):
	other_player.global_transform = player_transform
	other_player.show()

	ready += 1

	if ready >= 2:
		yield(get_tree().create_timer(2), "timeout")
		Menu.hide_menu()
		this_player.show()
		HUD.show_hud()
		Game.start()

func _on_game_restart():
	$IdlePivot/IdleCam.current = false
	$Light/AnimationPlayer.seek(0)
	$Figure.hide()

	get_tree().call_group("shields", "queue_free")

	ready = 0

	this_player.reset()
	this_player.global_transform = Transform().rotated(Vector3(0,1,0), deg2rad(randf()*360))
	this_player.global_transform = this_player.global_transform.translated(Vector3(0,5,40))

	rpc("_setup_done", this_player.global_transform)

func _on_game_connected(other_playerId):
	$IdlePivot/IdleCam.current = false
	$Light/AnimationPlayer.seek(0)
	$Figure.hide()

	get_tree().call_group("shields", "queue_free")

	ready = 0

	this_player = Player.instance()
	this_player.set_name(str(get_tree().get_network_unique_id()))
	this_player.set_network_master(get_tree().get_network_unique_id())
	this_player.connect("died", self, "_on_player_died")
	this_player.hide()
	add_child(this_player)

	this_player.global_transform = Transform().rotated(Vector3(0,1,0), deg2rad(randf()*360))
	this_player.global_transform = this_player.global_transform.translated(Vector3(0,5,40))


	other_player = OtherPlayer.instance()
	other_player.set_name(str(other_playerId))
	other_player.set_network_master(other_playerId)
	other_player.connect("died", self, "_on_player_died")
	other_player.hide()
	add_child(other_player)

	rpc("_setup_done", this_player.global_transform)

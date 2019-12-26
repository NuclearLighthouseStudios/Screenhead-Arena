extends Control

var _connection_info = ""

func _ready():
	if Game.is_host:
		$Heading.text = "Hosting Game"
	else:
		$HBoxContainer/CopyButton.hide()

# warning-ignore:return_value_discarded
	Game.connect("game_connected", self, "_on_game_connected")
# warning-ignore:return_value_discarded
	Game.connect("game_canceled", self, "_on_game_canceled")
# warning-ignore:return_value_discarded
	Game.connect("net_log", self, "_on_game_net_log")
# warning-ignore:return_value_discarded
	Game.connect("connection_info", self, "_on_connection_info")

# warning-ignore:unused_argument
func _on_game_connected(otherPlayerId : int):
	Menu.allow_lock()
	$HBoxContainer/CancelButton.hide()
	$HBoxContainer/CopyButton.hide()

func _on_game_canceled():
	Menu.show_menu(Menu.START)

func _on_game_net_log(message : String):
	if $Messages.text.length() <= 1:
		$Messages.text = message
		$Messages.show()
	else:
		$Messages.text = $Messages.text + "\n" + message

func _on_connection_info(info : String):
	_connection_info = info
	$HBoxContainer/CopyButton.disabled = false

func _on_CancelButton_pressed():
	Game.cancel()

func _on_CopyButton_pressed():
	OS.clipboard = _connection_info

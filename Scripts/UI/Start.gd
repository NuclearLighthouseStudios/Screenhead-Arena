extends Control

onready var host_button = $HBoxContainer/VBoxContainer2/HostButton
onready var join_button = $HBoxContainer/VBoxContainer2/JoinButton
onready var player_name = $HBoxContainer/VBoxContainer/PlayerName
onready var game_code = $HBoxContainer/VBoxContainer/GameCode

const SAVE_PATH = "user://settings.cfg"

func _ready():
	$HBoxContainer2/VersionLabel.text %= ProjectSettings.get_setting("game/version")

	_load_config()

func _load_config():
	if OS.get_name() == "HTML5":
		var url_hash : String = JavaScript.eval("location.hash")

		if url_hash.length() > 1:
			game_code.text = url_hash.lstrip("#")
			JavaScript.eval("history.replaceState({}, document.title, window.location.pathname)")

	var config_file = ConfigFile.new()
	if config_file.load(SAVE_PATH) == OK:
		player_name.text = config_file.get_value("game","player_name","")

	host_button.disabled = player_name.text.length() <= 0
	join_button.disabled = player_name.text.length() <= 0 or game_code.text.length() != 5

func _save_config():
	var config_file = ConfigFile.new()
	config_file.set_value("game","player_name",player_name.text)
	config_file.save(SAVE_PATH)

func _on_HostButton_pressed():
	var res = Game.host(player_name.text)

	if res != OK:
		print("Error creating server")
		return

	_save_config()
	Menu.show_menu(Menu.CONNECTING)

func _on_JoinButton_pressed():
	var res : int = Game.join(game_code.text, player_name.text.strip_edges())

	if res != OK:
		print("Error joining server")
		return

	_save_config()
	Menu.show_menu(Menu.CONNECTING)

func _on_TrainingLink_pressed():
	_save_config()
	Game.start_training()

func _on_PlayerName_text_entered(new_text):
	if new_text.length() > 0:
		_on_HostButton_pressed()

func _on_GameCode_text_entered(new_text):
	if new_text.length() == 5 and player_name.text.length() > 0:
		_on_JoinButton_pressed()

func _on_PlayerName_text_changed(new_text):
	host_button.disabled = new_text.length() <= 0
	join_button.disabled = new_text.length() <= 0 or game_code.text.length() != 5

func _on_GameCode_text_changed(new_text):
	join_button.disabled = new_text.length() != 5 or player_name.text.length() <= 0

func _on_CopyLink_pressed():
# warning-ignore:return_value_discarded
	OS.shell_open("http://nuclearlighthousestudios.com/")

extends Node

signal game_connected(other_player_id)
signal game_restart
signal game_disconnected
signal game_canceled
signal game_over
signal connection_failed
signal connection_info(info)
signal net_log(message)

# warning-ignore:unused_class_variable
var debug : bool = true

var running : bool = false
var connected : bool = false
var won : bool = false

var player_name : String = ""
var score : int = 0

var other_player_id : int = 0
var other_player_name : String = ""
var other_player_score : int = 0

var is_host : bool = false
var game_code : String = ""

func _ready():
# warning-ignore:return_value_discarded
	MultiplayerClient.connect("connected", self, "_on_network_connected")
# warning-ignore:return_value_discarded
	MultiplayerClient.connect("connection_failed", self, "_on_connection_failed")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected",self,"_on_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed",self,"_on_connection_failed")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")


remote func _hello_req(name : String, version : String):
	self.other_player_name = name

	emit_signal("net_log", "Challenger name is %s" % name)

	var version_regex := RegEx.new()
# warning-ignore:return_value_discarded
	version_regex.compile("^([0-9]+)\\.([0-9]+)\\.([0-9]+)$")
	var result := version_regex.search(version)

	if not result or result.get_group_count() != 3:
		rpc("_hello_res", false)
		return

	var semver : PoolStringArray = ProjectSettings.get_setting("game/version").split(".")

	if result.strings[1] != semver[0] or result.strings[2] != semver[1]:
		emit_signal("net_log", "Incompatible version!")
		rpc("_hello_res", false)
	else:
		rpc("_hello_res", true)

remote func _hello_res(ok):
	if ok:
		emit_signal("net_log", "Get ready!")
		connected = true
		emit_signal("game_connected", other_player_id)
	else:
		emit_signal("net_log", "Version check failed!")

		_on_connection_failed()


func _on_player_connected(id : int):
	emit_signal("net_log", "Incoming connection...")

#	get_tree().refuse_new_network_connections = true

	self.other_player_id = id

	rpc("_hello_req", player_name, ProjectSettings.get_setting("game/version"))


# warning-ignore:unused_argument
func _on_player_disconnected(id):
	if connected:
		emit_signal("game_disconnected")
	else:
		emit_signal("net_log", "Connection failed!")
		emit_signal("connection_failed")

	running = false
	connected = false
	get_tree().network_peer = null
	MultiplayerClient.stop()

func _on_server_disconnected():
	_on_player_disconnected(1)

func _on_connection_failed():
	running = false
	connected = false
	get_tree().network_peer = null
	MultiplayerClient.stop()

	emit_signal("net_log", "Connection failed!")
	emit_signal("connection_failed")


func _on_network_connected(game : String):
	self.game_code = game

	if is_host:
		emit_signal("net_log", "Game code is %s" % self.game_code)
		emit_signal("net_log", "Waiting for challenger...")
		emit_signal("connection_info", self.game_code)
	else:
		emit_signal("net_log", "Connecting to %s..." % self.game_code)

	get_tree().network_peer = MultiplayerClient.rtc_mp


# warning-ignore:shadowed_variable
func host(player_name : String):
	self.player_name = player_name
	is_host = true
	connected = false

	MultiplayerClient.host_game(ProjectSettings.get_setting("game/server"))

	return OK

# warning-ignore:shadowed_variable
func join(code : String, player_name : String):
	self.player_name = player_name
	self.game_code = code
	is_host = false
	connected = false

	MultiplayerClient.join_game(ProjectSettings.get_setting("game/server"), code)

	return OK

func start():
	running = true

func restart():
	emit_signal("game_restart")

func cancel():
	running = false
	connected = false
	get_tree().network_peer = null
	MultiplayerClient.stop()
	emit_signal("game_canceled")

func end():
	running = false
	connected = false
	get_tree().network_peer = null
	MultiplayerClient.stop()
	emit_signal("game_disconnected")

# warning-ignore:shadowed_variable
func over(won : bool):
	running = false
	self.won = won

	if won:
		score += 1
	else:
		other_player_score += 1

	emit_signal("game_over")

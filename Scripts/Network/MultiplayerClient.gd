extends Node

var game : String
var hosting : bool

var ws_client := WebSocketClient.new()

var rtc_mp := WebRTCMultiplayer.new()
var peer : WebRTCPeerConnection

signal connected()
signal connection_failed()

func _init():
# warning-ignore:return_value_discarded
	ws_client.connect("data_received", self, "_ws_parse_msg")
# warning-ignore:return_value_discarded
	ws_client.connect("connection_established", self, "_ws_connected")
# warning-ignore:return_value_discarded
	ws_client.connect("connection_error", self, "_ws_connection_closed")
# warning-ignore:return_value_discarded
	ws_client.connect("connection_closed", self, "_ws_connection_closed")

# warning-ignore:return_value_discarded
	rtc_mp.connect("connection_succeeded", self, "_connection_succeeded")


# warning-ignore:shadowed_variable
func host_game(url : String):
	stop()
	hosting = true
	self.game = ""
# warning-ignore:return_value_discarded
	ws_client.connect_to_url(url)

# warning-ignore:shadowed_variable
func join_game(url : String, game : String):
	stop()
	hosting = false
	self.game = game
# warning-ignore:return_value_discarded
	ws_client.connect_to_url(url)

func stop():
	rtc_mp.close()
	ws_client.disconnect_from_host()


func _send_msg(cmd : String, data : String):
# warning-ignore:return_value_discarded
	ws_client.get_peer(1).put_packet(("%s\n%s" % [cmd, data]).to_utf8())

func _connect_peer():
	self.peer = WebRTCPeerConnection.new()
	var peer_id := 2 if hosting else 1

# warning-ignore:return_value_discarded
	peer.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
# warning-ignore:return_value_discarded
	peer.connect("session_description_created", self, "_offer_created")
# warning-ignore:return_value_discarded
	peer.connect("ice_candidate_created", self, "_new_ice_candidate")

# warning-ignore:return_value_discarded
	rtc_mp.add_peer(peer, peer_id)

# warning-ignore:return_value_discarded
	if hosting: peer.create_offer()

func _new_ice_candidate(mid : String, index : int, sdp : String):
	_send_msg("CANDIDATE", "%s\n%d\n%s" % [mid, index, sdp])

func _offer_created(type : String, data : String):
# warning-ignore:return_value_discarded
	peer.set_local_description(type, data)

	if type == "offer":
		_send_msg("OFFER", data)
	else:
		_send_msg("ANSWER", data)


func _connection_succeeded():
	ws_client.disconnect_from_host()


func _ws_connection_closed(_clean : bool):
	if rtc_mp.get_peers().size() <= 0:
		emit_signal("connection_failed")

func _ws_connected(_protocol : String = ""):
	ws_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)

	if hosting:
# warning-ignore:return_value_discarded
		rtc_mp.initialize(1, true)
# warning-ignore:return_value_discarded
		ws_client.get_peer(1).put_packet(("HOST\n").to_utf8())
	else:
# warning-ignore:return_value_discarded
		rtc_mp.initialize(2, true)
# warning-ignore:return_value_discarded
		ws_client.get_peer(1).put_packet(("JOIN\n%s" % self.game).to_utf8())

func _ws_parse_msg():
	var pkt_str : String = ws_client.get_peer(1).get_packet().get_string_from_utf8()

	var req : PoolStringArray = pkt_str.split('\n', true, 1)
	if req.size() != 2:
		return

	var cmd : String = req[0]
	var data : String = req[1]

	if cmd == "GAME":
		self.game = data
		emit_signal("connected", self.game)

	elif cmd == "PEER":
		_connect_peer()

	elif cmd == "OFFER":
# warning-ignore:return_value_discarded
		peer.set_remote_description("offer", data)

	elif cmd == "ANSWER":
# warning-ignore:return_value_discarded
		peer.set_remote_description("answer", data)

	elif cmd == "CANDIDATE":
		var candidate : PoolStringArray = data.split('\n', false)
		if candidate.size() != 3:
			return
		if not candidate[1].is_valid_integer():
			return
# warning-ignore:return_value_discarded
		peer.add_ice_candidate(candidate[0], int(candidate[1]), candidate[2])

func _process(_delta : float):
	var status := ws_client.get_connection_status()

	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		ws_client.poll()

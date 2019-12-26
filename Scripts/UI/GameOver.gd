extends Control

var again = false

func _ready():
	if Game.won:
		$Message.text = "You Won!"
	else:
		$Message.text = "You Lost!"

	if Game.score >= Game.other_player_score:
		$Scores.text %= [Game.player_name, Game.other_player_name, Game.score, Game.other_player_score]
	else:
		$Scores.text %= [Game.other_player_name, Game.player_name, Game.other_player_score, Game.score]

func _on_Disconnect_pressed():
	Game.end()

remotesync func _again( who ):
	if again:
		$HBoxContainer/Disconnect.disabled = true
		$AgainLabel.text = "Get ready!"
		Menu.allow_lock()
		Game.restart()
	else:
		again = true
		if get_tree().get_rpc_sender_id() == get_tree().get_network_unique_id():
			$AgainLabel.text = "Waiting for other player..."
		else:
			$AgainLabel.text = "%s wants to go again" % who

func _on_Again_pressed():
	$HBoxContainer/Again.disabled = true
	rpc("_again", Game.player_name)

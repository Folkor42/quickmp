extends Control

@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var v_box_container: VBoxContainer = $VBoxContainer/VBoxContainer
@onready var start_button: Button = $VBoxContainer2/StartButton
@onready var exit_button: Button = $VBoxContainer2/ExitButton

var players : Array

func _ready() -> void:
	MultiplayerManager.game_started = false
	MultiplayerManager.current_scene = "res://lobby.tscn"
	join_button.pressed.connect ( join_game )
	host_button.pressed.connect ( host_game )
	start_button.pressed.connect ( host_start )
	exit_button.pressed.connect ( exit_game )
	MultiplayerManager.player_connected.connect(update_players)
	MultiplayerManager.player_disconnected.connect(update_players)
	update_players(null)
	
func host_game () -> void:
	MultiplayerManager.create_game()
	
func join_game () -> void:
	MultiplayerManager.join_game()
		
@rpc func update_players(_new_player_id, _new_player_info = null) -> void:
	if multiplayer:		
		if multiplayer.is_server():
			start_button.visible=true
		else:
			start_button.visible=false
	for c in v_box_container.get_children():
		c.queue_free()
	MultiplayerManager.players.sort()
	for p in MultiplayerManager.players:
		var new_label = Label.new()
		new_label.text = MultiplayerManager.players[p].name
		v_box_container.add_child(new_label)
	pass

func host_start()->void:
	MultiplayerManager.host_start()
	#rpc ("start_game")
	
@rpc("authority","call_local") func start_game() -> void:
	print ("Game Starting")
	MultiplayerManager.game_started = true
	MultiplayerManager.current_scene = "res://game.tscn"
	get_tree().change_scene_to_file(MultiplayerManager.current_scene)
	
func exit_game () -> void:
	get_tree().quit()

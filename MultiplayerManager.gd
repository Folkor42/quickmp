extends Node

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal start_game

var peer : ENetMultiplayerPeer
var game_started : bool = false
var current_scene : String

const IP_ADDRESS : String = "127.0.0.1"
const PORT : int = 12345
const MAX_CONNECTIONS : int = 4
# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

var players_loaded = 0

func _ready():
	current_scene = "res://lobby.tscn"
	game_started = false
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func join_game(address = ""):
	if address.is_empty():
		address = IP_ADDRESS
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	player_info['name'] = str(multiplayer.get_unique_id())
	
@rpc ("any_peer","call_local") func check_level()->String:
	return current_scene
	
func create_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	player_info['name'] = str(multiplayer.get_unique_id())
	players[1] = player_info
	player_connected.emit(1, player_info)

func host_start() -> void:
	rpc ("load_game","res://game.tscn")

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	players.clear()

@rpc("reliable", "any_peer")
func request_scene():
	var sender_id = multiplayer.get_remote_sender_id()
	print("request_scene() called by player ", sender_id)
	if multiplayer.is_server():  # ✅ Only the server should send the response
		print("Server received scene request from player ", sender_id)
		rpc_id(sender_id, "receive_scene", current_scene)  # ✅ Send scene to client

@rpc("reliable", "authority")
func receive_scene(scene_path: String):
	print("Received scene from server: ", scene_path)
	load_and_change_scene(scene_path)

func load_and_change_scene(scene_path: String):
	var new_scene = load(scene_path)
	if new_scene:
		get_tree().change_scene_to_file(scene_path)

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			start_game.emit()
			game_started=true
			players_loaded = 0


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	if !is_multiplayer_authority():
		rpc ("request_scene")
	if is_multiplayer_authority():
		current_scene = check_level()

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	print ("Registering Player")
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)
	if id == 1:
		exit_game()

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

func exit_game () -> void:
	get_tree().quit()

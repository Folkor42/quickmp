extends Node2D

const PLAYER_SCENE : PackedScene = preload("res://multiplayer_pc.tscn")
@onready var player_node: Node2D = $PlayerNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for p in MultiplayerManager.players:
		add_player(p)
	MultiplayerManager.player_disconnected.connect(remove_player)
	pass # Replace with function body.

func add_player(id) -> void:
	if is_multiplayer_authority():
		print ("ADDING PLAYER %d " % id)
		var player = PLAYER_SCENE.instantiate()
		player.position.x = randi_range(-8,8) * 50
		player.name = MultiplayerManager.players[id].name
		player_node.call_deferred("add_child",player,true)
		pass
	if !is_multiplayer_authority():
		print ("I can't update %d" % id)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

@rpc func remove_player(id) -> void:
	print ("Removing player %d" % id)
	if !player_node.has_node(str(id)):
		return
	var p = player_node.get_node(str(id))
	p.queue_free()

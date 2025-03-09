extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var label: Label = $Label
@onready var camera_2d: Camera2D = $Camera2D
@onready var v_box_container: VBoxContainer = $Camera2D/CanvasLayer/Control/VBoxContainer2/VBoxContainer
@onready var lobby_button: Button = $Camera2D/CanvasLayer/Control/VBoxContainer2/LobbyButton

var edelta : float

func _enter_tree() -> void:
	#set_multiplayer_authority(name.to_int())
	pass
	
func _ready() -> void:
	label.text = name
	#get_tree().process_frame.connect(_each_frame)
	update_players()
	MultiplayerManager.player_connected.connect(update_players)
	MultiplayerManager.player_disconnected.connect(update_players)
	lobby_button.pressed.connect(back_to_lobby)
	await get_tree().create_timer(0.5).timeout
	set_multiplayer_authority(name.to_int())
	camera_2d.enabled=is_multiplayer_authority()
	
func back_to_lobby() -> void:
	get_tree().change_scene_to_file("res://lobby.tscn")
	pass

func _physics_process(delta: float) -> void:
	edelta=delta
	if is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

#func _each_frame():
	#if is_multiplayer_authority():
		#rpc("updatePos", name, position)
		#
#@rpc func updatePos (id, pos):
	#if name == id:
		##print ("At position : " + str(pos))
		#position = lerp (position, pos, edelta * 15)

@rpc func update_players( _id = null, _player_info = null ) -> void:
	for c in v_box_container.get_children():
		c.queue_free()
	MultiplayerManager.players.sort()
	for p in MultiplayerManager.players:
		var new_label = Label.new()
		new_label.text = MultiplayerManager.players[p].name
		v_box_container.add_child(new_label, true)
	pass

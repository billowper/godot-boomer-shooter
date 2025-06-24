extends Node

enum GameState{
	STARTUP,
	MAIN_MENU,	
	LOADING,
	CINEMATIC,
	PLAYING,
	PAUSED,
	GAME_OVER
}
var game_state: GameState = GameState.STARTUP
var menu_scene: Node = null
var hud_scene: Node = null
var pause_screen: Node = null
var current_map_scene: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_scene = load("res://scenes/menu.tscn").instantiate()

	add_child(menu_scene)

	game_state = GameState.MAIN_MENU

	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)

func on_peer_connected() -> void:
	Console.add_log("peer connected")

func on_peer_disconnected() -> void:
	Console.add_log("peer connected")

func start_game() -> void:

	game_state = GameState.LOADING

	remove_child(menu_scene)

	load_map("res://maps/m1.tscn")

	hud_scene = load("res://scenes/hud.tscn").instantiate()
	add_child(hud_scene)

	pause_screen = load("res://scenes/pause_screen.tscn").instantiate()

	game_state = GameState.PLAYING

	var peer = ENetMultiplayerPeer.new()
	peer.create_server(7777, 32)
	multiplayer.multiplayer_peer = peer

func join_game(address: String) -> void:
	game_state = GameState.LOADING

	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, 7777)
	multiplayer.multiplayer_peer = peer

func load_map(map_path: String) -> void:

	game_state = GameState.LOADING

	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null

	current_map_scene = load(map_path).instantiate()
	current_map_scene.process_mode = PROCESS_MODE_PAUSABLE
	add_child(current_map_scene)
	
	game_state = GameState.PLAYING

func quit_to_menu() -> void:
	if hud_scene:
		hud_scene.queue_free()
		hud_scene = null
	
	if pause_screen:
		pause_screen.queue_free()
		pause_screen = null
	
	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null
		
	add_child(menu_scene)

	game_state = GameState.MAIN_MENU

	multiplayer.multiplayer_peer = null

func toggle_pause() -> void:
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		current_map_scene.get_tree().paused = true
		remove_child(hud_scene)
		add_child(pause_screen)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	elif game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
		current_map_scene.get_tree().paused = false
		add_child(hud_scene)
		remove_child(pause_screen)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):

	if Input.is_action_just_pressed("pause"):
		toggle_pause()

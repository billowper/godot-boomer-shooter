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

var _local_player

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$%GameWorld.process_mode = Node.PROCESS_MODE_PAUSABLE

	menu_scene = load("res://scenes/menu.tscn").instantiate()
	%UI.add_child(menu_scene)

	game_state = GameState.MAIN_MENU

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	LEG_Console.add_command("quit", quit_to_menu, true)
	LEG_Console.add_command("join", join_game, true)
	LEG_Console.add_command("map", load_map, true)

	await get_tree().process_frame # wait for everything to be ready

	var existing_map = get_tree().get_first_node_in_group("maps")
	if (existing_map != null):
		LEG_Log.log("Found existing map, using it")
		game_state = GameState.LOADING
		%UI.remove_child(menu_scene)
		current_map_scene = existing_map
		current_map_scene.process_mode = PROCESS_MODE_PAUSABLE
		%GameWorld.add_child(current_map_scene, true)
		game_state = GameState.PLAYING
		await get_tree().physics_frame 
		post_map_load()

func _on_peer_connected() -> void:
	LEG_Log.log("peer connected")

func _on_peer_disconnected() -> void:
	LEG_Log.log("peer disconnected")

func is_playing() -> bool:
	return game_state == GameState.PLAYING

func start_game() -> void:
	load_map("m1")

func get_local_player() -> Node3D:
	return _local_player

func join_game(address: String) -> bool:
	game_state = GameState.LOADING

	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, 7777)
	multiplayer.multiplayer_peer = peer

	return true

func load_map(map_name: String) -> bool:
	game_state = GameState.LOADING
	%UI.remove_child(menu_scene)
	
	if current_map_scene:
		%GameWorld.remove_child(current_map_scene)
		current_map_scene.queue_free()
		current_map_scene = null

	var res_path = "res://maps/"+map_name+".tscn"

	if ResourceLoader.exists(res_path):
		current_map_scene = load("res://maps/"+map_name+".tscn").instantiate()
		current_map_scene.process_mode = PROCESS_MODE_PAUSABLE
		%GameWorld.add_child(current_map_scene, true)
		game_state = GameState.PLAYING
		await get_tree().physics_frame 
		post_map_load()
		return true
	else:
		quit_to_menu()

	return false	

func post_map_load() -> void:
	if _local_player:
		_local_player.queue_free()
		_local_player = null

	var player = load("res://prefabs/player.tscn").instantiate() as Node3D

	_local_player = player

	%GameWorld.add_child(player, true)

	var spawn_points = current_map_scene.get_tree().get_nodes_in_group("spawn_points")
	
	if spawn_points.size() > 0:
		var sp = spawn_points.pick_random()
		player.global_position = sp.global_position
		player.global_rotation = sp.global_rotation

	if hud_scene == null:
		hud_scene = load("res://scenes/hud.tscn").instantiate()

	%UI.add_child(hud_scene)

	if pause_screen == null:
		pause_screen = load("res://scenes/pause_screen.tscn").instantiate()
	
	game_state = GameState.PLAYING

	if multiplayer.multiplayer_peer == null:
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(7777, 32)
		multiplayer.multiplayer_peer = peer

func quit_to_menu() -> bool:
	if _local_player:
		_local_player.queue_free()
		_local_player = null

	if hud_scene:
		hud_scene.queue_free()
		hud_scene = null
	
	if pause_screen:
		pause_screen.queue_free()
		pause_screen = null
	
	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null
		
	%UI.add_child(menu_scene)

	game_state = GameState.MAIN_MENU
	get_tree().paused = false

	multiplayer.multiplayer_peer = null
	return true

func toggle_pause() -> void:
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		get_tree().paused = true
		%UI.remove_child(hud_scene)
		%UI.add_child(pause_screen)

	elif game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
		get_tree().paused = false
		%UI.add_child(hud_scene)
		%UI.remove_child(pause_screen)

func _process(_delta):

	if Input.mouse_mode != get_desired_mouse_mode():
		Input.set_mouse_mode(get_desired_mouse_mode())

	if Input.is_action_just_pressed("pause"):
		toggle_pause()

	if Input.is_action_just_pressed("toggle_console"):
		LEG_Console.MainWindow.toggle()

	if Input.is_action_just_pressed("debug_toggle_cursor"):
		_debug_show_cursor = not _debug_show_cursor

func get_desired_mouse_mode() -> int:
	if _debug_show_cursor or (LEG_Console.MainWindow.has_focus()) \
		or game_state == GameState.PAUSED \
		or game_state == GameState.MAIN_MENU: 
		return Input.MOUSE_MODE_VISIBLE
	elif game_state == GameState.PLAYING:
		return Input.MOUSE_MODE_CAPTURED
	else:
		return Input.MOUSE_MODE_VISIBLE

var _debug_show_cursor := false
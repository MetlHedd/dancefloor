extends Node

# Scenes
var main_menu_scene_path : String = "res://Scenes/Game/MainMenu.tscn"

# Constant server parameters
const default_ip : String = '127.0.0.1'
const default_port : int = 9080
const default_max_players : int = 32

# World properties
var players : Dictionary = {}
var self_data : Dictionary = {
    "name": "Player0",
    "is_alive": false,
    "position": Vector2(200, 100),
    "skin": "Cat",
    "palette": "default"
}
master var players_alive : int = 0

# Server only properties
var current_map_json_string : String = ""
var current_map_json
var default_map_path : String = "res://Maps/1.json"
var loaded_maps : Array = []

# Websocket server on html5
var ws_server = null

func _ready():
    get_tree().connect("network_peer_connected", self, "_on_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
    get_tree().connect("server_disconnected", self, "_disconnected_from_server")
    get_tree().connect("connection_failed", self, "_disconnected_from_server")

func reset_data() -> void:
    players = {}
    self_data = {
        "name": "Player0",
        "is_alive": false,
        "position": Vector2(200, 100),
        "skin": "Cat",
        "palette": "default"
    }
    current_map_json_string = ""
    current_map_json = {}
    loaded_maps = []

func create_server(player_name = "Player0", port = default_port, slots = default_max_players) -> void:
    reset_data()

    # Limit player name lenght and characters
    var regex = RegEx.new()
    regex.compile("^[^\\W]+")

    var regex_searched = regex.search(player_name)
    if regex_searched:
        player_name = regex_searched.get_string()
    else:
        player_name = "Player0"

    if player_name.length() == 0 or player_name.length() > 16:
        player_name = "Player0"
        
    # Load the default map
    var file_handler : File = File.new()

    if file_handler.open(default_map_path, File.READ) == OK:
        current_map_json_string = file_handler.get_as_text()
    else:
        print("[Server - World: ready] Could not load map on default map path")

    # Pass the players paramaters to the self_data
    self_data.name = player_name
    self_data.skin = Defines.selected_skin
    self_data.palette = Defines.selected_palette

    # Since peer 1 is the master it will be added to the players lsit
    players[1] = self_data

    # Creates the network server peer
    if OS.get_name() == "HTML5":
        ws_server = WebSocketServer.new()
        ws_server.listen(port, PoolStringArray(), true)
        get_tree().set_network_peer(ws_server)
    else:
        var peer : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()

        peer.compression_mode = NetworkedMultiplayerENet.COMPRESS_ZSTD

        var network_error = peer.create_server(port, slots)

        if network_error != OK:
            Defines.has_main_menu_error_message = true
            Defines.main_menu_error_message = "Could not create server"
            get_tree().change_scene(main_menu_scene_path)

        get_tree().set_network_peer(peer)

func connect_to_server(player_name = "Guest", ip = default_ip, port = default_port) -> void:
    reset_data()

    # Limit player name lenght and characters
    var regex = RegEx.new()
    regex.compile("^[^\\W]+")

    var regex_searched = regex.search(player_name)
    if not regex_searched:
        player_name = "Guest"
    else:
        player_name = regex_searched.get_string()

    if player_name.length() == 0 or player_name.length() > 16:
        player_name = "Guest"

    # Pass the players paramaters to the self_data
    self_data.name = player_name
    self_data.skin = Defines.selected_skin
    self_data.palette = Defines.selected_palette

    # Network signals
    get_tree().connect("connected_to_server", self, "_connected_to_server")

    # Creates the network client peer
    if OS.get_name() == "HTML5":
        ws_server = WebSocketClient.new()
        ws_server.connect_to_url("ws://%s:%d" % [ip, port], PoolStringArray(), true)
        get_tree().set_network_peer(ws_server)
    else:
        var peer : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()

        peer.compression_mode = NetworkedMultiplayerENet.COMPRESS_ZSTD

        var network_error = peer.create_client(ip, port)

        if network_error != OK:
            Defines.has_main_menu_error_message = true
            Defines.main_menu_error_message = "Could not connect to server"
            get_tree().change_scene(main_menu_scene_path)

        get_tree().set_network_peer(peer)

# Called when a client connect to a server
func _connected_to_server() -> void:
    var local_player_id =  get_tree().get_network_unique_id()

    players[local_player_id] = self_data
    
    get_node("/root/Game")._init_player()

    rpc("_send_player_information", local_player_id, self_data)
    get_node("/root/Game/World").rpc_id(1, "_request_map_informations", get_tree().get_network_unique_id())

func _on_player_connected(connected_player_id) -> void:
    var local_player_id = get_tree().get_network_unique_id()

    if not get_tree().is_network_server():
        rpc_id(1, "_request_player_info", local_player_id, connected_player_id)

func _on_player_disconnected(disconnected_player_id) -> void:
    players.erase(disconnected_player_id)

    get_node("/root/Game")._on_player_left(disconnected_player_id)

func _disconnected_from_server() -> void:
    Defines.has_main_menu_error_message = true
    Defines.main_menu_error_message = "Could not create server"
    get_tree().change_scene(main_menu_scene_path)

func _process(_delta):
    if ws_server != null and get_tree().has_network_peer():
        if OS.get_name() == "HTML5" and ws_server.is_listening():
            ws_server.poll()
        elif OS.get_name() == "HTML5" and (ws_server.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED or ws_server.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
            ws_server.poll()
    
    if get_tree().has_network_peer() and get_tree().is_network_server():
        if players_alive <= 1 and players.size() > 1:
            init_new_game()
        elif players_alive == 0 and players.size() == 1:
            init_new_game()

func update_position(id, new_position : Vector2) -> void:
    players[id].position = new_position

func get_player_name_by_id(id : int) -> String:
    return players[id].name

func init_new_game() -> void:
    if get_tree().is_network_server():
        players_alive = players.size()
        
        var random_selected_map = current_map_json_string

        for id in players:
            players[id].is_alive = true
        
        var map_json : Dictionary = get_node("/root/Game/World").load_map(random_selected_map)
        
        get_node("/root/Game").rpc("new_game_started", map_json)

remote func _request_player_info(request_from_id, player_id) -> void:
    if get_tree().is_network_server():
        rpc_id(request_from_id, '_send_player_information', player_id, players[player_id])

remote func _request_players(request_from_id) -> void:
    if get_tree().is_network_server():
        for peer_id in players:
            if peer_id != request_from_id:
                rpc_id(request_from_id, '_send_player_information', peer_id, players[peer_id])

remote func _send_player_information(id, info) -> void:
    players[id] = info
    
    get_node("/root/Game")._on_player_join(id, info)

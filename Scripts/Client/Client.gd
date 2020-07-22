extends Control

# World properties
var grounds : Array = []
var players : Dictionary = {}
var own_player_scene
var own_player_info = {
    "name": "playerName"
}

# Websocket properties
var ws_client : WebSocketClient = WebSocketClient.new()

# Server properties
var server_url : String = ""
var server_port : int = 0

# Debug properties
var server_debug_enabled : bool = true

# Packet regex
var packet_regex = RegEx.new()

func _ready():
    # Get properties from defines
    server_url = Defines.server_url

    # Compile packet regex
    packet_regex.compile("[^\\s]+")

    # Connect network signals
    get_tree().conenct("network_peer_connected", self, "_network_player_connected")
    get_tree().conenct("network_peer_disconnected", self, "_network_player_disconnected")
    get_tree().conenct("connected_to_server", self, "_network_connected")
    get_tree().conenct("connection_failed", self, "_network_disconnected")
    get_tree().conenct("server_disconnected", self, "_network_disconnected")

    # Connect to the server
    var network_peer : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
    var network_error = network_peer.create_client(server_url, server_port)

    get_tree().network_peer = network_peer

    if network_error != OK:
        print("[Client: _ready] Could not connect to multiplayer server")
        get_tree().network_peer = null
    
    own_player_scene = $World.new_player(Defines.player_name, true)

func _process(_delta):
    pass

func _network_player_disconnected(id) -> void:
    players[id] = {
        "player_scene": false,
    }

func _network_client_connected(proto = "") -> void:
    print("[Client: _ws_client_connected] Connected to server %s" % [server_url])
    
    ws_client_send_packet("playerConnection %s" % [Defines.player_name])

func _network_client_disconnected(was_clean = false) -> void:
    set_process(false)

func _ws_client_on_data() -> void:
    var packet_string = ws_client.get_peer(1).get_packet().get_string_from_utf8()
    var regex_search = packet_regex.search_all(packet_string)

    # Print packet data if debug is enabled
    if server_debug_enabled:
        print("[Server: _ws_server_on_data] Receveid from websocket server: %s" % [packet_string])

    # Handle packet

    if regex_search.size() > 0:		
        var args : Array = []
                
        for search in regex_search:
            args.append(search.get_string())
        
        if args[0] == "receiveMap" and args.size() == 2:
            $World.new_game(Marshalls.base64_to_utf8(args[1]))
        elif args[0] == "newPlayer" and args.size() == 5:
            players[args[1]] = $World.new_player(args[2], false, Vector2(args[3], args[4]))
        elif args[0] == "validInput" and args.size() == 3:
            players[args[1]].update_input(args[2])
        elif args[0] == "respawnPlayer":
            pass
    
func ws_client_send_packet(content: String) -> void:
    var packet = content.to_utf8()

    ws_client.get_peer(1).put_packet(packet)

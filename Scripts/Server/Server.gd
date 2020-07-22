extends Control

# World properties 
var default_map_path : String = "res://Maps/1.json"
var loaded_maps : Array = []
var current_map_base_64 : String = ""

# Server properties
var can_spawn_client_player : bool = true
var client_player_name : String = "Player0"
var server_port : int = 9080
var ws_server : WebSocketServer = WebSocketServer.new()
const server_admin_password : String = "ablacadabla"

# Debug properties
var server_debug_enabled : bool = false

# Server connections
var connections = {}

# Packet regex
var packet_regex = RegEx.new()

func _ready():
	# Get properties from define
	client_player_name = Defines.player_name

	# Connect websocket server signals
	ws_server.connect("client_connected", self, "_ws_server_new_connection")
	ws_server.connect("client_disconnected", self, "_ws_server_new_disconnection")
	ws_server.connect("client_close_request", self, "_ws_server_close_request")
	ws_server.connect("data_received", self, "_ws_server_on_data")

	# Create the websocket server
	print("[Server: ready] Creating new websocket server, port: %d" % [server_port])

	var ws_server_error = ws_server.listen(server_port)

	if ws_server_error != OK:
		set_process(false)
		print("[Server: ready] Could not create the websocket server on port %d" % [server_port])
	else:
		print("[Server: ready] WebSocket server is ready!")

	# Add client player if isn't godot-server instance
	if OS.get_name() != "Server":
		connections[0] = {
			"player_scene": $World.new_player(client_player_name, true),
			"is_player": true,
			"is_admin": true,
			"proto": false,
			"is_server": true
		}
		Defines.have_player_client = true
	
	# Load the default map
	var file_handler : File = File.new()

	if file_handler.open(default_map_path, File.READ) == OK:
		var map_json : String = file_handler.get_as_text()

		$World.new_game(map_json)
		current_map_base_64 = Marshalls.utf8_to_base64(map_json)
	else:
		print("[Server - World: ready] Could not load map on default map path")
	
	# Compile packet regex
	packet_regex.compile("[^\\s]+")

func _process(_delta):
	ws_server.poll()

func _ws_server_new_connection(id, proto) -> void:
	print("[Server: ws_server_new_connection] New websocket connection! Details [id, proto]: %d, %s" % [id, proto])

	connections[id] = {
		"player_scene": false,
		"is_player": false,
		"is_admin": false,
		"is_server": false,
		"proto": proto,
	}

func _ws_server_new_disconnection(id, was_clean = false) -> void:
	print("[Server: ws_server_new_connection] New websocket disconnection! Details [id, was_clean]: %d, %s" % [id, str(was_clean)])

	connections.erase(id)

func _ws_server_close_request(_id, _code, _reason) -> void:
	pass

func _ws_server_on_data(id) -> void:
	# Get packet data
	var packet_data = ws_server.get_peer(id).get_packet()
	var packet_string = packet_data.get_string_from_utf8()
	var regex_search = packet_regex.search_all(packet_string)

	# Print packet data if debug is enabled
	if server_debug_enabled:
		print("[Server: _ws_server_on_data] Receveid from %d: %s" % [id, packet_string])

	# Handle packet

	if regex_search.size() > 0:		
		var args : Array = []
				
		for search in regex_search:
			args.append(search.get_string())
		
		if args[0] == "playerConnection" and args.size() == 2 and not connections[id].is_player:
			var player_name = args[1]

			# Add new player to the server
			var player_instance = $World.new_player(player_name, false)

			connections[id].is_player = true
			connections[id].player_scene = player_instance

			# Send the current map
			ws_server_send_packet(id, "receiveMap %s" % [current_map_base_64])

			# Send all players
			for connection_id in connections:
				if connections[connection_id].is_player and connection_id != id:
					ws_server_send_packet(id, "newPlayer %s %s %d %d" % [str(connection_id), connections[id].player_scene.player_name, connections[id].player_scene.get_node("RigidBody2D").position.x, connections[id].player_scene.get_node("RigidBody2D").position.y])
			
		elif args[0] == "serverPassword" and args.size() == 2:
			var password_entered = args[1]

			if password_entered == server_admin_password:
				connections[id].is_admin = true

		
		# Accept above packets only if it's a player connection
		if connections[id].is_player:
			if args[0] == "validInput" and args.size() == 2:
				var action = args[1]

				connections[id].player_scene.update_input(action)
				ws_server_broadcast("validInput %d %s" % [id, action], id)
			elif args[0] == "message" and args.size() > 1:
				pass
		
		# Accept above packets only if it's a admin connection
		if connections[id].is_admin:
			if args[0] == "sendMap" and args.size() == 2:
				pass
			elif args[0] == "kick" and args.size() == 2:
				pass
			elif args[0] == "getIds" and args.size() == 2:
				pass
			elif args[0] == "playVideo" and args.size() == 2:
				pass

func ws_server_send_packet(id, content: String) -> void:
	var packet = content.to_utf8()

	ws_server.get_peer(id).put_packet(packet)

func ws_server_broadcast(content: String, dont_send_to = -1) -> void:
	var packet = content.to_utf8()

	for id in connections:
		if not connections[id].is_server and dont_send_to != id:
			ws_server.get_peer(id).put_packet(packet)

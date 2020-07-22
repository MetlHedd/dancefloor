extends Control

var own_player

# Ground change timer
var ground_change_time_left : int = 10

func _ready():
    # Update UI
    $UI.update_player_list()

    # If is the network server
    if get_tree().has_network_peer() and get_tree().is_network_server():
        $GroundChangeTimer.connect("timeout", self, "_change_ground_timeout")
    
    # Send current map to the world
    if get_tree().has_network_peer() and get_tree().is_network_server():
        _init_player()
        Network.init_new_game()

func _init_player():
    # Creates the local player
    own_player = $World.new_player(get_tree().get_network_unique_id(), Network.self_data.name, Network.self_data.skin, Network.self_data.position, Network.self_data.is_alive)
    own_player.z_index = 2

func _on_player_join(player_id, player_info) -> void:
    $World.new_player(player_id, player_info.name, player_info.skin, player_info.position, player_info.is_alive)
    
    $UI.update_player_list()

func _on_player_left(player_id) -> void:
    $World.players[player_id].queue_free()
    $World.players.erase(player_id)
    $UI.update_player_list()

func _change_ground_timeout():
    ground_change_time_left -= 1

    if ground_change_time_left >= 1 and ground_change_time_left <= 3:
        rpc("_set_round_text", "%d..." % [ground_change_time_left])
    elif ground_change_time_left == 0:
        rpc("_set_round_text", "Now!")
    else:
        rpc("_set_round_text", "Wait!")

    if ground_change_time_left == 0:
        rpc("_grounds_will_change")
        
        for ground in range($World.current_map.grounds.size()):
            var random_picked_ground_type = Defines.grounds_types_availables[randi() % Defines.grounds_types_availables.size()]

            rpc("_on_ground_change", random_picked_ground_type, Vector2($World.current_map.grounds[ground].position.x, $World.current_map.grounds[ground].position.y) , Vector2($World.current_map.grounds[ground].size.x, $World.current_map.grounds[ground].size.y))

        ground_change_time_left = 5

remotesync func _set_round_text(text : String) -> void:
    $UI/GameTime.text = text

remotesync func new_game_started(map_json) -> void:
    ground_change_time_left = 10   
    
    if get_tree().is_network_server():
        $GroundChangeTimer.start()
    
    # Add the grounds to the map
    for ground in $World.current_map_scenes.grounds:
        if ground:
            ground.queue_free()
    
    $World.current_map_scenes.grounds = []

    for ground in map_json.grounds:
        $World.add_ground(ground.type, Vector2(ground.position.x, ground.position.y), Vector2(ground.size.x, ground.size.y))
    
    # Respawn players
    for id in $World.players:
        var player_scene = $World.players[id]
        
        player_scene.visible = true
        player_scene.get_node("RigidBody2D").global_position = Vector2(map_json.playerSpawnPosition.x, map_json.playerSpawnPosition.y)
        player_scene.is_alive = true

remotesync func _grounds_will_change() -> void:
    for ground in $World.current_map_scenes.grounds:
        if ground:
            ground.queue_free()
    
    $World.current_map_scenes.grounds = []

remotesync func _on_ground_change(ground_type, ground_position, ground_size) -> void:
    $World.add_ground(ground_type, ground_position, ground_size)

extends Node2D

# Players in the current world
var players : Dictionary = {}

# Scenes to be loaded
onready var player_scene = preload("res://Scenes/Game/Player.tscn")
var grounds_scenes = {}

# Current map properties
var current_map : Dictionary = {}
var current_map_scenes = {
    "grounds": []
}

func _ready():
    for type in Defines.grounds_types_availables:
        grounds_scenes[type] = load("res://Scenes/Game/Grounds/" + type + "Ground.tscn")

func new_player(id : int, player_name : String, skin : String, palette : String, position = Vector2(0, 0), is_alive = false):
    var player_instance = player_scene.instance()
    
    # Change player initial properties
    player_instance.is_alive = is_alive
    player_instance.player_name = player_name
    player_instance.set_network_master(id)
    player_instance.player_id = id
    player_instance.player_skin = skin
    player_instance.player_palette = palette
    
    # Add player to the scene
    $".".add_child(player_instance)
    player_instance.get_node("RigidBody2D").global_position = position
    player_instance.name = str(id)

    if not is_alive:
        player_instance.visible = false

    # Save player instance
    players[id] = player_instance
    
    return player_instance

func add_ground(type: String, position: Vector2, size: Vector2, add_on_position = -1) -> void:
    var ground_instance = grounds_scenes[type].instance()
    
    ground_instance.position = position
    ground_instance.scale.x = size.x / 64.0
    ground_instance.scale.y = size.y / 32.0

    if add_on_position == -1:
        current_map_scenes.grounds.append(ground_instance)
    elif current_map_scenes.grounds[add_on_position]:
            current_map_scenes.grounds[add_on_position].queue_free()
            current_map_scenes.grounds[add_on_position] = ground_instance

    $".".add_child(ground_instance)

func load_map(map_string : String) -> Dictionary:
    # Load the map json
    var map_json = JSON.parse(map_string)

    if map_json.error == OK:
        current_map = map_json.result
    
    return current_map
        
func change_ground(ground_id : int, new_ground_type : String, have_new_size = false, new_size = Vector2(0, 0)) -> void:
    if not have_new_size:
        add_ground(new_ground_type, current_map.grounds[ground_id].position, current_map.grounds[ground_id].size, ground_id)
    else:
        add_ground(new_ground_type, current_map.grounds[ground_id].position, new_size, ground_id)

remote func _request_map_informations(requester_id) -> void:
    if get_tree().is_network_server():
        rpc_id(requester_id, "_receveid_map_information", current_map)

remote func _receveid_map_information(map_information : Dictionary) -> void:
    for ground in map_information.grounds:
        add_ground(ground.type, Vector2(ground.position.x, ground.position.y), Vector2(ground.size.x, ground.size.y))
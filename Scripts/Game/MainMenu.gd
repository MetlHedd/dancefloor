extends Control

var server_scene_path = "res://Scenes/Game/Server.tscn"
var client_scene_path : String = "res://Scenes/Game/Client.tscn"
var game_scene_path : String = "res://Scenes/Game/Game.tscn"

func _ready():
    # Reset network peer
    get_tree().set_network_peer(null)

    # Connect signals
    $Menu/JoinButton.connect("pressed", self, "show_join_menu")
    $Menu/HostButton.connect("pressed", self, "show_host_menu")

    $HostMenu/CreateServerButton.connect("pressed", self, "host_server")
    $JoinMenu/JoinServerButton.connect("pressed", self, "join_server")

    if Defines.has_main_menu_error_message:
        Defines.has_main_menu_error_message = false
        $AcceptDialog.dialog_text = Defines.main_menu_error_message
        $AcceptDialog.popup_centered()

func show_main_menu():
    $Menu.visible = true
    $HostMenu.visible = false
    $JoinMenu.visible = false

func show_join_menu():
    $Menu.visible = false
    $HostMenu.visible = false
    $JoinMenu.visible = true

func show_host_menu():
    $Menu.visible = false
    $HostMenu.visible = true
    $JoinMenu.visible = false

func host_server():
    Network.create_server($Menu/PlayerName.text, $HostMenu/ServerPort.value)
    get_tree().change_scene(game_scene_path)

func join_server():
    Network.connect_to_server($Menu/PlayerName.text, $JoinMenu/LineEdit.text, $JoinMenu/ServerPort.value)
    get_tree().change_scene(game_scene_path)

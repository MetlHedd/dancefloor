extends Control

var server_scene_path = "res://Scenes/Game/Server.tscn"
var client_scene_path : String = "res://Scenes/Game/Client.tscn"
var game_scene_path : String = "res://Scenes/Game/Game.tscn"

func _ready() -> void:
	# Reset network peer
	get_tree().set_network_peer(null)

	# Connect signals
	$Menu/JoinButton.connect("pressed", self, "show_join_menu")
	$Menu/HostButton.connect("pressed", self, "show_host_menu")

	$HostMenu/CreateServerButton.connect("pressed", self, "host_server")
	$JoinMenu/JoinServerButton.connect("pressed", self, "join_server")

	$Menu/SkinButton.connect("pressed", self, "show_skin_selector")

	# Check if Main Menu needs to show an error message
	if Defines.has_main_menu_error_message:
		Defines.has_main_menu_error_message = false
		$AcceptDialog.dialog_text = Defines.main_menu_error_message
		$AcceptDialog.popup_centered()

# Show main menu
func show_main_menu() -> void:
	$Menu.visible = true
	$HostMenu.visible = false
	$JoinMenu.visible = false

# Show the join server menu
func show_join_menu() -> void:
	$Menu.visible = false
	$HostMenu.visible = false
	$JoinMenu.visible = true

# Show the host server menu
func show_host_menu() -> void:
	$Menu.visible = false
	$HostMenu.visible = true
	$JoinMenu.visible = false

# Go to game and create a server
func host_server() -> void:
	Network.create_server($Menu/PlayerName.text, $HostMenu/ServerPort.value)
	get_tree().change_scene(game_scene_path)

# Go to game and join the specified server
func join_server() -> void:
	Network.connect_to_server($Menu/PlayerName.text, $JoinMenu/ServerIP.text, $JoinMenu/ServerPort.value)
	get_tree().change_scene(game_scene_path)


func show_skin_selector() -> void:
	$SkinSelector.popup_centered()

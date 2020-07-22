extends Control

# Scenes
var main_menu_scene_path : String = "res://Scenes/Game/MainMenu.tscn"

func _ready() -> void:
	# Connect signals
	# Chat
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.connect("focus_entered", self, "_focus_on_line_edit")
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.connect("focus_exited", self, "_focus_exited_on_line_edit")
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.connect("text_entered", self, "send_chat_message")
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/SendButton.connect("pressed", self, "send_chat_message", [null])

	# Options
	$Panel/HBoxContainer/Options/Content/ScrollContainer/VBoxContainer/BackToMainMenu.connect("pressed", self, "back_to_main_menu")

func new_chat_message(player_id : int, player_color : String, message : String, enable_bbcode = false) -> void:
	if enable_bbcode:
		$Panel/HBoxContainer/Chat/Content/Chat.bbcode_text += "\n[img]res://Assets/Sprites/Player/Skins/%s/skin.png[/img] [b][color=%s]%s:[/color][/b] %s" % [Network.players[player_id].skin, player_color, Network.players[player_id].name, message]
	else:
		message = message.replace("[", "n")
		message = message.replace("\\", "\\/")
		message = message.replace("]", "n")

		$Panel/HBoxContainer/Chat/Content/Chat.bbcode_text += "\n[img]res://Assets/Sprites/Player/Skins/%s/skin.png[/img] [b][color=%s]%s:[/color][/b] %s" % [Network.players[player_id].skin, player_color, Network.players[player_id].name, message]

func new_system_message(message : String) -> void:
	$Panel/HBoxContainer/VBoxContainer/Chat.bbcode_text += "\n%s" % [message]

func update_player_list() -> void:
	$Panel/HBoxContainer/Players/Content/List.text = ""
	
	for id in Network.players:
		$Panel/HBoxContainer/Players/Content/List.text += "%s\n" % [Network.players[id].name]

func _focus_on_line_edit():
	Defines.focus_on_line_edit = true

func _focus_exited_on_line_edit():
	Defines.focus_on_line_edit = false

func send_chat_message(_new_text):
	# Get the chat message to be sent
	var text = $Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.text

	rpc("_new_chat_message", get_tree().get_network_unique_id(), text, get_tree().is_network_server())

	# Reset the text
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.text = ""

func back_to_main_menu():
	get_tree().set_network_peer(null)
	get_tree().change_scene(main_menu_scene_path)

remotesync func _new_chat_message(player_id, message : String, is_server : bool) -> void:
	if message.length() > 0 and message.length() < 200:
		if is_server:
			new_chat_message(player_id, "#fff240", message, true)
		else:
			new_chat_message(player_id, "#b3dfff", message, false)

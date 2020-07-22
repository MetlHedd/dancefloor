extends Control

func _ready() -> void:
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.connect("focus_entered", self, "_focus_on_line_edit")
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.connect("focus_exited", self, "_focus_exited_on_line_edit")
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.connect("text_entered", self, "send_chat_message")
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/SendButton.connect("pressed", self, "send_chat_message")

func new_chat_message(player_name : String, player_color : String, message : String, enable_bbcode = false) -> void:
	if enable_bbcode:
		$Panel/HBoxContainer/Chat/Content/Chat.bbcode_text += "\n[img]res://Assets/Sprites/Grounds/player.png[/img][b][color=%s]%s:[/color][/b] %s" % [player_color, player_name, message]
	else:
		message = message.replace("[", "n")
		message = message.replace("\\", "\\/")
		message = message.replace("]", "n")

		$Panel/HBoxContainer/Chat/Content/Chat.bbcode_text += "\n[img]res://Assets/Sprites/Grounds/player.png[/img][b][color=%s]%s:[/color][/b] %s" % [player_color, player_name, message]

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

func send_chat_message():
	# Get the chat message to be sent
	var text = $Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.text

	rpc("_new_chat_message", get_tree().get_network_unique_id(), text, get_tree().is_network_server())

	# Reset the text
	$Panel/HBoxContainer/Chat/Content/HBoxContainer2/Message.text = ""

remotesync func _new_chat_message(player_id, message : String, is_server : bool) -> void:
	if message.length() > 0 and message.length() < 200:
		if is_server:
			new_chat_message(Network.get_player_name_by_id(player_id), "#fff240", message, true)
		else:
			new_chat_message(Network.get_player_name_by_id(player_id), "#b3dfff", message, false)

extends Control

const skins_directory_path : String = "res://Assets/Sprites/Player/Skins/"
onready var skin_visualizer_scene = preload("res://Scenes/UI/SkinVisualizer.tscn")

func _ready():
	# Reset defines
	Defines.avalaible_skins = []

	# Connect signals
	$Buttons/HBoxContainer/Back.connect("pressed", self, "close_popup")

	# Check all available skins
	var skin_directory : Directory = Directory.new()

	if skin_directory.open(skins_directory_path) == OK:
		skin_directory.list_dir_begin(true, true)

		var folder_name = skin_directory.get_next()

		while folder_name != "":
			if skin_directory.current_is_dir():
				var skin_visualizer_instance = skin_visualizer_scene.instance()
				skin_visualizer_instance.skin_name = folder_name

				# Add to the scene and connect pressed signal
				$ContentBG/Grid.add_child(skin_visualizer_instance)
				skin_visualizer_instance.get_node("Button").connect("pressed", self, "select_skin", [folder_name])
				
				Defines.avalaible_skins.append(folder_name)

			folder_name = skin_directory.get_next()
	else:
		print("An error occurred when trying to access skins path.")


func select_skin(skin_name : String):
	Defines.selected_skin = skin_name

func close_popup():
	hide()

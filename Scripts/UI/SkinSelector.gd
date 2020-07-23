extends Control

const skins_directory_path : String = "res://Assets/Sprites/Player/Skins"
onready var skin_visualizer_scene = preload("res://Scenes/UI/SkinVisualizer.tscn")

func _ready():
	# Connect signals
	$Buttons/HBoxContainer/Back.connect("pressed", self, "close_popup")

	# Check all available skins
	for skin_name in Defines.avalaible_skins:
		for palette_name in Defines.avalaible_skins[skin_name]:
			var skin_visualizer_instance = skin_visualizer_scene.instance()
							
			# Set skin properties
			skin_visualizer_instance.skin_name = skin_name
			skin_visualizer_instance.skin_palette = palette_name

			# Add to the scene and connect pressed signal
			$ContentBG/Grid.add_child(skin_visualizer_instance)
			if skin_visualizer_instance:
				skin_visualizer_instance.get_node("Button").connect("pressed", self, "select_skin", [skin_name, palette_name])


func select_skin(skin_name : String, palette : String):
	Defines.selected_skin = skin_name
	Defines.selected_palette = palette

func close_popup():
	hide()

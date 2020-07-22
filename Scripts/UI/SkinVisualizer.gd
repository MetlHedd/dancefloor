extends Control

export var skin_name : String = "Cat"

func _ready():
	var skin_scene = load("res://Assets/Sprites/Player/Skins/%s/skin.png" % [skin_name])

	$Button/Name.text = skin_name
	$Button/SkinImage.set_texture(skin_scene)

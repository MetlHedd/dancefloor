extends Control

export var skin_name : String = "Cat"
export var skin_palette : String = "Brown"

func _ready():
	var skin_scene = load("res://Assets/Sprites/Player/Skins/%s/skin-r.png" % [skin_name])
	var palette = load("res://Assets/Sprites/Player/Skins/%s/Palettes/%s.png" % [skin_name, skin_palette])
	
	#
	if skin_scene == null or palette == null:
		queue_free()
		print(skin_palette)
	else:
		# Set properties
		$Button/Name.text = skin_name
		$Button/SkinImage.set_texture(skin_scene)
		
		# Set palette
		var material = $Button/SkinImage.material.duplicate();
		material.set_shader_param("palette", palette)
	
		$Button/SkinImage.material = material;

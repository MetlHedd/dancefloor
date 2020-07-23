extends Node

# Grounds

# Grounds avalaibles
var grounds_types_availables : Array = ["Wood", "Trampoline", "Ice", "Cloud"]

# Skins

# Skins path
const skins_directory_path : String = "res://Assets/Sprites/Player/Skins"
# Dict of skins found on skins_directory_path
var avalaible_skins : Dictionary = {}


# Client properperties

# If client is currently with focus on line edit (to send message)
var focus_on_line_edit : bool = false
# Selected skin
var selected_skin : String = "Cat"
# Selected palette
var selected_palette : String = "Default"

# MainMenu Properties

# If main menu has an error message
var has_main_menu_error_message : bool = false
# Main menu error message
var main_menu_error_message : String = ""

# Functions

# Skins

# Find all skins on skins_directory_path
func find_all_skins() -> void:
    # Regex to only get skin name
    var regex = RegEx.new()

    regex.compile("[^\\.]+")

    # Check all available skins
    var skin_directory : Directory = Directory.new()

    # Check skins by name
    if skin_directory.open(skins_directory_path) == OK:
        skin_directory.list_dir_begin(true, true)

        var skin_name = skin_directory.get_next()

        while skin_name != "":
            if skin_directory.current_is_dir():
                # Get regex skin_name

                var result_skin = regex.search(skin_name)

                # Get all palettes
                var palettes : Directory = Directory.new()
                
                if result_skin and palettes.open("%s/%s/Palettes" % [skins_directory_path, result_skin.get_string()]) == OK:
                    palettes.list_dir_begin(true, true)

                    var palette_name = palettes.get_next()

                    while palette_name != "":
                        var result_palette = regex.search(palette_name)

                        if result_palette and not palettes.current_is_dir():
                            register_skin(result_skin.get_string(), result_palette.get_string())
                            
                        palette_name = palettes.get_next()

            skin_name = skin_directory.get_next()
    else:
        print("An error occurred when trying to access skins path.")

func register_skin(skin_name : String, skin_palette : String) -> void:
    if not skin_name in avalaible_skins:
        avalaible_skins[skin_name] = []
    
    if not skin_palette in avalaible_skins[skin_name]:
        avalaible_skins[skin_name].append(skin_palette)

# Virtual

# When scene is ready
func _ready() -> void:
    find_all_skins()
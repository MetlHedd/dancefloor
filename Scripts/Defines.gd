extends Node

var grounds_types_availables : Array = ["Wood", "Trampoline", "Ice", "Cloud"]
var avalaible_skins : Array = []

# Client properties
var focus_on_line_edit : bool = false
var selected_skin : String = "Cat"

# MainMenu Properties
var has_main_menu_error_message : bool = false
var main_menu_error_message : String = ""
extends Node2D

# Movement properties
const Direction = {
    "ZERO": Vector2(0, 0),
    "LEFT": Vector2(-1, 0),
    "RIGHT": Vector2(1, 0),
    "UP": Vector2(0, -1),
    "DOWN": Vector2(0, 1)
}
puppet var directional_force : Vector2 = Vector2(0, 0)

# Player properties
var is_alive : bool = false
var player_name : String = "PlayerNameAAAAAAAAAAAAA"

# Collision propertions
var is_grounded : bool = false
var is_side_collided : bool = false

# Server and client properties
var player_id : int = 0
var player_skin : String = "Cat"

# Position error treeshold
const position_error_treeshold : float = 25.0

func _ready():
    # Connect signals
    $RigidBody2D/Area2D.connect("body_entered", self, "_area2d_body_entered")
    $RigidBody2D/Area2D.connect("body_exited", self, "_area2d_body_exited")
    $RigidBody2D/LeftCol.connect("body_entered", self, "_body_entered_sides_collision")
    $RigidBody2D/LeftCol.connect("body_exited", self, "_body_exited_sides_collision")
    $RigidBody2D/RightCol.connect("body_entered", self, "_body_entered_sides_collision")
    $RigidBody2D/RightCol.connect("body_exited", self, "_body_exited_sides_collision")
    
    # Change player name (on label)
    $RigidBody2D/LabelPlayerName.text = player_name
    
    # Set network master
    set_network_master(player_id)

    # Set player skin
    if player_skin in Defines.avalaible_skins:
        $RigidBody2D/Sprite.set_texture(load("res://Assets/Sprites/Player/Skins/%s/skin-r.png" % [player_skin]))

func update_input() -> void:
    if not is_alive:
        visible = false
    
    if get_tree().has_network_peer() and get_tree().is_network_server() and is_alive:
        Network.update_position(player_id, $RigidBody2D.global_position)

        if $RigidBody2D.global_position.y > 350:
            Network.players_alive -= 1
            is_alive = false

    if get_tree().has_network_peer() and is_network_master() and is_alive:
        if not Defines.focus_on_line_edit:
            if Input.is_action_pressed("move_left") and not is_side_collided:
                directional_force += Direction.LEFT
                
            if Input.is_action_pressed("move_right") and not is_side_collided:
                directional_force += Direction.RIGHT

            # Jump movement
            if Input.is_action_pressed("move_up") and (is_grounded or is_side_collided):
                directional_force += Direction.UP
                is_grounded = false
    
        
        rset("directional_force", directional_force)
        rpc("fix_position", $RigidBody2D.global_position)

func reset_direction_force():
    directional_force = Direction.ZERO
    rset("directional_force", directional_force)

func _area2d_body_entered(body) -> void:
    if get_tree().has_network_peer() and is_network_master() and body.get_physics_material_override().bounce < 0.2:
        is_grounded = true

func _area2d_body_exited(_body) -> void:
    if get_tree().has_network_peer() and is_network_master() and is_alive and is_network_master():
        is_grounded = false

func _body_entered_sides_collision(body) -> void:
    if get_tree().has_network_peer() and is_network_master() and is_alive and body.get_physics_material_override().friction > 0.2 and body.get_physics_material_override().bounce < 0.2 and is_network_master():
            is_side_collided = true

func _body_exited_sides_collision(body) -> void:
    if get_tree().has_network_peer() and is_network_master() and is_alive and body.get_physics_material_override().friction > 0.2 and body.get_physics_material_override().bounce < 0.2 and is_network_master():
            is_side_collided = false

remote func fix_position(position: Vector2) -> void:
    if abs($RigidBody2D.global_position.x - position.x) <= position_error_treeshold:
        $RigidBody2D.global_position.x = position.x
    else:
        # Fix position based on server position
        pass

    if abs($RigidBody2D.global_position.y - position.y) <= position_error_treeshold:
        $RigidBody2D.global_position.y = position.y
    else:
        # Fix position based on server position
        pass
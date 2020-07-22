extends RigidBody2D

const Direction = {
    "ZERO": Vector2(0, 0),
    "LEFT": Vector2(-1, 0),
    "RIGHT": Vector2(1, 0),
    "UP": Vector2(0, -1),
    "DOWN": Vector2(0, 1)
}

# Movement properties
const acceleration : float = 1000.0
const move_speed : float = 225.0
const jump_speed : float = 250.0
const max_top_speed : float = 1000.0

func _integrate_forces(state):
    var velocity : Vector2 = Vector2(0, 0)

    if is_network_master():
        get_parent().reset_direction_force()
        
    get_parent().update_input()
    
    # Get movement velocity
    velocity = get_parent().directional_force * acceleration

    velocity.y = clamp(velocity.y, -jump_speed, jump_speed)

    var final_velocity : Vector2 = state.get_linear_velocity() + velocity
    
    final_velocity.x = clamp(final_velocity.x, -move_speed, move_speed)

    if not get_parent().is_side_collided:
        final_velocity.y = clamp(final_velocity.y, -max_top_speed, max_top_speed)
    elif get_parent().is_side_collided and not get_parent().is_grounded:
        final_velocity.y = clamp(final_velocity.y, -jump_speed, jump_speed)

    # Add the new velocity to the state
    state.set_linear_velocity(final_velocity)

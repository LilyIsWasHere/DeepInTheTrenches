class_name WeightedAgentConfig
extends NavAgentConfig



@export var upwards_slope_weight: float
@export  var downwards_slope_weight: float
@export var terrain_delta_weight: float
@export var desired_terrain_delta: float 


#"height": terrain_data["height"],
#"initial_height": terrain_data["initial_height"],
#"slope_x": slope_x,
#"slope_z": slope_z,
#"slope_degrees": slope_degrees
		
func get_nav_cost(context: Dictionary, move_context: NavMoveContext) -> float:
	var delta: Vector2i = move_context.to_cell - move_context.from_cell
	var is_diagonal: bool = abs(delta.x) == 1 and abs(delta.y) == 1
	var base_cost: float = 1.41421356 if is_diagonal else 1.0

	var score_layers: Dictionary = context.get("score_layers", {})
	var terrain_layer: Dictionary = score_layers.get(&"terrain", {})
	var terrain_score: float = float(terrain_layer.get(move_context.to_cell, 0.0))
	
	var terrain_delta: float = move_context.to_data.height - move_context.to_data.initial_height
	var terrain_delta_diff: float = max(terrain_delta - desired_terrain_delta, 0)
	var terrain_delta_score: float = terrain_delta_diff * terrain_delta_weight
	base_cost += terrain_delta_score
	
	
	return base_cost
	
	

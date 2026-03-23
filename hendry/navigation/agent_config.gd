# The resource that holds the configuration for the agent, as well as a cost function for the pathfinding algorithm to use.

extends Resource
class_name NavAgentConfig

@export var radius: float = 0.2
@export var height: float = 1.7
@export var max_speed: float = 5.0
@export var max_slope_degrees: float = 45.0
@export var max_step_height: float = 1.0
@export var wall_climb_height: float = 1.7

# Override this to get any data you want, 'cuz you ain't getting any more when threads start
func init_context(agent: Node) -> Dictionary:
	var context: Dictionary = {}

	if agent != null and "team" in agent:
		var player_id: int = agent.team
		context["player_id"] = player_id
		var score_layers: Dictionary = {}
		score_layers[&"terrain"] = Navigation.get_player_score_layer(player_id, &"terrain")
		context["score_layers"] = score_layers

	return context

# Override this, remember that this will run in a thread
func get_nav_cost(context: Dictionary, move_context: Dictionary) -> float:
	var from_cell: Vector2i = move_context["from_cell"]
	var to_cell: Vector2i = move_context["to_cell"]
	var delta: Vector2i = to_cell - from_cell
	var is_diagonal: bool = abs(delta.x) == 1 and abs(delta.y) == 1
	var base_cost: float = 1.41421356 if is_diagonal else 1.0
	return base_cost

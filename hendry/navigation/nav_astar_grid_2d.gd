extends AStarGrid2D
class_name NavAStarGrid2D

# use nav_map's cost function, which uses agent_config's cost function
var compute_cost_fn: Callable = Callable()
func _compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
	if compute_cost_fn.is_null():
		return INF

	return float(compute_cost_fn.call(from_id, to_id))

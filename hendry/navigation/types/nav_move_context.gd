# type for agent-dependent move context from one cell to another

extends RefCounted
class_name NavMoveContext

var from_cell: Vector2i = Vector2i.ZERO
var to_cell: Vector2i = Vector2i.ZERO
var from_data: NavCellData = null
var to_data: NavCellData = null

var edge_max_slope_degrees: float = INF

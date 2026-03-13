extends Object
class_name GameSingleton

# Array[Array[Unit]], idx 0, 1 for player 0, 1
var Units: Array[Array]

func get_player_units(idx: int) -> Array[Unit]:
	return Units[idx]

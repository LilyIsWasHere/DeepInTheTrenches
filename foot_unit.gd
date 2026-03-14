extends Unit

@export var weapon : Weapon

func move_to_point(point : Vector3) -> void:
	targetPos = point

func shoot_at_point(point : Vector3) -> void:
	weapon.shoot(point)

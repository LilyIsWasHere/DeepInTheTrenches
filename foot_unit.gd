extends MoveableUnit
class_name FootUnit

@export var weapon : Weapon

func shoot_at_point(point : Vector3) -> void:
	weapon.shoot(point)

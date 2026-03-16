extends MoveableUnit
class_name FootUnit

@export var weapon : Weapon

func _ready() -> void:
	super()
	add_to_group("can_attack")
	#uncomment this vvv when we get troops digging working
	#add_to_group("can_dig")

func shoot_at_point(point : Vector3) -> void:
	weapon.shoot(point)

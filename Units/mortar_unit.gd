extends Unit

@export var weapon : Weapon

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	add_to_group("can_attack")

func shoot_at_point(point : Vector3) -> void:
	weapon.shoot(point)

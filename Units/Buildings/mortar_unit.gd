extends BuildingUnit

@export var weapon : ArtilleryWeapon

var target: Vector3 = Vector3(10, 10, 10)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	add_to_group("can_attack")
	weapon.owning_player = GlobalPlayerManager.get_player(team)

func shoot_at_point(point : Vector3) -> void:
	weapon.shoot(point)
	
	
func _process(_delta: float) -> void:
	super(_delta)
	
	weapon.shoot(target)

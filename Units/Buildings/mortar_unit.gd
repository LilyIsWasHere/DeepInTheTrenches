extends BuildingUnit

@export var weapon : ArtilleryWeapon
@export var workstation : Workstation
var isTargeting : bool = false

var target: Vector3 = Vector3(10, 10, 10)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	add_to_group("can_attack")
	weapon.owning_player = GlobalPlayerManager.get_player(team)
	if team == 0:
		weapon.set_targ_pos_colour(Color.BLUE)
	else:
		weapon.set_targ_pos_colour(Color.RED)

func set_target_visible(isVisible : bool) -> void:
	weapon.set_target_pos_visibility(isVisible)

func shoot_at_point(point : Vector3) -> void:
	if isTargeting:
		#don't shoot while targeting
		return
	
	weapon.shoot(point)

func set_target(targetPos : Vector3) -> void:
	target = targetPos
	weapon.fixed_target = target

func _process(_delta: float) -> void:
	super(_delta)
	
	if workstation.is_occupied():
		shoot_at_point(target)
	
	if selectedArrow.visible:
		set_target_visible(true)
	else:
		set_target_visible(false)

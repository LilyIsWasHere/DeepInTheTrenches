extends Node3D

var start_position : Vector3
var target_position : Vector3
var direction : Vector3
var gun_range : float
var target_area : float
var damage : float
var speed : float = 20.0
var own_unit : Unit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# move bullet
	translate(direction * speed * delta)
	
	# should make the bullet die if it has moved further than it's range
	if $Area3D.global_position.distance_to(start_position) >= gun_range:
		queue_free()
	
func shoot(start : Vector3, target : Vector3, area : float, range : float, dmg : float, me : Unit) -> void:
	start_position = start
	target_position = target
	target_area = area
	gun_range = range
	damage = dmg
	
	own_unit = me
	
	direction = (target_position - start_position).normalized()
	global_position = start_position

func _on_area_3d_body_entered(body: Node3D) -> void:
	var targetUnit : Node = body
	
	while targetUnit != null and !(targetUnit is Unit):
		targetUnit = targetUnit.get_parent()
	
	if targetUnit == null:
		return

	if target_area > 1.0:
		pass
		# find all targets and deal damage to each
	else:
		if targetUnit.has_method("deal_damage") and targetUnit != own_unit:
			targetUnit.deal_damage(damage)
			print("i touched someone")
	queue_free()

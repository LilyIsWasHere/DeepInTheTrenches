extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_animation(name: String) -> void:
	if name == "idle":
		$Animations.play('idle')
	elif name == "shoot":
		$Animations.play("shoot")
	elif name == "walk":
		$Animations.play("walk")

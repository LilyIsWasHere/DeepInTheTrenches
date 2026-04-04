extends DirectionalLight3D

func _ready() -> void:
	_apply_shadow_setting(GameSettings.shadows_enabled)
	GameSettings.shadows_changed.connect(_apply_shadow_setting)

func _apply_shadow_setting(enabled: bool) -> void:
	shadow_enabled = enabled

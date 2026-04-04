extends Control

func _on_shadows_toggle_button_toggled(toggled_on: bool) -> void:
	GameSettings.set_shadows_enabled(toggled_on)
extends Control

# set the UI elements to match the current settings
func _ready() -> void:
	%ShadowsToggleButton.button_pressed = GameSettings.graphics["shadows_enabled"]
	%MasterSlider.value = GameSettings.audio["master_volume"] * 100.0
	%SFXSlider.value = GameSettings.audio["sfx_volume"] * 100.0
	%MusicSlider.value = GameSettings.audio["music_volume"] * 100.0

func _on_shadows_toggle_button_toggled(toggled_on: bool) -> void:
	GameSettings.set_shadows_enabled(toggled_on)

func _on_master_slider_value_changed(value: float) -> void:
	GameSettings.set_master_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value)

func _on_music_slider_value_changed(value: float) -> void:
	GameSettings.set_music_volume(value)

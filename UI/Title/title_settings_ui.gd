extends Control

@onready var shadows_toggle_button: Button = %ShadowsToggleButton
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider

# set the UI elements to match the current settings
func _ready() -> void:
	shadows_toggle_button.button_pressed = GameSettings.graphics["shadows_enabled"]
	master_slider.value = GameSettings.audio["master_volume"] * 100.0
	sfx_slider.value = GameSettings.audio["sfx_volume"] * 100.0
	music_slider.value = GameSettings.audio["music_volume"] * 100.0

func _on_shadows_toggle_button_toggled(toggled_on: bool) -> void:
	GameSettings.set_shadows_enabled(toggled_on)

func _on_master_slider_value_changed(value: float) -> void:
	GameSettings.set_master_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value)

func _on_music_slider_value_changed(value: float) -> void:
	GameSettings.set_music_volume(value)

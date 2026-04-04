extends Node3D

@export var terrain_rotation_speed: float = 0.1

# panels
@onready var credits_panel: Control = %"TitleCreditsUI"
@onready var settings_panel: Control = %"TitleSettingsUI"

# fancy terrain stuff
@onready var terrain: Terrain = %"Terrain"
@onready var directional_light: DirectionalLight3D = %"DirectionalLight3D"

# buttons
@onready var singleplayer_button: Button = %"SingleplayerButton"
@onready var host_button: Button = %"HostButton"
@onready var join_button: Button = %"JoinButton"
@onready var settings_button: Button = %"SettingsButton"
@onready var credits_button: Button = %"CreditsButton"

func _process(delta: float) -> void:
	var tile := terrain.get_child(0) as TerrainTile_Class
	if tile == null:
			return

	var scroll := Vector2(Time.get_ticks_msec() * 0.02, 0.0)
	tile.heightmap_mat.set_shader_parameter("offset", scroll)
	tile.get_node("HeightMapGenViewport").render_target_update_mode = SubViewport.UPDATE_ONCE
	
	terrain.rotate_y(terrain_rotation_speed * delta)
	directional_light.rotate_y(terrain_rotation_speed * 4 * delta)

func hide_all_panels() -> void:
	credits_panel.hide()
	settings_panel.hide()

func _on_singleplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://base.tscn")

func _on_settings_button_toggled(toggled_on: bool) -> void:

	if toggled_on:
		settings_panel.show()
	else:
		settings_panel.hide()

func _on_credits_button_toggled(toggled_on: bool) -> void:

	if toggled_on:
		credits_panel.show()
	else:
		credits_panel.hide()

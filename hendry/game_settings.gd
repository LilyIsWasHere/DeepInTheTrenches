# global singleton for dealing with game settings

extends Node

signal shadows_changed(enabled: bool)

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULTS := {
	"graphics": {
		"shadows_enabled": true,
	},
	"audio": {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0,
	},
	"input": {
		# TODO: add input rebind
	},
}

var graphics := DEFAULTS["graphics"].duplicate(true)
var audio := DEFAULTS["audio"].duplicate(true)
var input := DEFAULTS["input"].duplicate(true)

var shadows_enabled: bool = true

func _ready() -> void:
	load_settings()

# this is called from the settings panel when the user toggles the shadows option
func set_shadows_enabled(enabled: bool) -> void:
	if shadows_enabled == enabled:
		return

	shadows_enabled = enabled
	save_settings()
	shadows_changed.emit(enabled)

# this is called from the settings panel when the user changes the volume sliders
func set_master_volume(volume: float) -> void:
	volume /= 100.0
	audio["master_volume"] = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
	save_settings()

func set_sfx_volume(volume: float) -> void:
	volume /= 100.0
	audio["sfx_volume"] = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(volume))
	save_settings()

func set_music_volume(volume: float) -> void:
	volume /= 100.0
	audio["music_volume"] = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(volume))
	save_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return

	for section: String in DEFAULTS.keys():
		var target: Dictionary = get(section)
		for key: String in DEFAULTS[section].keys():
			target[key] = config.get_value(section, key, DEFAULTS[section][key])
	
	# apply the volume settings upon loading
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(audio["master_volume"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(audio["sfx_volume"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(audio["music_volume"]))


func save_settings() -> void:
	var config := ConfigFile.new()

	for section: String in DEFAULTS.keys():
		var source: Dictionary = get(section)
		for key: String in DEFAULTS[section].keys():
			config.set_value(section, key, source[key])

	config.save(SETTINGS_PATH)

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

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return

	for section: String in DEFAULTS.keys():
		var target: Dictionary = get(section)
		for key: String in DEFAULTS[section].keys():
			target[key] = config.get_value(section, key, DEFAULTS[section][key])


func save_settings() -> void:
	var config := ConfigFile.new()

	for section: String in DEFAULTS.keys():
		var source: Dictionary = get(section)
		for key: String in DEFAULTS[section].keys():
			config.set_value(section, key, source[key])

	config.save(SETTINGS_PATH)

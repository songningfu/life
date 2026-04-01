class_name SettingsStore
extends RefCounted

const SETTINGS_PATH := "user://settings.cfg"

const SECTION_AUDIO := "audio"
const SECTION_VIDEO := "video"
const SECTION_GAME := "game"

const KEY_MASTER := "master_volume"
const KEY_BGM := "bgm_volume"
const KEY_SFX := "sfx_volume"
const KEY_RESOLUTION := "resolution"
const KEY_FULLSCREEN := "fullscreen"
const KEY_VSYNC := "vsync"
const KEY_TEXT_SPEED := "text_speed"
const KEY_AUTO_SPEED := "auto_speed"
const KEY_SCHEDULE_TEMPLATE := "schedule_template"

static func load_all() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		return _defaults()

	var d := _defaults()
	d[KEY_MASTER] = float(cfg.get_value(SECTION_AUDIO, KEY_MASTER, d[KEY_MASTER]))
	d[KEY_BGM] = float(cfg.get_value(SECTION_AUDIO, KEY_BGM, d[KEY_BGM]))
	d[KEY_SFX] = float(cfg.get_value(SECTION_AUDIO, KEY_SFX, d[KEY_SFX]))
	d[KEY_RESOLUTION] = str(cfg.get_value(SECTION_VIDEO, KEY_RESOLUTION, d[KEY_RESOLUTION]))
	d[KEY_FULLSCREEN] = bool(cfg.get_value(SECTION_VIDEO, KEY_FULLSCREEN, d[KEY_FULLSCREEN]))
	d[KEY_VSYNC] = bool(cfg.get_value(SECTION_VIDEO, KEY_VSYNC, d[KEY_VSYNC]))
	d[KEY_TEXT_SPEED] = str(cfg.get_value(SECTION_GAME, KEY_TEXT_SPEED, d[KEY_TEXT_SPEED]))
	d[KEY_AUTO_SPEED] = str(cfg.get_value(SECTION_GAME, KEY_AUTO_SPEED, d[KEY_AUTO_SPEED]))
	d[KEY_SCHEDULE_TEMPLATE] = str(cfg.get_value(SECTION_GAME, KEY_SCHEDULE_TEMPLATE, d[KEY_SCHEDULE_TEMPLATE]))
	return d

static func save_all(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_AUDIO, KEY_MASTER, data.get(KEY_MASTER, 0.8))
	cfg.set_value(SECTION_AUDIO, KEY_BGM, data.get(KEY_BGM, 0.7))
	cfg.set_value(SECTION_AUDIO, KEY_SFX, data.get(KEY_SFX, 0.8))
	cfg.set_value(SECTION_VIDEO, KEY_RESOLUTION, data.get(KEY_RESOLUTION, "1920x1080"))
	cfg.set_value(SECTION_VIDEO, KEY_FULLSCREEN, data.get(KEY_FULLSCREEN, false))
	cfg.set_value(SECTION_VIDEO, KEY_VSYNC, data.get(KEY_VSYNC, true))
	cfg.set_value(SECTION_GAME, KEY_TEXT_SPEED, data.get(KEY_TEXT_SPEED, "中"))
	cfg.set_value(SECTION_GAME, KEY_AUTO_SPEED, data.get(KEY_AUTO_SPEED, "关"))
	cfg.set_value(SECTION_GAME, KEY_SCHEDULE_TEMPLATE, data.get(KEY_SCHEDULE_TEMPLATE, "default"))
	cfg.save(SETTINGS_PATH)

static func _defaults() -> Dictionary:
	return {
		KEY_MASTER: 0.8,
		KEY_BGM: 0.7,
		KEY_SFX: 0.8,
		KEY_RESOLUTION: "1920x1080",
		KEY_FULLSCREEN: false,
		KEY_VSYNC: true,
		KEY_TEXT_SPEED: "中",
		KEY_AUTO_SPEED: "关",
		KEY_SCHEDULE_TEMPLATE: "default",
	}

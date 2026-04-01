extends Node

var music_player: AudioStreamPlayer
var current_track: String = ""
var fade_tween: Tween
var music_volume: float = 0.7

var master_volume: float = 0.8
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8

var tracks = {
	"menu": "res://audio/menu_bgm.mp3",
	"game": "res://audio/game_bgm.mp3",
}

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	_load_saved_audio_settings()

func play(track_name: String):
	if track_name == current_track and music_player.playing:
		return
	if not tracks.has(track_name):
		return

	var stream = load(tracks[track_name])
	if stream == null:
		return

	current_track = track_name

	if music_player.playing:
		# 淡出再切歌
		_kill_tween()
		fade_tween = create_tween()
		fade_tween.tween_property(music_player, "volume_db", -80.0, 0.8)
		fade_tween.tween_callback(func():
			music_player.stream = stream
			music_player.volume_db = -80.0
			music_player.play()
		)
		fade_tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), 0.8)
	else:
		music_player.stream = stream
		music_player.volume_db = -80.0
		music_player.play()
		_kill_tween()
		fade_tween = create_tween()
		fade_tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), 1.0)

func stop():
	current_track = ""
	_kill_tween()
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -80.0, 0.8)
	fade_tween.tween_callback(music_player.stop)

func set_volume(vol: float):
	music_volume = clampf(vol, 0.0, 1.0)
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume)

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(master_volume, 0.0001)))

func set_bgm_volume(vol: float) -> void:
	bgm_volume = clampf(vol, 0.0, 1.0)
	music_volume = bgm_volume
	if music_player.playing:
		music_player.volume_db = linear_to_db(max(music_volume, 0.0001))

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(sfx_volume, 0.0001)))

func apply_mixer_settings(settings: Dictionary) -> void:
	set_master_volume(float(settings.get("master_volume", master_volume)))
	set_bgm_volume(float(settings.get("bgm_volume", bgm_volume)))
	set_sfx_volume(float(settings.get("sfx_volume", sfx_volume)))

func _load_saved_audio_settings() -> void:
	var settings_store_script: Script = load("res://scripts/menus/SettingsStore.gd")
	if settings_store_script == null:
		return
	var settings: Dictionary = settings_store_script.call("load_all")
	apply_mixer_settings(settings)

func _kill_tween():
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

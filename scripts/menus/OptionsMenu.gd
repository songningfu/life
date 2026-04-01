extends PanelContainer

signal close_requested()

@onready var master_slider: HSlider = $VBox/Content/Tabs/音频/AudioVBox/MasterRow/Slider
@onready var bgm_slider: HSlider = $VBox/Content/Tabs/音频/AudioVBox/BgmRow/Slider
@onready var sfx_slider: HSlider = $VBox/Content/Tabs/音频/AudioVBox/SfxRow/Slider

@onready var resolution_opt: OptionButton = $VBox/Content/Tabs/显示/VideoVBox/ResolutionRow/Option
@onready var fullscreen_check: CheckBox = $VBox/Content/Tabs/显示/VideoVBox/FullscreenRow/Check
@onready var vsync_check: CheckBox = $VBox/Content/Tabs/显示/VideoVBox/VsyncRow/Check

@onready var text_speed_opt: OptionButton = $VBox/Content/Tabs/游戏/GameVBox/TextSpeedRow/Option
@onready var auto_speed_opt: OptionButton = $VBox/Content/Tabs/游戏/GameVBox/AutoSpeedRow/Option
@onready var schedule_opt: OptionButton = $VBox/Content/Tabs/游戏/GameVBox/ScheduleRow/Option

@onready var close_btn: Button = $VBox/Footer/CloseBtn

var _settings := {}

const RESOLUTIONS := ["1280x720", "1600x900", "1920x1080", "2560x1440"]

func _ready() -> void:
	_bind_options()
	_apply_visual_style()
	close_btn.pressed.connect(func():
		_save_settings()
		visible = false
		close_requested.emit()
	)

func open_menu() -> void:
	visible = true
	_load_settings_to_ui()

func _bind_options() -> void:
	for r in RESOLUTIONS:
		resolution_opt.add_item(r)
	for t in ["慢", "中", "快"]:
		text_speed_opt.add_item(t)
	for a in ["关", "慢", "中", "快"]:
		auto_speed_opt.add_item(a)
	for s in ["default", "study_mode", "social_mode", "work_mode", "health_mode"]:
		schedule_opt.add_item(s)

	master_slider.value_changed.connect(func(v: float): _settings["master_volume"] = v)
	bgm_slider.value_changed.connect(func(v: float): _settings["bgm_volume"] = v)
	sfx_slider.value_changed.connect(func(v: float): _settings["sfx_volume"] = v)
	resolution_opt.item_selected.connect(func(i: int): _settings["resolution"] = resolution_opt.get_item_text(i))
	fullscreen_check.toggled.connect(func(v: bool): _settings["fullscreen"] = v)
	vsync_check.toggled.connect(func(v: bool): _settings["vsync"] = v)
	text_speed_opt.item_selected.connect(func(i: int): _settings["text_speed"] = text_speed_opt.get_item_text(i))
	auto_speed_opt.item_selected.connect(func(i: int): _settings["auto_speed"] = auto_speed_opt.get_item_text(i))
	schedule_opt.item_selected.connect(func(i: int): _settings["schedule_template"] = schedule_opt.get_item_text(i))

func _load_settings_to_ui() -> void:
	var settings_store_script: Script = load("res://scripts/menus/SettingsStore.gd")
	_settings = settings_store_script.call("load_all")

	master_slider.value = float(_settings.get("master_volume", 0.8))
	bgm_slider.value = float(_settings.get("bgm_volume", 0.7))
	sfx_slider.value = float(_settings.get("sfx_volume", 0.8))

	_set_option_by_text(resolution_opt, str(_settings.get("resolution", "1920x1080")))
	fullscreen_check.button_pressed = bool(_settings.get("fullscreen", false))
	vsync_check.button_pressed = bool(_settings.get("vsync", true))
	_set_option_by_text(text_speed_opt, str(_settings.get("text_speed", "中")))
	_set_option_by_text(auto_speed_opt, str(_settings.get("auto_speed", "关")))
	_set_option_by_text(schedule_opt, str(_settings.get("schedule_template", "default")))

func _save_settings() -> void:
	_apply_audio_settings()
	_apply_video_settings()
	_apply_game_settings()
	var settings_store_script: Script = load("res://scripts/menus/SettingsStore.gd")
	settings_store_script.call("save_all", _settings)

func _apply_audio_settings() -> void:
	AudioManager.apply_mixer_settings(_settings)

func _apply_video_settings() -> void:
	var res = str(_settings.get("resolution", "1920x1080")).split("x")
	if res.size() == 2:
		var w := int(res[0])
		var h := int(res[1])
		DisplayServer.window_set_size(Vector2i(w, h))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _settings.get("fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if _settings.get("vsync", true) else DisplayServer.VSYNC_DISABLED)

func _apply_game_settings() -> void:
	# 设置持久化，实际读取消费由对话系统/游戏系统按需使用
	pass

func _set_option_by_text(opt: OptionButton, text: String) -> void:
	for i in range(opt.item_count):
		if opt.get_item_text(i) == text:
			opt.select(i)
			return

func _apply_visual_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#0f1730")
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = Color("#27406b")
	panel.corner_radius_top_left = 10
	panel.corner_radius_top_right = 10
	panel.corner_radius_bottom_left = 10
	panel.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", panel)

	$VBox/Header.add_theme_color_override("font_color", Color("#e4f0ff"))
	$VBox/Header.add_theme_font_size_override("font_size", 30)

	for btn in [close_btn]:
		var n := StyleBoxFlat.new()
		n.bg_color = Color("#1a2950")
		n.border_width_left = 1
		n.border_width_top = 1
		n.border_width_right = 1
		n.border_width_bottom = 1
		n.border_color = Color("#4a9eff")
		n.corner_radius_top_left = 8
		n.corner_radius_top_right = 8
		n.corner_radius_bottom_left = 8
		n.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", n)
		var h := n.duplicate()
		h.bg_color = Color("#243b70")
		btn.add_theme_stylebox_override("hover", h)
		btn.add_theme_color_override("font_color", Color("#edf3ff"))

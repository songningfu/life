extends Control

@onready var title_label: Label = $Center/VBox/Title
@onready var subtitle_label: Label = $Center/VBox/SubTitle
@onready var new_game_btn: Button = $Center/VBox/MenuButtons/NewGameBtn
@onready var continue_btn: Button = $Center/VBox/MenuButtons/ContinueBtn
@onready var save_manage_btn: Button = $Center/VBox/MenuButtons/SaveManageBtn
@onready var options_btn: Button = $Center/VBox/MenuButtons/OptionsBtn
@onready var credits_btn: Button = $Center/VBox/MenuButtons/CreditsBtn
@onready var exit_btn: Button = $Center/VBox/MenuButtons/ExitBtn
@onready var dim_layer: ColorRect = $DimLayer
@onready var popup_layer: CanvasLayer = $PopupLayer

var _save_slots_panel
var _options_menu
var _credits_menu

func _ready() -> void:
	title_label.text = "大学四年"
	subtitle_label.text = "你的选择，书写你的青春"
	_apply_boot_settings()

	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	save_manage_btn.pressed.connect(_on_save_manage_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	exit_btn.pressed.connect(func(): get_tree().quit())

	dim_layer.visible = false
	_update_continue_state()
	AudioManager.play("menu")

func _update_continue_state() -> void:
	continue_btn.disabled = _get_latest_save_slot() < 0

func _on_new_game_pressed() -> void:
	_open_save_slots_for_new_game()

func _on_continue_pressed() -> void:
	var slot := _get_latest_save_slot()
	if slot < 0:
		return
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		return
	SaveManager.store_temp("pending_game_init", {
		"save_slot": slot,
		"is_new_game": false,
		"save_data": data,
	})
	SceneTransitions.fade_to("game")

func _on_save_manage_pressed() -> void:
	_open_save_slots_for_manage()

func _on_options_pressed() -> void:
	if _options_menu == null:
		var packed: PackedScene = load("res://scenes/menus/OptionsMenu.tscn")
		_options_menu = packed.instantiate()
		popup_layer.add_child(_options_menu)
		_options_menu.close_requested.connect(_close_popup)
	_show_popup(_options_menu)
	_options_menu.open_menu()

func _on_credits_pressed() -> void:
	if _credits_menu == null:
		var packed: PackedScene = load("res://scenes/menus/Credits.tscn")
		_credits_menu = packed.instantiate()
		popup_layer.add_child(_credits_menu)
		_credits_menu.close_requested.connect(_close_popup)
	_show_popup(_credits_menu)
	_credits_menu.start_scroll()

func _open_save_slots_for_new_game() -> void:
	if _save_slots_panel == null:
		_create_save_slots_panel()
	_show_popup(_save_slots_panel)
	_save_slots_panel.open_manage()

func _open_save_slots_for_manage() -> void:
	if _save_slots_panel == null:
		_create_save_slots_panel()
	_show_popup(_save_slots_panel)
	_save_slots_panel.open_manage()

func _create_save_slots_panel() -> void:
	var packed: PackedScene = load("res://scenes/menus/SaveSlotsPanel.tscn")
	_save_slots_panel = packed.instantiate()
	popup_layer.add_child(_save_slots_panel)
	_save_slots_panel.slot_chosen_for_new_game.connect(_start_new_game_with_slot)
	_save_slots_panel.slot_chosen_for_load.connect(_load_slot)
	_save_slots_panel.closed.connect(_close_popup)

func _start_new_game_with_slot(slot: int) -> void:
	SaveManager.store_temp("pending_char_creation_slot", slot)
	SceneTransitions.menu_to_creation()

func _load_slot(slot: int) -> void:
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		return
	SaveManager.store_temp("pending_game_init", {
		"save_slot": slot,
		"is_new_game": false,
		"save_data": data,
	})
	SceneTransitions.fade_to("game")

func _show_popup(node: Control) -> void:
	dim_layer.visible = true
	node.visible = true

func _close_popup() -> void:
	dim_layer.visible = false
	if _save_slots_panel:
		_save_slots_panel.visible = false
	if _options_menu:
		_options_menu.visible = false
	if _credits_menu:
		_credits_menu.visible = false
	_update_continue_state()

func _get_latest_save_slot() -> int:
	var best_slot := -1
	var best_ts := ""
	for info in SaveManager.get_all_slots_info():
		if not info.get("exists", false):
			continue
		var ts := str(info.get("meta", {}).get("timestamp", ""))
		if best_slot < 0 or ts > best_ts:
			best_slot = int(info.get("slot", -1))
			best_ts = ts
	return best_slot

func _apply_boot_settings() -> void:
	var settings_store_script: Script = load("res://scripts/menus/SettingsStore.gd")
	if settings_store_script == null:
		return
	var settings: Dictionary = settings_store_script.call("load_all")
	AudioManager.apply_mixer_settings(settings)

	var res = str(settings.get("resolution", "1920x1080")).split("x")
	if res.size() == 2:
		DisplayServer.window_set_size(Vector2i(int(res[0]), int(res[1])))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.get("fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.get("vsync", true) else DisplayServer.VSYNC_DISABLED)

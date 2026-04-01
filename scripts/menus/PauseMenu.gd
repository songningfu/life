extends CanvasLayer

@onready var root: PanelContainer = $PauseRoot
@onready var resume_btn: Button = $PauseRoot/VBox/Buttons/ResumeBtn
@onready var save_btn: Button = $PauseRoot/VBox/Buttons/SaveBtn
@onready var load_btn: Button = $PauseRoot/VBox/Buttons/LoadBtn
@onready var options_btn: Button = $PauseRoot/VBox/Buttons/OptionsBtn
@onready var back_menu_btn: Button = $PauseRoot/VBox/Buttons/BackMenuBtn

var _host_game: Node
var _save_panel
var _options_menu

func _ready() -> void:
	visible = false
	resume_btn.pressed.connect(_toggle_pause)
	save_btn.pressed.connect(_save_game)
	load_btn.pressed.connect(_open_load_panel)
	options_btn.pressed.connect(_open_options)
	back_menu_btn.pressed.connect(_back_to_main_menu)

func setup(game_node: Node) -> void:
	_host_game = game_node

func toggle_pause() -> void:
	_toggle_pause()

func _toggle_pause() -> void:
	visible = not visible
	root.visible = visible
	get_tree().paused = visible

func _save_game() -> void:
	if _host_game and _host_game.has_method("save_now"):
		_host_game.save_now()

func _open_load_panel() -> void:
	if _save_panel == null:
		var packed: PackedScene = load("res://scenes/menus/SaveSlotsPanel.tscn")
		_save_panel = packed.instantiate()
		root.add_child(_save_panel)
		_save_panel.slot_chosen_for_load.connect(_load_slot)
		_save_panel.closed.connect(func(): _save_panel.visible = false)
	_save_panel.open_load_only()
	_save_panel.visible = true

func _load_slot(slot: int) -> void:
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		return
	SaveManager.store_temp("pending_game_init", {
		"save_slot": slot,
		"is_new_game": false,
		"save_data": data,
	})
	get_tree().paused = false
	SceneTransitions.fade_to("game")

func _open_options() -> void:
	if _options_menu == null:
		var packed: PackedScene = load("res://scenes/menus/OptionsMenu.tscn")
		_options_menu = packed.instantiate()
		root.add_child(_options_menu)
		_options_menu.close_requested.connect(func(): _options_menu.visible = false)
	_options_menu.open_menu()
	_options_menu.visible = true

func _back_to_main_menu() -> void:
	get_tree().paused = false
	SceneTransitions.back_to_menu()

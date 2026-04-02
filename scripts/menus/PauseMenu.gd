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
	_apply_visual_style()
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

func _exit_tree() -> void:
	get_tree().paused = false
	if _save_panel != null and is_instance_valid(_save_panel):
		_save_panel.queue_free()
		_save_panel = null
	if _options_menu != null and is_instance_valid(_options_menu):
		_options_menu.queue_free()
		_options_menu = null

func _apply_visual_style() -> void:
	$Shade.color = Color(0.01, 0.02, 0.07, 0.68)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#111a32")
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = Color("#3a5e90")
	panel.corner_radius_top_left = 10
	panel.corner_radius_top_right = 10
	panel.corner_radius_bottom_left = 10
	panel.corner_radius_bottom_right = 10
	root.add_theme_stylebox_override("panel", panel)
	$PauseRoot/VBox/Title.add_theme_color_override("font_color", Color("#e4f0ff"))
	for btn in [resume_btn, save_btn, load_btn, options_btn, back_menu_btn]:
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

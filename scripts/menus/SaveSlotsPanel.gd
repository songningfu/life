extends PanelContainer

signal slot_chosen_for_new_game(slot: int)
signal slot_chosen_for_load(slot: int)
signal closed()

@onready var title_label: Label = $VBox/Title
@onready var slot_list: VBoxContainer = $VBox/Scroll/SlotList
@onready var back_btn: Button = $VBox/BackBtn

var _mode: String = "manage"

func _ready() -> void:
	_apply_visual_style()
	back_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)

func open_manage() -> void:
	_mode = "manage"
	title_label.text = "选择新学期档案"
	visible = true
	_refresh_slots()

func open_load_only() -> void:
	_mode = "load"
	title_label.text = "继续学业"
	visible = true
	_refresh_slots()

func _refresh_slots() -> void:
	for child in slot_list.get_children():
		child.queue_free()

	for info in SaveManager.get_all_slots_info():
		slot_list.add_child(_build_slot_row(info))

func _build_slot_row(info: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 68)
	row.add_theme_constant_override("separation", 10)

	var slot_btn := Button.new()
	slot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_btn.custom_minimum_size = Vector2(0, 68)
	slot_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	slot_btn.add_theme_font_size_override("font_size", 17)

	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color("#16213e")
	base_style.border_width_left = 1
	base_style.border_width_top = 1
	base_style.border_width_right = 1
	base_style.border_width_bottom = 1
	base_style.border_color = Color("#2e4f80")
	base_style.corner_radius_top_left = 8
	base_style.corner_radius_top_right = 8
	base_style.corner_radius_bottom_left = 8
	base_style.corner_radius_bottom_right = 8
	base_style.content_margin_left = 18
	base_style.content_margin_right = 18
	base_style.content_margin_top = 14
	base_style.content_margin_bottom = 14
	slot_btn.add_theme_stylebox_override("normal", base_style)
	var hover_style := base_style.duplicate()
	hover_style.bg_color = Color("#1d2b50")
	slot_btn.add_theme_stylebox_override("hover", hover_style)
	slot_btn.add_theme_color_override("font_color", Color("#e6efff"))

	var slot_id: int = int(info.get("slot", 0))
	var exists: bool = bool(info.get("exists", false))
	var meta: Dictionary = info.get("meta", {})

	if exists:
		slot_btn.text = "学期档案 %d  ·  %s  ·  大%s %s" % [
			slot_id + 1,
			meta.get("player_name", "未知"),
			meta.get("year", 1),
			meta.get("phase", "")
		]
	else:
		slot_btn.text = "学期档案 %d  ·  空白档案" % (slot_id + 1)

	slot_btn.pressed.connect(func():
		if _mode == "load":
			if exists:
				slot_chosen_for_load.emit(slot_id)
			return

		if exists:
			slot_chosen_for_load.emit(slot_id)
		else:
			slot_chosen_for_new_game.emit(slot_id)
	)
	row.add_child(slot_btn)

	if _mode == "manage" and exists:
		var new_btn := Button.new()
		new_btn.text = "新档"
		new_btn.custom_minimum_size = Vector2(84, 68)
		new_btn.pressed.connect(func():
			slot_chosen_for_new_game.emit(slot_id)
		)
		row.add_child(new_btn)

		var del_btn := Button.new()
		del_btn.text = "删除"
		del_btn.custom_minimum_size = Vector2(84, 68)
		del_btn.pressed.connect(func():
			SaveManager.delete_save(slot_id)
			_refresh_slots()
		)
		row.add_child(del_btn)

	return row

func _apply_visual_style() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#101a34")
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = Color("#3a5e90")
	panel.corner_radius_top_left = 12
	panel.corner_radius_top_right = 12
	panel.corner_radius_bottom_left = 12
	panel.corner_radius_bottom_right = 12
	panel.content_margin_left = 22
	panel.content_margin_right = 22
	panel.content_margin_top = 18
	panel.content_margin_bottom = 18
	add_theme_stylebox_override("panel", panel)
	title_label.add_theme_color_override("font_color", Color("#e4f0ff"))
	title_label.add_theme_font_size_override("font_size", 28)
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
	back_btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color("#243b70")
	back_btn.add_theme_stylebox_override("hover", h)
	back_btn.add_theme_color_override("font_color", Color("#edf3ff"))

extends PanelContainer

signal slot_chosen_for_new_game(slot: int)
signal slot_chosen_for_load(slot: int)
signal closed()

@onready var title_label: Label = $VBox/Title
@onready var slot_list: VBoxContainer = $VBox/Scroll/SlotList
@onready var back_btn: Button = $VBox/BackBtn

var _mode: String = "manage"

func _ready() -> void:
	back_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)

func open_manage() -> void:
	_mode = "manage"
	title_label.text = "存档管理"
	visible = true
	_refresh_slots()

func open_load_only() -> void:
	_mode = "load"
	title_label.text = "读取存档"
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
	row.add_theme_constant_override("separation", 8)

	var slot_btn := Button.new()
	slot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_btn.custom_minimum_size = Vector2(0, 56)
	slot_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var slot_id: int = int(info.get("slot", 0))
	var exists: bool = bool(info.get("exists", false))
	var meta: Dictionary = info.get("meta", {})

	if exists:
		slot_btn.text = "槽位 %d  |  %s  |  大%s %s" % [
			slot_id + 1,
			meta.get("player_name", "未知"),
			meta.get("year", 1),
			meta.get("phase", "")
		]
	else:
		slot_btn.text = "槽位 %d  |  空" % (slot_id + 1)

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
		new_btn.custom_minimum_size = Vector2(64, 56)
		new_btn.pressed.connect(func():
			slot_chosen_for_new_game.emit(slot_id)
		)
		row.add_child(new_btn)

		var del_btn := Button.new()
		del_btn.text = "删除"
		del_btn.custom_minimum_size = Vector2(64, 56)
		del_btn.pressed.connect(func():
			SaveManager.delete_save(slot_id)
			_refresh_slots()
		)
		row.add_child(del_btn)

	return row

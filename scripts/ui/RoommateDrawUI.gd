# res://scripts/ui/RoommateDrawUI.gd
extends CanvasLayer

signal draw_completed(roommates: Array)
signal draw_cancelled

var current_roommates: Array = []
var redraw_left: int = 0
var max_redraw: int = 0
var allow_redraw: bool = true
var roommate_count: int = 3

func _ready() -> void:
	layer = 30
	visible = false

	if not %RedrawBtn.pressed.is_connected(_on_redraw):
		%RedrawBtn.pressed.connect(_on_redraw)

	if not %ConfirmBtn.pressed.is_connected(_on_confirm):
		%ConfirmBtn.pressed.connect(_on_confirm)

	if not %CancelBtn.pressed.is_connected(_on_cancel):
		%CancelBtn.pressed.connect(_on_cancel)

func start_draw() -> void:
	visible = true

	var cfg: Dictionary = RoommateDrawer.get_draw_config()
	roommate_count = int(cfg.get("roommate_count", 3))
	allow_redraw = bool(cfg.get("allow_redraw", true))
	max_redraw = int(cfg.get("max_redraw", 2))
	redraw_left = max_redraw

	%TitleLabel.text = "抽取舍友"
	_update_redraw_ui()
	_do_draw()

func _do_draw() -> void:
	current_roommates = RoommateDrawer.draw_roommates(roommate_count, [])
	_display_roommates()
	_play_flip_animation_if_exists()

func _display_roommates() -> void:
	for child: Node in %CardList.get_children():
		child.queue_free()

	for item: Variant in current_roommates:
		if item is Dictionary:
			var info: Dictionary = item

			var card: PanelContainer = PanelContainer.new()
			card.custom_minimum_size = Vector2(260, 420)

			var vbox: VBoxContainer = VBoxContainer.new()
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.add_theme_constant_override("separation", 8)
			card.add_child(vbox)

			var portrait: TextureRect = TextureRect.new()
			portrait.custom_minimum_size = Vector2(220, 180)
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var portrait_path: String = str(info.get("portrait", ""))
			if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
				portrait.texture = load(portrait_path)
			vbox.add_child(portrait)

			var name_label: Label = Label.new()
			name_label.text = str(info.get("name", "未知"))
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(name_label)

			var personality_label: Label = Label.new()
			personality_label.text = "性格：%s" % str(info.get("personality", "未知"))
			vbox.add_child(personality_label)

			var traits_label: Label = Label.new()
			var traits_var: Variant = info.get("traits", [])
			var traits_arr: Array = traits_var if traits_var is Array else []
			traits_label.text = "特征：%s" % " / ".join(traits_arr)
			traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(traits_label)

			var desc_label: Label = Label.new()
			desc_label.text = str(info.get("description", ""))
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(desc_label)

			%CardList.add_child(card)

func _on_redraw() -> void:
	if not allow_redraw:
		return
	if redraw_left <= 0:
		return

	redraw_left -= 1
	_update_redraw_ui()
	_do_draw()

func _on_confirm() -> void:
	draw_completed.emit(current_roommates.duplicate(true))
	queue_free()

func _on_cancel() -> void:
	draw_cancelled.emit()
	queue_free()

func _update_redraw_ui() -> void:
	if allow_redraw:
		%RedrawInfo.text = "剩余重抽次数：%d / %d" % [redraw_left, max_redraw]
		%RedrawBtn.disabled = redraw_left <= 0
	else:
		%RedrawInfo.text = "本次不可重抽"
		%RedrawBtn.disabled = true

func _play_flip_animation_if_exists() -> void:
	if %AnimPlayer and %AnimPlayer.has_animation("card_flip"):
		%AnimPlayer.play("card_flip")

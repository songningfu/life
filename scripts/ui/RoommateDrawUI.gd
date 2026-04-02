# res://scripts/ui/RoommateDrawUI.gd
extends CanvasLayer

const ROOMMATE_CARD_SCENE := preload("res://scenes/ui/RoommateCard.tscn")

signal draw_completed(roommates: Array)
signal draw_cancelled

var current_roommates: Array = []
var redraw_left: int = 0
var max_redraw: int = 0
var allow_redraw: bool = true
var roommate_count: int = 3

@onready var redraw_btn: Button = $RootPanel/VBox/BottomBar/RedrawBtn
@onready var confirm_btn: Button = $RootPanel/VBox/BottomBar/ConfirmBtn
@onready var cancel_btn: Button = $RootPanel/VBox/BottomBar/CancelBtn
@onready var title_label: Label = $RootPanel/VBox/TitleLabel
@onready var redraw_info: Label = $RootPanel/VBox/RedrawInfo
@onready var card_list: HBoxContainer = $RootPanel/VBox/CardScroll/CardList
@onready var anim_player: AnimationPlayer = $RootPanel/AnimPlayer

func _ready() -> void:
	layer = 30
	visible = false

	if not redraw_btn.pressed.is_connected(_on_redraw):
		redraw_btn.pressed.connect(_on_redraw)

	if not confirm_btn.pressed.is_connected(_on_confirm):
		confirm_btn.pressed.connect(_on_confirm)

	if not cancel_btn.pressed.is_connected(_on_cancel):
		cancel_btn.pressed.connect(_on_cancel)

func start_draw() -> void:
	visible = true

	var cfg: Dictionary = RoommateDrawer.get_draw_config()
	roommate_count = int(cfg.get("roommate_count", 3))
	allow_redraw = bool(cfg.get("allow_redraw", true))
	max_redraw = int(cfg.get("max_redraw", 2))
	redraw_left = max_redraw

	title_label.text = "抽取舍友"
	_update_redraw_ui()
	_do_draw()

func _clear_cards() -> void:
	for child: Node in card_list.get_children():
		var portrait := child.get_node_or_null("CardMargin/VBox/Portrait") as TextureRect
		if portrait != null:
			portrait.texture = null
		child.queue_free()

func _exit_tree() -> void:
	_clear_cards()

func _do_draw() -> void:
	current_roommates = RoommateDrawer.draw_roommates(roommate_count, [])
	_display_roommates()
	_play_flip_animation_if_exists()

func _display_roommates() -> void:
	_clear_cards()

	for item: Variant in current_roommates:
		if item is Dictionary:
			var info: Dictionary = item
			var card := ROOMMATE_CARD_SCENE.instantiate() as PanelContainer
			if card == null:
				continue

			var portrait := card.get_node("CardMargin/VBox/Portrait") as TextureRect
			var name_label := card.get_node("CardMargin/VBox/NameLabel") as Label
			var personality_label := card.get_node("CardMargin/VBox/PersonalityLabel") as Label
			var traits_label := card.get_node("CardMargin/VBox/TraitsLabel") as Label
			var desc_label := card.get_node("CardMargin/VBox/DescriptionLabel") as Label
			if portrait == null or name_label == null or personality_label == null or traits_label == null or desc_label == null:
				continue

			var portrait_path: String = str(info.get("portrait", ""))
			if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
				portrait.texture = load(portrait_path)

			name_label.text = str(info.get("name", "未知"))
			personality_label.text = "性格：%s" % str(info.get("personality", "未知"))

			var traits_var: Variant = info.get("traits", [])
			var traits_arr: Array = traits_var if traits_var is Array else []
			traits_label.text = "特征：%s" % " / ".join(traits_arr)
			desc_label.text = str(info.get("description", ""))

			card_list.add_child(card)

func _on_redraw() -> void:
	if not allow_redraw:
		return
	if redraw_left <= 0:
		return

	redraw_left -= 1
	_update_redraw_ui()
	_do_draw()

func _on_confirm() -> void:
	_clear_cards()
	draw_completed.emit(current_roommates.duplicate(true))
	queue_free()

func _on_cancel() -> void:
	_clear_cards()
	draw_cancelled.emit()
	queue_free()

func _update_redraw_ui() -> void:
	if allow_redraw:
		redraw_info.text = "剩余重抽次数：%d / %d" % [redraw_left, max_redraw]
		redraw_btn.disabled = redraw_left <= 0
	else:
		redraw_info.text = "本次不可重抽"
		redraw_btn.disabled = true

func _play_flip_animation_if_exists() -> void:
	if anim_player and anim_player.has_animation("card_flip"):
		anim_player.play("card_flip")

extends CanvasLayer

const ROOMMATE_CARD_SCENE := preload("res://scenes/ui/RoommateCard.tscn")

signal draw_completed(roommates: Array, draw_summary: Dictionary)
signal draw_cancelled

var current_roommates: Array = []
var redraw_left: int = 0
var max_redraw: int = 0
var allow_redraw: bool = true
var roommate_count: int = 3
var draw_count: int = 0
var ssr_draw_count: int = 0
var current_has_ssr: bool = false
var _draw_config: Dictionary = {}
var _is_animating: bool = false
var _root_origin: Vector2 = Vector2.ZERO

@onready var mask: ColorRect = $Mask
@onready var back_glow: ColorRect = $BackGlow
@onready var root_panel: PanelContainer = $RootPanel
@onready var inner_panel: PanelContainer = $RootPanel/InnerPanel
@onready var top_shine: ColorRect = $RootPanel/TopShine
@onready var header_box: VBoxContainer = $RootPanel/VBox/Header
@onready var status_bar: PanelContainer = $RootPanel/VBox/StatusBar
@onready var redraw_badge: PanelContainer = $RootPanel/VBox/StatusBar/StatusMargin/StatusHBox/RedrawBadge
@onready var card_stage: PanelContainer = $RootPanel/VBox/CardStage
@onready var bottom_bar: HBoxContainer = $RootPanel/VBox/BottomBar
@onready var redraw_btn: Button = $RootPanel/VBox/BottomBar/RedrawBtn
@onready var confirm_btn: Button = $RootPanel/VBox/BottomBar/ConfirmBtn
@onready var cancel_btn: Button = $RootPanel/VBox/BottomBar/CancelBtn
@onready var title_label: Label = $RootPanel/VBox/Header/TitleLabel
@onready var subtitle_label: Label = $RootPanel/VBox/Header/SubtitleLabel
@onready var redraw_info: Label = $RootPanel/VBox/StatusBar/StatusMargin/StatusHBox/RedrawBadge/RedrawInfo
@onready var tip_label: Label = $RootPanel/VBox/StatusBar/StatusMargin/StatusHBox/TipLabel
@onready var card_list: HBoxContainer = $RootPanel/VBox/CardStage/StageMargin/CardScroll/CardList

var colors := {
	"panel": Color("#0d1629"),
	"panel_soft": Color("#121f38"),
	"panel_inner": Color("#0f1a30"),
	"panel_hover": Color("#203463"),
	"border": Color("#33578b"),
	"border_soft": Color("#253c63"),
	"accent": Color("#69c6ff"),
	"accent_soft": Color("#9bdcff"),
	"text": Color("#edf5ff"),
	"muted": Color("#9fb5d4"),
	"warn": Color("#ffcc7a"),
	"danger": Color("#ff8c8c"),
	"ssr": Color("#ffd77a"),
	"sr": Color("#d2b6ff"),
}

func _ready() -> void:
	layer = 30
	visible = false
	_root_origin = root_panel.position
	_apply_visual_style()

	if not redraw_btn.pressed.is_connected(_on_redraw):
		redraw_btn.pressed.connect(_on_redraw)

	if not confirm_btn.pressed.is_connected(_on_confirm):
		confirm_btn.pressed.connect(_on_confirm)

	if not cancel_btn.pressed.is_connected(_on_cancel):
		cancel_btn.pressed.connect(_on_cancel)

func start_draw() -> void:
	visible = true
	_draw_config = RoommateDrawer.get_draw_config()
	roommate_count = int(_draw_config.get("roommate_count", 3))
	allow_redraw = bool(_draw_config.get("allow_redraw", true))
	max_redraw = int(_draw_config.get("max_redraw", 2))
	redraw_left = max_redraw
	draw_count = 0
	ssr_draw_count = 0
	current_has_ssr = false

	title_label.text = "抽取舍友"
	subtitle_label.text = "大学第一批同行者，会悄悄改变你之后的很多日常。"
	_do_draw()
	_play_enter_animation()

func _clear_cards() -> void:
	for child: Node in card_list.get_children():
		var portrait := child.get_node_or_null("CardMargin/VBox/PortraitFrame/Portrait") as TextureRect
		if portrait != null:
			portrait.texture = null
		child.queue_free()

func _exit_tree() -> void:
	_clear_cards()

func _do_draw() -> void:
	current_roommates = RoommateDrawer.draw_roommates(roommate_count, [])
	draw_count += 1
	current_has_ssr = RoommateDrawer.has_ssr(current_roommates)
	if current_has_ssr:
		ssr_draw_count += 1
	_display_roommates()
	_update_redraw_ui()

func _display_roommates() -> void:
	_clear_cards()

	for item: Variant in current_roommates:
		if not (item is Dictionary):
			continue

		var info: Dictionary = item
		var card := ROOMMATE_CARD_SCENE.instantiate() as PanelContainer
		if card == null:
			continue

		var badge_panel := card.get_node_or_null("CardMargin/VBox/TopRow/RarityBadge") as PanelContainer
		var badge_label := card.get_node_or_null("CardMargin/VBox/TopRow/RarityBadge/BadgeLabel") as Label
		var portrait := card.get_node_or_null("CardMargin/VBox/PortraitFrame/Portrait") as TextureRect
		var name_label := card.get_node_or_null("CardMargin/VBox/NameLabel") as Label
		var personality_label := card.get_node_or_null("CardMargin/VBox/PersonalityLabel") as Label
		var traits_label := card.get_node_or_null("CardMargin/VBox/TraitsLabel") as Label
		var desc_label := card.get_node_or_null("CardMargin/VBox/DescriptionLabel") as Label
		if portrait == null or name_label == null or personality_label == null or traits_label == null or desc_label == null:
			continue

		var portrait_path: String = str(info.get("portrait", ""))
		if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
			portrait.texture = load(portrait_path)

		var rarity: String = str(info.get("rarity", "r")).to_upper()
		if badge_panel != null:
			badge_panel.visible = rarity != "R"
		if badge_label != null:
			badge_label.text = rarity

		name_label.text = str(info.get("name", "未知"))
		personality_label.text = "性格  ·  %s" % str(info.get("personality", "未知"))

		var traits_var: Variant = info.get("traits", [])
		var traits_arr: Array = traits_var if traits_var is Array else []
		traits_label.text = "特征  ·  %s" % (" / ".join(traits_arr) if not traits_arr.is_empty() else "暂无")
		desc_label.text = str(info.get("description", ""))

		card_list.add_child(card)
		_apply_card_style(card, rarity)
		_prepare_card_reveal(card, rarity)

func _prepare_card_reveal(card: Control, rarity: String) -> void:
	card.set_meta("rarity", rarity)
	card.pivot_offset = card.custom_minimum_size * 0.5
	card.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.82, 0.96)
	card.position.y += 28
	card.set_meta("reveal_target_y", card.position.y - 28.0)
	var reveal_cover := card.get_node_or_null("RevealCover") as ColorRect
	if reveal_cover != null:
		reveal_cover.visible = true
		reveal_cover.modulate = Color(1, 1, 1, 0.94)

func _on_redraw() -> void:
	if not allow_redraw:
		return
	if redraw_left <= 0 or _is_animating:
		return

	redraw_left -= 1
	await _animate_old_cards_out()
	_do_draw()
	await _reveal_cards()

func _on_confirm() -> void:
	if _is_animating:
		return
	var draw_summary := {
		"draw_count": draw_count,
		"ssr_draw_count": ssr_draw_count,
		"final_has_ssr": current_has_ssr,
	}
	_clear_cards()
	draw_completed.emit(current_roommates.duplicate(true), draw_summary)
	queue_free()

func _on_cancel() -> void:
	if _is_animating:
		return
	_clear_cards()
	draw_cancelled.emit()
	queue_free()

func _update_redraw_ui() -> void:
	if allow_redraw:
		redraw_info.text = "累计抽取：%d 次 · 剩余重抽：%d / %d" % [draw_count, redraw_left, max_redraw]
		redraw_btn.disabled = _is_animating or redraw_left <= 0
	else:
		redraw_info.text = "累计抽取：%d 次 · 本次不可重抽" % draw_count
		redraw_btn.disabled = true

	confirm_btn.disabled = _is_animating
	cancel_btn.disabled = _is_animating

	var late_draw_threshold: int = int(_draw_config.get("late_draw_threshold", 20))
	if current_has_ssr:
		tip_label.text = str(_draw_config.get("ssr_tip", "这次真让你欧到了。可再稀有的人，也要能陪你把日子过下去。"))
		tip_label.add_theme_color_override("font_color", colors.ssr)
	elif draw_count >= late_draw_threshold:
		tip_label.text = str(_draw_config.get("late_draw_tip", "抽到这里你该懂了，真正难得的不是极品，是一直陪着你过日子的人。"))
		tip_label.add_theme_color_override("font_color", colors.warn)
	else:
		tip_label.text = "确认后将带着这组舍友进入大学生活。"
		tip_label.add_theme_color_override("font_color", colors.accent_soft if not redraw_btn.disabled else colors.muted)

func _apply_visual_style() -> void:
	var root_style := StyleBoxFlat.new()
	root_style.bg_color = colors.panel
	root_style.border_width_left = 1
	root_style.border_width_top = 1
	root_style.border_width_right = 1
	root_style.border_width_bottom = 1
	root_style.border_color = colors.border
	root_style.corner_radius_top_left = 22
	root_style.corner_radius_top_right = 22
	root_style.corner_radius_bottom_left = 22
	root_style.corner_radius_bottom_right = 22
	root_style.content_margin_left = 28
	root_style.content_margin_top = 24
	root_style.content_margin_right = 28
	root_style.content_margin_bottom = 24
	root_style.shadow_color = Color(0, 0, 0, 0.52)
	root_style.shadow_size = 28
	root_panel.add_theme_stylebox_override("panel", root_style)

	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(0.09, 0.14, 0.24, 0.36)
	inner_style.border_width_left = 1
	inner_style.border_width_top = 1
	inner_style.border_width_right = 1
	inner_style.border_width_bottom = 1
	inner_style.border_color = Color(0.42, 0.62, 0.92, 0.10)
	inner_style.corner_radius_top_left = 18
	inner_style.corner_radius_top_right = 18
	inner_style.corner_radius_bottom_left = 18
	inner_style.corner_radius_bottom_right = 18
	inner_panel.add_theme_stylebox_override("panel", inner_style)

	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color(0.08, 0.12, 0.20, 0.92)
	status_style.border_width_left = 1
	status_style.border_width_top = 1
	status_style.border_width_right = 1
	status_style.border_width_bottom = 1
	status_style.border_color = colors.border_soft
	status_style.set_corner_radius_all(16)
	status_style.shadow_color = Color(0, 0, 0, 0.16)
	status_style.shadow_size = 8
	status_bar.add_theme_stylebox_override("panel", status_style)

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.10, 0.18, 0.30, 0.96)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.border_color = Color(0.32, 0.54, 0.86, 0.88)
	badge_style.set_corner_radius_all(13)
	badge_style.content_margin_left = 14
	badge_style.content_margin_right = 14
	badge_style.content_margin_top = 7
	badge_style.content_margin_bottom = 7
	redraw_badge.add_theme_stylebox_override("panel", badge_style)

	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = Color(0.06, 0.09, 0.15, 0.92)
	stage_style.border_width_left = 1
	stage_style.border_width_top = 1
	stage_style.border_width_right = 1
	stage_style.border_width_bottom = 1
	stage_style.border_color = Color(0.20, 0.30, 0.46, 0.92)
	stage_style.set_corner_radius_all(18)
	stage_style.shadow_color = Color(0, 0, 0, 0.18)
	stage_style.shadow_size = 14
	card_stage.add_theme_stylebox_override("panel", stage_style)

	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", colors.text)
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", colors.muted)
	redraw_info.add_theme_font_size_override("font_size", 15)
	redraw_info.add_theme_color_override("font_color", colors.accent_soft)
	tip_label.add_theme_font_size_override("font_size", 15)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	redraw_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.add_theme_font_size_override("font_size", 18)

	var divider := status_bar.get_node("StatusMargin/StatusHBox/StatusDivider") as Label
	divider.add_theme_color_override("font_color", Color(0.38, 0.49, 0.66))
	top_shine.color = Color(0.54, 0.76, 1.0, 0.08)
	back_glow.color = Color(0.12, 0.22, 0.44, 0.14)

	_style_button(cancel_btn, colors.panel_soft, colors.border_soft, colors.text)
	_style_button(redraw_btn, Color("#173660"), colors.accent, colors.accent_soft)
	_style_button(confirm_btn, Color("#21506f"), colors.accent_soft, colors.text)

func _style_button(button: Button, bg: Color, border: Color, text_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = border
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_left = 14
	normal.corner_radius_bottom_right = 14
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	normal.shadow_size = 8
	normal.shadow_color = Color(bg.r, bg.g, bg.b, 0.14)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = bg.lerp(Color.WHITE, 0.08)
	hover.border_color = border.lerp(Color.WHITE, 0.12)
	hover.shadow_size = 12
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = bg.lerp(Color.BLACK, 0.14)
	pressed.shadow_size = 4
	button.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate()
	disabled.bg_color = bg.lerp(Color.BLACK, 0.24)
	disabled.border_color = border.lerp(Color.BLACK, 0.35)
	disabled.shadow_size = 0
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color.lerp(Color("#5c6c85"), 0.5))

func _apply_card_style(card: PanelContainer, rarity: String) -> void:
	var palette := _rarity_palette(rarity)
	var glow := card.get_node_or_null("Glow") as ColorRect
	var inner_frame := card.get_node_or_null("InnerFrame") as PanelContainer
	var badge_panel := card.get_node_or_null("CardMargin/VBox/TopRow/RarityBadge") as PanelContainer
	var badge_label := card.get_node_or_null("CardMargin/VBox/TopRow/RarityBadge/BadgeLabel") as Label
	var portrait_frame := card.get_node_or_null("CardMargin/VBox/PortraitFrame") as PanelContainer
	var portrait_glow := card.get_node_or_null("CardMargin/VBox/PortraitFrame/PortraitGlow") as ColorRect
	var name_label := card.get_node_or_null("CardMargin/VBox/NameLabel") as Label
	var personality_label := card.get_node_or_null("CardMargin/VBox/PersonalityLabel") as Label
	var traits_label := card.get_node_or_null("CardMargin/VBox/TraitsLabel") as Label
	var desc_label := card.get_node_or_null("CardMargin/VBox/DescriptionLabel") as Label
	var divider := card.get_node_or_null("CardMargin/VBox/Divider") as HSeparator

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = palette["panel"]
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = palette["border"]
	card_style.set_corner_radius_all(18)
	card_style.shadow_size = 16
	card_style.shadow_color = palette["shadow"]
	card.add_theme_stylebox_override("panel", card_style)

	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = palette["inner"]
	inner_style.border_width_left = 1
	inner_style.border_width_top = 1
	inner_style.border_width_right = 1
	inner_style.border_width_bottom = 1
	inner_style.border_color = palette["line"]
	inner_style.set_corner_radius_all(14)
	inner_frame.add_theme_stylebox_override("panel", inner_style)

	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = palette["portrait_bg"]
	portrait_style.border_width_left = 1
	portrait_style.border_width_top = 1
	portrait_style.border_width_right = 1
	portrait_style.border_width_bottom = 1
	portrait_style.border_color = palette["line"]
	portrait_style.set_corner_radius_all(14)
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)

	if glow != null:
		glow.color = palette["glow"]
	if portrait_glow != null:
		portrait_glow.color = palette["portrait_glow"]

	if badge_panel != null:
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = palette["badge_bg"]
		badge_style.border_width_left = 1
		badge_style.border_width_top = 1
		badge_style.border_width_right = 1
		badge_style.border_width_bottom = 1
		badge_style.border_color = palette["badge_border"]
		badge_style.set_corner_radius_all(12)
		badge_style.content_margin_left = 10
		badge_style.content_margin_right = 10
		badge_style.content_margin_top = 4
		badge_style.content_margin_bottom = 4
		badge_panel.add_theme_stylebox_override("panel", badge_style)

	if badge_label != null:
		badge_label.add_theme_font_size_override("font_size", 12)
		badge_label.add_theme_color_override("font_color", palette["badge_text"])

	if name_label != null:
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", palette["title"])
	if personality_label != null:
		personality_label.add_theme_font_size_override("font_size", 14)
		personality_label.add_theme_color_override("font_color", palette["muted"])
	if traits_label != null:
		traits_label.add_theme_font_size_override("font_size", 14)
		traits_label.add_theme_color_override("font_color", palette["accent"])
	if desc_label != null:
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", palette["body"])
	if divider != null:
		divider.add_theme_color_override("separator", palette["line"])

func _rarity_palette(rarity: String) -> Dictionary:
	match rarity:
		"SSR":
			return {
				"panel": Color("#15131f"),
				"inner": Color("#1d1722"),
				"border": Color("#cfa957"),
				"line": Color("#715a2b"),
				"badge_bg": Color("#2b2010"),
				"badge_border": Color("#cfa957"),
				"badge_text": Color("#ffe7ad"),
				"title": Color("#fff2cd"),
				"muted": Color("#dbcba2"),
				"accent": Color("#ffd77a"),
				"body": Color("#d7ceb0"),
				"glow": Color(1.0, 0.84, 0.48, 0.12),
				"portrait_bg": Color("#271f17"),
				"portrait_glow": Color(1.0, 0.86, 0.58, 0.11),
				"shadow": Color(0.42, 0.30, 0.06, 0.20),
			}
		"SR":
			return {
				"panel": Color("#121326"),
				"inner": Color("#171936"),
				"border": Color("#8e73c8"),
				"line": Color("#4d4473"),
				"badge_bg": Color("#211933"),
				"badge_border": Color("#8e73c8"),
				"badge_text": Color("#efe4ff"),
				"title": Color("#f4f0ff"),
				"muted": Color("#c2b7e2"),
				"accent": Color("#d2b6ff"),
				"body": Color("#cfd2ea"),
				"glow": Color(0.69, 0.58, 1.0, 0.10),
				"portrait_bg": Color("#161a30"),
				"portrait_glow": Color(0.77, 0.67, 1.0, 0.09),
				"shadow": Color(0.18, 0.12, 0.28, 0.18),
			}
		_:
			return {
				"panel": Color("#0d1627"),
				"inner": Color("#101d34"),
				"border": Color("#426792"),
				"line": Color("#254162"),
				"badge_bg": Color("#16304d"),
				"badge_border": Color("#69c6ff"),
				"badge_text": Color("#cdeeff"),
				"title": Color("#edf5ff"),
				"muted": Color("#a9bfd8"),
				"accent": Color("#8ccfff"),
				"body": Color("#c7d4e6"),
				"glow": Color(0.38, 0.64, 1.0, 0.08),
				"portrait_bg": Color("#13233c"),
				"portrait_glow": Color(0.47, 0.74, 1.0, 0.07),
				"shadow": Color(0.05, 0.10, 0.20, 0.18),
			}

func _play_enter_animation() -> void:
	_is_animating = true
	_update_redraw_ui()
	mask.modulate = Color(1, 1, 1, 0)
	back_glow.modulate = Color(1, 1, 1, 0)
	root_panel.modulate = Color(1, 1, 1, 0)
	root_panel.scale = Vector2(0.965, 0.965)
	root_panel.position = _root_origin + Vector2(0, 18)
	header_box.modulate = Color(1, 1, 1, 0)
	header_box.scale = Vector2(0.98, 0.98)
	status_bar.modulate = Color(1, 1, 1, 0)
	status_bar.scale = Vector2(0.985, 0.985)
	card_stage.modulate = Color(1, 1, 1, 0)
	card_stage.scale = Vector2(0.99, 0.99)
	bottom_bar.modulate = Color(1, 1, 1, 0)
	bottom_bar.scale = Vector2(0.985, 0.985)
	top_shine.modulate = Color(1, 1, 1, 0)

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(mask, "modulate:a", 1.0, 0.20)
	tw.tween_property(back_glow, "modulate:a", 1.0, 0.28)
	tw.tween_property(root_panel, "modulate:a", 1.0, 0.24)
	tw.tween_property(root_panel, "scale", Vector2.ONE, 0.24)
	tw.tween_property(root_panel, "position:y", _root_origin.y, 0.24)
	tw.tween_property(top_shine, "modulate:a", 1.0, 0.30)
	tw.chain()
	tw.set_parallel(true)
	tw.tween_property(header_box, "modulate:a", 1.0, 0.18)
	tw.tween_property(header_box, "scale", Vector2.ONE, 0.18)
	tw.tween_property(status_bar, "modulate:a", 1.0, 0.18)
	tw.tween_property(status_bar, "scale", Vector2.ONE, 0.18)
	tw.chain()
	tw.set_parallel(true)
	tw.tween_property(card_stage, "modulate:a", 1.0, 0.16)
	tw.tween_property(card_stage, "scale", Vector2.ONE, 0.16)
	tw.tween_property(bottom_bar, "modulate:a", 1.0, 0.16)
	tw.tween_property(bottom_bar, "scale", Vector2.ONE, 0.16)
	await tw.finished
	await _reveal_cards()

func _reveal_cards() -> void:
	_is_animating = true
	_update_redraw_ui()
	var total := card_list.get_child_count()
	for i in range(total):
		var card := card_list.get_child(i) as Control
		if card == null:
			continue
		var target_y := float(card.get_meta("reveal_target_y", card.position.y))
		var reveal_cover := card.get_node_or_null("RevealCover") as ColorRect
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(card, "modulate:a", 1.0, 0.18)
		tw.parallel().tween_property(card, "position:y", target_y, 0.18)
		tw.parallel().tween_property(card, "scale:x", 1.04, 0.15)
		tw.parallel().tween_property(card, "scale:y", 1.0, 0.15)
		if reveal_cover != null:
			tw.parallel().tween_property(reveal_cover, "modulate:a", 0.18, 0.09)
		tw.chain()
		tw.parallel().tween_property(card, "scale:x", 1.0, 0.12)
		if reveal_cover != null:
			tw.parallel().tween_property(reveal_cover, "modulate:a", 0.0, 0.12)
		await tw.finished
		if reveal_cover != null:
			reveal_cover.visible = false
		await _accent_revealed_card(card)
		if i < total - 1:
			await get_tree().create_timer(0.05).timeout
	_is_animating = false
	_update_redraw_ui()

func _accent_revealed_card(card: Control) -> void:
	if str(card.get_meta("rarity", "R")) != "SSR":
		return
	var glow := card.get_node_or_null("Glow") as ColorRect
	var base_color := glow.color if glow != null else Color(1, 1, 1, 0)
	var flash_color := Color(1.0, 0.90, 0.64, min(base_color.a + 0.14, 0.28))
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if glow != null:
		tw.parallel().tween_property(glow, "color", flash_color, 0.10)
	tw.parallel().tween_property(card, "scale", Vector2(1.018, 1.018), 0.10)
	tw.chain()
	if glow != null:
		tw.parallel().tween_property(glow, "color", base_color, 0.22)
	tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.22)
	await tw.finished

func _animate_old_cards_out() -> void:
	_is_animating = true
	_update_redraw_ui()
	var count := card_list.get_child_count()
	if count == 0:
		return
	for i in range(count):
		var card := card_list.get_child(i) as Control
		if card == null:
			continue
		card.pivot_offset = card.custom_minimum_size * 0.5
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(card, "modulate:a", 0.0, 0.14).set_delay(i * 0.03)
		tw.parallel().tween_property(card, "position:y", card.position.y - 10.0, 0.14).set_delay(i * 0.03)
		tw.parallel().tween_property(card, "scale", Vector2(0.94, 0.94), 0.14).set_delay(i * 0.03)
	await get_tree().create_timer(0.14 + max(count - 1, 0) * 0.03 + 0.04).timeout
	_clear_cards()

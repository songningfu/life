extends Control

const GameStaticData = preload("res://scripts/GameStaticData.gd")
const ROOMMATE_DRAW_UI_SCENE: PackedScene = preload("res://scenes/ui/RoommateDrawUI.tscn")
const TOTAL_SELECTION_BUDGET := 9
const MAX_TALENT_PAID_REROLLS := 2
const MAJORS_PER_PAGE := 8
const BACKGROUNDS_PER_PAGE := 4

var current_page: int = 1
var total_pages: int = 6

var player_name: String = ""
var selected_gender: String = "male"
var selected_background: String = "normal"
var selected_university_tier: String = "low"
var selected_university_name: String = "临海学院"
var selected_major_id: String = "marketing"
var selected_major_profile: Dictionary = {}
var current_talents: Array = []
var talent_reroll_count: int = 0
var save_slot: int = -1
var _roommate_draw_ui: CanvasLayer = null
var _pending_init_data: Dictionary = {}

var pages: Array = []
var progress_dots: Array = []

@onready var intro_overlay: ColorRect = $IntroOverlay
@onready var intro_label: RichTextLabel = $IntroOverlay/IntroLabel
@onready var intro_hint: Label = $IntroOverlay/IntroHint
var intro_texts: Array = []
var intro_phase: int = 0
var intro_active: bool = false

var bg_buttons: Dictionary = {}
var university_buttons: Dictionary = {}
var major_buttons: Dictionary = {}
var major_page_index: int = 0
var bg_page_index: int = 0

# ──────────────────────────────────────────────
#  统一配色系统
# ──────────────────────────────────────────────
var colors := {
	# 主色
	"accent":        Color("#5aadff"),
	"accent_soft":   Color("#1e3352"),
	"accent_bright": Color("#8fd4ff"),
	"accent_glow":   Color("#3d8eff"),

	# 文字
	"text":          Color("#e8f0fa"),
	"text_secondary":Color("#b0bdd0"),
	"dim":           Color("#6b7d96"),
	"disabled_text": Color("#4a5568"),

	# 语义色
	"good":          Color("#6dd4a0"),
	"bad":           Color("#f0879d"),
	"warn":          Color("#ffc56d"),
	"info":          Color("#7ec8ff"),

	# 面板
	"bg_deep":       Color("#050a12"),
	"bg_base":       Color("#0a1120"),
	"panel":         Color("#0d1628"),
	"panel_hover":   Color("#12203a"),
	"panel_border":  Color("#1c3050"),
	"panel_border_bright": Color("#2a5080"),

	# 按钮
	"btn_primary":   Color("#3a7fd5"),
	"btn_secondary": Color("#283a52"),
	"btn_danger":    Color("#8b3a4a"),
}

# ──────────────────────────────────────────────
#  常量
# ──────────────────────────────────────────────
const CORNER_RADIUS := 14
const CARD_CORNER := 16
const PAGE_MARGIN_H := 56
const PAGE_MARGIN_V := 36
const SECTION_GAP := 20
const CARD_GAP := 14
const ANIM_DURATION := 0.35

# ──────────────────────────────────────────────
#  初始化
# ──────────────────────────────────────────────
func _ready() -> void:
	ModuleManager.ensure_modules_loaded()
	_init_pages()
	_init_progress_dots()
	_apply_global_layout()
	_style_all()
	_bind_events()

	if intro_overlay and not intro_overlay.gui_input.is_connected(_on_intro_input):
		intro_overlay.gui_input.connect(_on_intro_input)

	if SaveManager.has_temp("pending_char_creation_slot"):
		save_slot = SaveManager.get_temp("pending_char_creation_slot")
		SaveManager.store_temp("pending_char_creation_slot", null)

	selected_major_profile = GameStaticData.get_major_by_id(selected_major_id)
	_build_background_list()
	_build_university_list()
	_build_major_list()
	_update_budget_display()
	_update_selection_summary(3)
	_update_selection_summary(4)
	_update_selection_summary(5)
	_update_gender_selection()
	_show_page(1)
	_start_intro()

func _init_pages() -> void:
	pages = [
		$PageContainer/Page1_Name,
		$PageContainer/Page2_Gender,
		$PageContainer/Page3_Background,
		$PageContainer/Page4_University,
		$PageContainer/Page5_Major,
		$PageContainer/Page6_Talent,
	]

func _init_progress_dots() -> void:
	progress_dots = [
		$ProgressIndicator/Dot1,
		$ProgressIndicator/Dot2,
		$ProgressIndicator/Dot3,
		$ProgressIndicator/Dot4,
		$ProgressIndicator/Dot5,
		$ProgressIndicator/Dot6,
	]

# ──────────────────────────────────────────────
#  全局布局修复（所有页面锚点 + 填充）
# ──────────────────────────────────────────────
func _apply_global_layout() -> void:
	# 背景全屏
	var background := $Background
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.set_offsets_preset(Control.PRESET_FULL_RECT)

	# PageContainer 全屏
	var page_container := $PageContainer
	page_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_container.set_offsets_preset(Control.PRESET_FULL_RECT)

	# 每一页全屏
	for page in pages:
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		page.set_offsets_preset(Control.PRESET_FULL_RECT)

	# ProgressIndicator 顶部居中
	var progress := $ProgressIndicator
	progress.set_anchors_preset(Control.PRESET_CENTER_TOP)

	# IntroOverlay 全屏
	if intro_overlay:
		intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		intro_overlay.set_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Page1_Name 布局 ──
	_fix_simple_page_layout($PageContainer/Page1_Name, "VBox")

	# ── Page2_Gender 布局 ──
	_fix_simple_page_layout($PageContainer/Page2_Gender, "VBox")

	# ── Page3_Background 布局 ──
	_fix_scroll_page_layout($PageContainer/Page3_Background)
	_fix_page3_columns()

	# ── Page4_University 布局 ──
	_fix_scroll_page_layout($PageContainer/Page4_University)
	_fix_page4_layout()

	# ── Page5_Major 布局 ──
	_fix_scroll_page_layout($PageContainer/Page5_Major)
	_fix_page5_layout()

	# ── Page6_Talent 布局 ──
	_fix_scroll_page_layout($PageContainer/Page6_Talent)
	_fix_page6_layout()

func _fix_simple_page_layout(page: Control, vbox_name: String) -> void:
	# 修复没有 ScrollContainer 的简单页面
	var vbox := page.get_node_or_null(vbox_name)
	if vbox == null:
		return
	# 用 anchors 把 VBox 居中并限制最大宽度
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = PAGE_MARGIN_H
	vbox.offset_right = -PAGE_MARGIN_H
	vbox.offset_top = PAGE_MARGIN_V + 20
	vbox.offset_bottom = -PAGE_MARGIN_V
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", SECTION_GAP)

func _fix_scroll_page_layout(page: Control) -> void:
	# 修复带 ScrollContainer（MarginContainer）的页面
	var scroll := page.get_node_or_null("ScrollContainer") as MarginContainer
	if scroll == null:
		return
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.set_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_constant_override("margin_left", PAGE_MARGIN_H)
	scroll.add_theme_constant_override("margin_right", PAGE_MARGIN_H)
	scroll.add_theme_constant_override("margin_top", PAGE_MARGIN_V)
	scroll.add_theme_constant_override("margin_bottom", PAGE_MARGIN_V - 12)

	var vbox := scroll.get_node_or_null("VBox") as VBoxContainer
	if vbox:
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", SECTION_GAP)

func _fix_page3_columns() -> void:
	var vbox := $PageContainer/Page3_Background/ScrollContainer/VBox as VBoxContainer
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", SECTION_GAP)

	var summary := $PageContainer/Page3_Background/ScrollContainer/VBox/SelectionSummary as PanelContainer
	summary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summary.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	summary.custom_minimum_size = Vector2(764, 122)

	var header := $PageContainer/Page3_Background/ScrollContainer/VBox/SectionHeader as VBoxContainer
	header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_theme_constant_override("separation", 4)

	var grid := $PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundList as GridContainer
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	grid.custom_minimum_size = Vector2(764, 0)

	var pager := $PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager as HBoxContainer
	pager.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 16)

	var budget := $PageContainer/Page3_Background/ScrollContainer/VBox/BudgetBar as PanelContainer
	budget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	budget.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	budget.custom_minimum_size = Vector2(764, 84)

	var nav := $PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons as HBoxContainer
	nav.size_flags_vertical = Control.SIZE_SHRINK_END
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 28)

	var bottom := vbox.get_node_or_null("BottomSpacer")
	if bottom:
		bottom.custom_minimum_size = Vector2(0, 4)
		bottom.size_flags_vertical = Control.SIZE_SHRINK_END

func _fix_page4_layout() -> void:
	var vbox := $PageContainer/Page4_University/ScrollContainer/VBox as VBoxContainer
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", SECTION_GAP)

	var budget := $PageContainer/Page4_University/ScrollContainer/VBox/BudgetBar as PanelContainer
	budget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	budget.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	budget.custom_minimum_size = Vector2(764, 72)

	var summary := $PageContainer/Page4_University/ScrollContainer/VBox/SelectionSummary as PanelContainer
	summary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summary.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	summary.custom_minimum_size = Vector2(764, 118)

	var list := $PageContainer/Page4_University/ScrollContainer/VBox/UniversityList as VBoxContainer
	list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.custom_minimum_size = Vector2(764, 0)
	list.add_theme_constant_override("separation", CARD_GAP)

	var nav := $PageContainer/Page4_University/ScrollContainer/VBox/NavButtons as HBoxContainer
	nav.size_flags_vertical = Control.SIZE_SHRINK_END
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 28)

func _fix_page5_layout() -> void:
	var vbox := $PageContainer/Page5_Major/ScrollContainer/VBox as VBoxContainer
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", SECTION_GAP)

	var budget := $PageContainer/Page5_Major/ScrollContainer/VBox/BudgetBar as PanelContainer
	budget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	budget.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	budget.custom_minimum_size = Vector2(764, 72)

	var summary := $PageContainer/Page5_Major/ScrollContainer/VBox/SelectionSummary as PanelContainer
	summary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summary.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	summary.custom_minimum_size = Vector2(764, 118)

	var list := $PageContainer/Page5_Major/ScrollContainer/VBox/MajorList as GridContainer
	list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.custom_minimum_size = Vector2(1032, 0)
	list.columns = 4
	list.add_theme_constant_override("h_separation", CARD_GAP)
	list.add_theme_constant_override("v_separation", CARD_GAP)

	var pager := $PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager as HBoxContainer
	pager.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 16)

	var nav := $PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons as HBoxContainer
	nav.size_flags_vertical = Control.SIZE_SHRINK_END
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 28)

func _fix_page6_layout() -> void:
	var vbox := $PageContainer/Page6_Talent/ScrollContainer/VBox as VBoxContainer
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", SECTION_GAP)

	var budget := $PageContainer/Page6_Talent/ScrollContainer/VBox/BudgetBar as PanelContainer
	budget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	budget.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	budget.custom_minimum_size = Vector2(764, 72)

	var list := $PageContainer/Page6_Talent/ScrollContainer/VBox/TalentList as VBoxContainer
	list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.custom_minimum_size = Vector2(764, 0)
	list.add_theme_constant_override("separation", CARD_GAP)

	var roll_btn := $PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn as Button
	roll_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	roll_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	roll_btn.custom_minimum_size = Vector2(260, 56)

	var hint := $PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel as Label
	hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var nav := $PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons as HBoxContainer
	nav.size_flags_vertical = Control.SIZE_SHRINK_END
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 28)

	var bottom := vbox.get_node_or_null("BottomSpacer")
	if bottom:
		bottom.custom_minimum_size = Vector2(0, 4)
		bottom.size_flags_vertical = Control.SIZE_SHRINK_END

# ──────────────────────────────────────────────
#  Intro 序幕
# ──────────────────────────────────────────────
func _start_intro() -> void:
	intro_texts = [
		"[center][font_size=44][color=#d0d8e4]Subconscious Echo Studios[/color][/font_size]\n[font_size=22][color=#6b7d96]出品[/color][/font_size][/center]",
		"[center][font_size=40][color=#6ec6ff]致那些难忘的日子[/color][/font_size][/center]",
		"[center][font_size=48][color=#e8f0fa]高考之后[/color][/font_size]\n\n[font_size=22][color=#b0bdd0]风穿过走廊，\n把喧闹慢慢吹散。\n\n有人在笑，\n有人沉默，\n而时间已经往前走了。[/color][/font_size][/center]",
		"[center][font_size=44][color=#ffc56d]那个夏天[/color][/font_size]\n\n[font_size=22][color=#b0bdd0]蝉鸣很响，天很亮。\n查分、等待、失眠，\n你把未来想了很多遍，\n却还是站在故事开头。[/color][/font_size][/center]",
		"[center][font_size=44][color=#cfe3ff]后来你才明白[/color][/font_size]\n\n[font_size=22][color=#b0bdd0]很多告别没有配乐。\n它不说再见，\n只是在某个傍晚提醒你：\n有些日子，已经留在身后。[/color][/font_size][/center]",
		"[center][font_size=46][color=#8fd4ff]往前走吧[/color][/font_size]\n\n[font_size=24][color=#d0dcea]从今天起，\n你将用自己的选择，\n写下新的四年。[/color][/font_size][/center]",
	]
	intro_phase = 0
	intro_active = true
	intro_overlay.visible = true
	intro_overlay.modulate = Color(1, 1, 1, 1)
	intro_hint.text = "点击屏幕继续..."
	_show_intro_text(intro_texts[0])

func _show_intro_text(text: String) -> void:
	intro_label.clear()
	intro_label.append_text(text)
	intro_label.modulate = Color(1, 1, 1, 0)
	intro_label.scale = Vector2(0.985, 0.985)
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(intro_label, "modulate:a", 1.0, 0.7)
	tw.parallel().tween_property(intro_label, "scale", Vector2.ONE, 0.7)
	tw.parallel().tween_property(intro_hint, "modulate:a", 0.8, 0.5)

func _on_intro_input(event: InputEvent) -> void:
	if not intro_active:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		intro_phase += 1
		if intro_phase < intro_texts.size():
			var current_idx := intro_phase
			var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tw.parallel().tween_property(intro_label, "modulate:a", 0.0, 0.2)
			tw.parallel().tween_property(intro_label, "scale", Vector2(1.012, 1.012), 0.2)
			tw.parallel().tween_property(intro_hint, "modulate:a", 0.3, 0.15)
			tw.tween_callback(func():
				if current_idx < intro_texts.size():
					_show_intro_text(intro_texts[current_idx])
			)
		else:
			intro_active = false
			var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tw.tween_interval(0.25)
			tw.parallel().tween_property(intro_label, "modulate:a", 0.0, 0.4)
			tw.parallel().tween_property(intro_label, "scale", Vector2(1.015, 1.015), 0.4)
			tw.parallel().tween_property(intro_hint, "modulate:a", 0.0, 0.3)
			tw.parallel().tween_property(intro_overlay, "modulate:a", 0.0, 0.85)
			tw.tween_callback(func():
				intro_overlay.visible = false
			)

# ──────────────────────────────────────────────
#  统一样式系统
# ──────────────────────────────────────────────
func _style_all() -> void:
	$Background.color = colors.bg_deep

	# ── 所有页面的 Title / Subtitle ──
	for i in range(total_pages):
		var title = _find_title(pages[i])
		var subtitle = _find_subtitle(pages[i])
		if title:
			title.add_theme_font_size_override("font_size", 38)
			title.add_theme_color_override("font_color", colors.text)
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if subtitle:
			subtitle.add_theme_font_size_override("font_size", 17)
			subtitle.add_theme_color_override("font_color", colors.dim)
			subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Page1 姓名输入 ──
	var name_input := $PageContainer/Page1_Name/VBox/NameInput
	name_input.add_theme_font_size_override("font_size", 26)
	name_input.placeholder_text = "请输入你的名字..."
	_style_input(name_input)
	_style_btn($PageContainer/Page1_Name/VBox/NextBtn, colors.btn_primary, "下一步")

	# ── Page2 性别选择 ──
	var male_btn := $PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn
	var female_btn := $PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn
	male_btn.add_theme_font_size_override("font_size", 30)
	female_btn.add_theme_font_size_override("font_size", 30)
	var gender_btns := $PageContainer/Page2_Gender/VBox/GenderButtons as HBoxContainer
	gender_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	gender_btns.add_theme_constant_override("separation", 32)
	_style_nav_pair(
		$PageContainer/Page2_Gender/VBox/NavButtons,
		$PageContainer/Page2_Gender/VBox/NavButtons/BackBtn,
		$PageContainer/Page2_Gender/VBox/NavButtons/NextBtn
	)
	var gender_hint: Label = $PageContainer/Page2_Gender/VBox/SelectionHint
	gender_hint.add_theme_font_size_override("font_size", 15)
	gender_hint.add_theme_color_override("font_color", colors.dim)
	gender_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Page3 / Page4 / Page5 导航按钮 ──
	_style_nav_pair(
		$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons,
		$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/BackBtn,
		$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/NextBtn
	)
	_style_nav_pair(
		$PageContainer/Page4_University/ScrollContainer/VBox/NavButtons,
		$PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/BackBtn,
		$PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/NextBtn
	)
	_style_nav_pair(
		$PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons,
		$PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/BackBtn,
		$PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/NextBtn
	)
	_style_nav_pair(
		$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons,
		$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/BackBtn,
		$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/StartBtn
	)

	# ── Page3 背景页特有样式 ──
	_style_page3_details()

	# ── Page4 大学页 ──
	_style_page4_details()

	# ── Page5 专业页 ──
	_style_page5_details()

	# ── Page6 天赋页 ──
	_style_page6_details()

	# ── 所有 BudgetBar ──
	for budget_root in [
		$PageContainer/Page3_Background/ScrollContainer/VBox/BudgetBar,
		$PageContainer/Page4_University/ScrollContainer/VBox/BudgetBar,
		$PageContainer/Page5_Major/ScrollContainer/VBox/BudgetBar,
		$PageContainer/Page6_Talent/ScrollContainer/VBox/BudgetBar,
	]:
		_style_budget_bar(budget_root)

	# ── 所有 SelectionSummary ──
	var bg_summary := $PageContainer/Page3_Background/ScrollContainer/VBox/SelectionSummary
	_style_summary_panel(bg_summary)
	for summary_root in [
		$PageContainer/Page4_University/ScrollContainer/VBox/SelectionSummary,
		$PageContainer/Page5_Major/ScrollContainer/VBox/SelectionSummary,
	]:
		_style_summary_panel(summary_root)


	# ── 进度指示点 ──
	_style_progress_dots()

	# ── Intro ──
	intro_label.add_theme_font_size_override("normal_font_size", 28)
	intro_label.bbcode_enabled = true
	intro_label.fit_content = false
	intro_label.scroll_active = false
	intro_hint.add_theme_font_size_override("font_size", 15)
	intro_hint.add_theme_color_override("font_color", Color(0.68, 0.76, 0.88))
	intro_hint.modulate = Color(1, 1, 1, 0.75)

func _style_page3_details() -> void:
	var summary := $PageContainer/Page3_Background/ScrollContainer/VBox/SelectionSummary as PanelContainer
	if summary:
		_style_summary_panel(summary)
		var title := summary.get_node("Margin/VBox/SummaryTitle") as Label
		var body := summary.get_node("Margin/VBox/SummaryBody") as Label
		var impact := summary.get_node("Margin/VBox/SummaryImpact") as Label
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		impact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_theme_font_size_override("font_size", 16)
		impact.add_theme_font_size_override("font_size", 13)

	var section_title: Label = $PageContainer/Page3_Background/ScrollContainer/VBox/SectionHeader/SectionTitle
	var section_sub: Label = $PageContainer/Page3_Background/ScrollContainer/VBox/SectionHeader/SectionSubtitle
	section_title.add_theme_font_size_override("font_size", 22)
	section_title.add_theme_color_override("font_color", colors.text)
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_sub.add_theme_font_size_override("font_size", 14)
	section_sub.add_theme_color_override("font_color", colors.dim)
	section_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var page_label: Label = $PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/PageLabel
	page_label.add_theme_font_size_override("font_size", 15)
	page_label.add_theme_color_override("font_color", colors.text_secondary)

	_style_pager_btn($PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/PrevPageBtn)
	_style_pager_btn($PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/NextPageBtn)

func _style_page4_details() -> void:
	var summary := $PageContainer/Page4_University/ScrollContainer/VBox/SelectionSummary as PanelContainer
	if summary:
		_style_summary_panel(summary)
		var title := summary.get_node("Margin/VBox/SummaryTitle") as Label
		var body := summary.get_node("Margin/VBox/SummaryBody") as Label
		var impact := summary.get_node("Margin/VBox/SummaryImpact") as Label
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		impact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_theme_font_size_override("font_size", 16)
		impact.add_theme_font_size_override("font_size", 13)

	var list := $PageContainer/Page4_University/ScrollContainer/VBox/UniversityList as VBoxContainer
	if list:
		list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		list.add_theme_constant_override("separation", CARD_GAP)

func _style_page5_details() -> void:
	var summary := $PageContainer/Page5_Major/ScrollContainer/VBox/SelectionSummary as PanelContainer
	if summary:
		_style_summary_panel(summary)
		var title := summary.get_node("Margin/VBox/SummaryTitle") as Label
		var body := summary.get_node("Margin/VBox/SummaryBody") as Label
		var impact := summary.get_node("Margin/VBox/SummaryImpact") as Label
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		impact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_theme_font_size_override("font_size", 16)
		impact.add_theme_font_size_override("font_size", 13)

	var list := $PageContainer/Page5_Major/ScrollContainer/VBox/MajorList as GridContainer
	if list:
		list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		list.add_theme_constant_override("h_separation", CARD_GAP)
		list.add_theme_constant_override("v_separation", CARD_GAP)

	var page_label: Label = $PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PageLabel
	page_label.add_theme_font_size_override("font_size", 15)
	page_label.add_theme_color_override("font_color", colors.text_secondary)

	_style_pager_btn($PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PrevPageBtn)
	_style_pager_btn($PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/NextPageBtn)

	var pager := $PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager as HBoxContainer
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 16)

func _style_page6_details() -> void:
	var roll_btn := $PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn
	_style_btn(roll_btn, Color("#3d6dcc"), "免费抽取天赋")
	roll_btn.add_theme_font_size_override("font_size", 22)
	roll_btn.custom_minimum_size = Vector2(260, 56)

	var hint := $PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", colors.dim)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var talent_list := $PageContainer/Page6_Talent/ScrollContainer/VBox/TalentList as VBoxContainer
	if talent_list:
		talent_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		talent_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		talent_list.add_theme_constant_override("separation", CARD_GAP)

	$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/StartBtn.add_theme_font_size_override("font_size", 20)

func _style_progress_dots() -> void:
	for dot in progress_dots:
		var s := StyleBoxFlat.new()
		s.bg_color = Color("#1c2e44")
		s.set_corner_radius_all(6)
		dot.add_theme_stylebox_override("panel", s)
		dot.custom_minimum_size = Vector2(28, 6)

# ──────────────────────────────────────────────
#  辅助查找
# ──────────────────────────────────────────────
func _find_title(page: Node) -> Label:
	if page.has_node("VBox/Title"):
		return page.get_node("VBox/Title") as Label
	if page.has_node("ScrollContainer/VBox/Title"):
		return page.get_node("ScrollContainer/VBox/Title") as Label
	return null

func _find_subtitle(page: Node) -> Label:
	if page.has_node("VBox/Subtitle"):
		return page.get_node("VBox/Subtitle") as Label
	if page.has_node("ScrollContainer/VBox/Subtitle"):
		return page.get_node("ScrollContainer/VBox/Subtitle") as Label
	return null

# ──────────────────────────────────────────────
#  统一组件样式
# ──────────────────────────────────────────────
func _style_input(input: LineEdit) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = colors.bg_base
	s.set_corner_radius_all(CORNER_RADIUS)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 2
	s.border_color = colors.panel_border
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	input.add_theme_stylebox_override("normal", s)
	var f = s.duplicate()
	f.border_color = colors.accent
	f.border_width_bottom = 2
	input.add_theme_stylebox_override("focus", f)
	input.add_theme_color_override("font_color", colors.text)
	input.add_theme_color_override("font_placeholder_color", colors.dim)
	input.add_theme_color_override("caret_color", colors.accent_bright)

func _style_btn(btn: BaseButton, base_color: Color, label_text: String = "") -> void:
	if label_text != "" and btn is Button:
		btn.text = label_text if btn.text.is_empty() else btn.text

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.content_margin_top = 13
	normal.content_margin_bottom = 13
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = base_color.lightened(0.1)
	normal.shadow_size = 6
	normal.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.14)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = base_color.lightened(0.1)
	hover.border_color = base_color.lightened(0.2)
	hover.shadow_size = 10
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = base_color.darkened(0.08)
	pressed.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate()
	disabled.bg_color = colors.btn_secondary.darkened(0.2)
	disabled.border_color = Color("#2a3344")
	disabled.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", colors.text)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", colors.text_secondary)
	btn.add_theme_color_override("font_disabled_color", colors.disabled_text)

func _style_pager_btn(btn: BaseButton) -> void:
	_style_btn(btn, colors.btn_secondary)
	btn.add_theme_font_size_override("font_size", 15)

func _style_nav_pair(container: HBoxContainer, back_btn: BaseButton, next_btn: BaseButton) -> void:
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 28)
	_style_btn(back_btn, colors.btn_secondary)
	_style_btn(next_btn, colors.btn_primary)

func _style_summary_panel(root: PanelContainer) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = colors.panel
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = colors.panel_border
	panel.set_corner_radius_all(CARD_CORNER)
	panel.content_margin_left = 4
	panel.content_margin_right = 4
	panel.content_margin_top = 4
	panel.content_margin_bottom = 4
	root.add_theme_stylebox_override("panel", panel)

	var title := root.get_node("Margin/VBox/SummaryTitle") as Label
	var body := root.get_node("Margin/VBox/SummaryBody") as Label
	var impact := root.get_node("Margin/VBox/SummaryImpact") as Label
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", colors.dim)
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", colors.text)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	impact.add_theme_font_size_override("font_size", 14)
	impact.add_theme_color_override("font_color", colors.accent_bright)
	impact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _style_info_panel(root: PanelContainer) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(colors.panel.r, colors.panel.g, colors.panel.b, 0.85)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = colors.panel_border
	panel.set_corner_radius_all(CARD_CORNER)
	root.add_theme_stylebox_override("panel", panel)

func _style_budget_bar(root: PanelContainer) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = colors.panel
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = colors.panel_border
	panel.set_corner_radius_all(CORNER_RADIUS)
	panel.content_margin_left = 22
	panel.content_margin_right = 22
	panel.content_margin_top = 14
	panel.content_margin_bottom = 14
	root.add_theme_stylebox_override("panel", panel)

	var title: Label = root.get_node_or_null("VBox/HeaderRow/BudgetTitle") as Label
	if title == null:
		title = root.get_node_or_null("HBox/BudgetTitle") as Label
	var value: Label = root.get_node_or_null("VBox/HeaderRow/BudgetValue") as Label
	if value == null:
		value = root.get_node_or_null("HBox/BudgetValue") as Label
	var hint: Label = root.get_node_or_null("VBox/HeaderRow/BudgetHint") as Label
	if hint == null:
		hint = root.get_node_or_null("HBox/BudgetHint") as Label

	if title != null:
		title.add_theme_color_override("font_color", colors.dim)
		title.add_theme_font_size_override("font_size", 14)
	if value != null:
		value.add_theme_color_override("font_color", colors.warn)
		value.add_theme_font_size_override("font_size", 20)
	if hint != null:
		hint.add_theme_color_override("font_color", colors.dim)
		hint.add_theme_font_size_override("font_size", 13)

	var meter := root.get_node_or_null("VBox/BudgetMeter") as ProgressBar
	if meter != null:
		meter.add_theme_constant_override("outline_size", 0)
		meter.custom_minimum_size.y = 8
		meter.add_theme_stylebox_override("background", _make_meter_bg())
		meter.add_theme_stylebox_override("fill", _make_meter_fill())

func _make_meter_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = colors.bg_base
	s.border_width_left = 1; s.border_width_top = 1
	s.border_width_right = 1; s.border_width_bottom = 1
	s.border_color = colors.panel_border
	s.set_corner_radius_all(999)
	return s

func _make_meter_fill() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = colors.accent
	s.border_width_left = 0; s.border_width_top = 0
	s.border_width_right = 0; s.border_width_bottom = 0
	s.set_corner_radius_all(999)
	return s

func _style_select_card(btn: Button, selected: bool, is_disabled: bool = false, accent: Color = Color.TRANSPARENT) -> void:
	if accent == Color.TRANSPARENT:
		accent = colors.accent

	var s := StyleBoxFlat.new()
	if is_disabled:
		s.bg_color = Color("#080d16")
	elif selected:
		s.bg_color = Color("#142840")
	else:
		s.bg_color = colors.panel
	s.border_width_left = 2; s.border_width_top = 2
	s.border_width_right = 2; s.border_width_bottom = 2
	if is_disabled:
		s.border_color = Color("#151d2a")
	elif selected:
		s.border_color = accent
	else:
		s.border_color = colors.panel_border
	s.set_corner_radius_all(CARD_CORNER)
	s.content_margin_left = 18; s.content_margin_right = 18
	s.content_margin_top = 16; s.content_margin_bottom = 16
	if selected:
		s.shadow_size = 12
		s.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	else:
		s.shadow_size = 0
	btn.add_theme_stylebox_override("normal", s)

	var h = s.duplicate()
	if not is_disabled:
		h.bg_color = colors.panel_hover if not selected else Color("#1a3350")
		h.border_color = accent.darkened(0.15) if not selected else accent
	btn.add_theme_stylebox_override("hover", h)

	var p = s.duplicate()
	p.bg_color = Color("#0e1e32")
	btn.add_theme_stylebox_override("pressed", p)

	var d = s.duplicate()
	d.bg_color = Color("#080d16")
	d.border_color = Color("#151d2a")
	d.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", d)

	btn.add_theme_color_override("font_color", colors.text if not is_disabled else colors.disabled_text)
	btn.add_theme_color_override("font_hover_color", colors.text)
	btn.add_theme_color_override("font_disabled_color", colors.disabled_text)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.expand_icon = false
	btn.disabled = is_disabled

func _style_gender_card(btn: Button, base_color: Color, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = base_color if selected else base_color.darkened(0.55)
	s.border_width_left = 2; s.border_width_top = 2
	s.border_width_right = 2; s.border_width_bottom = 2
	s.border_color = colors.text if selected else base_color.darkened(0.25)
	s.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.25) if selected else Color(0,0,0,0)
	s.shadow_size = 16 if selected else 0
	s.set_corner_radius_all(18)
	s.content_margin_left = 36; s.content_margin_right = 36
	s.content_margin_top = 24; s.content_margin_bottom = 24
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = base_color.lightened(0.06)
	btn.add_theme_stylebox_override("hover", h)
	var p = s.duplicate()
	p.bg_color = base_color.darkened(0.06)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color.WHITE if selected else Color("#c8d6e8"))

# ──────────────────────────────────────────────
#  格式化文本
# ──────────────────────────────────────────────
func _format_budget_text(cost: int) -> String:
	return "分配点数 -%d" % cost

func _format_background_text(bg_id: String) -> String:
	var bg: Dictionary = GameStaticData.get_background(bg_id)
	var impact_lines := _get_background_card_impacts(bg_id)
	var impact_text := " · ".join(impact_lines) if not impact_lines.is_empty() else "整体较均衡"
	return "%s  ·  %s\n%s\n%s\n%s" % [
		str(bg.get("name", "")),
		_format_budget_text(int(bg.get("cost", 0))),
		str(bg.get("route_tag", "")),
		impact_text,
		str(bg.get("tradeoff", "")),
	]

func _format_university_text(option: Dictionary) -> String:
	return "%s · %s\n%s\n%s · %s / %s" % [
		_tier_str(str(option.get("tier", ""))),
		str(option.get("name", "")),
		str(option.get("desc", "")),
		_format_budget_text(int(option.get("cost", 0))),
		str(option.get("route_tag", "")),
		str(option.get("difficulty_tag", "")),
	]

func _format_major_text(major: Dictionary) -> String:
	return "%s\n%s\n%s · %s · %s学分" % [
		str(major.get("name", "")),
		str(major.get("desc", "")),
		_format_budget_text(int(major.get("cost", 0))),
		str(major.get("route_tag", "")),
		str(major.get("required_credits", 0)),
	]

func _format_page3_summary(bg_id: String) -> Dictionary:
	var bg := GameStaticData.get_background(bg_id)
	var bg_lines := GameStaticData.get_background_impact_summary(bg_id)
	return {
		"body": "%s · %s\n%s" % [str(bg.get("name", "")), str(bg.get("route_tag", "")), str(bg.get("tradeoff", ""))],
		"impact": "影响：%s" % (" / ".join(bg_lines) if not bg_lines.is_empty() else "整体较均衡"),
	}

func _format_selection_summary(page_idx: int) -> Dictionary:
	match page_idx:
		3:
			return _format_page3_summary(selected_background)
		4:
			var uni := GameStaticData.get_university_by_tier(selected_university_tier)
			return {
				"body": "%s · %s\n%s" % [_tier_str(selected_university_tier), selected_university_name, str(uni.get("desc", ""))],
				"impact": "%s / %s / 分配点数 -%d" % [str(uni.get("route_tag", "")), str(uni.get("difficulty_tag", "")), int(uni.get("cost", 0))],
			}
		5:
			var major := GameStaticData.get_major_by_id(selected_major_id)
			return {
				"body": "%s\n%s" % [str(major.get("name", "")), str(major.get("desc", ""))],
				"impact": "%s 学分 / 难度 x%s / 分配点数 -%d / %s" % [str(major.get("required_credits", 0)), str(major.get("exam_difficulty", 1.0)), int(major.get("cost", 0)), str(major.get("route_tag", ""))],
			}
		_:
			return {"body": "", "impact": ""}

func _update_selection_summary(page_idx: int) -> void:
	var root_path := "PageContainer/Page%d_%s/ScrollContainer/VBox/SelectionSummary" % [page_idx, "Background" if page_idx == 3 else "University" if page_idx == 4 else "Major"]
	if not has_node(root_path):
		return
	var root := get_node(root_path) as PanelContainer
	var body := root.get_node("Margin/VBox/SummaryBody") as Label
	var impact := root.get_node("Margin/VBox/SummaryImpact") as Label
	var data := _format_selection_summary(page_idx)
	body.text = str(data.get("body", ""))
	impact.text = str(data.get("impact", ""))

# ──────────────────────────────────────────────
#  事件绑定
# ──────────────────────────────────────────────
func _bind_events() -> void:
	$PageContainer/Page1_Name/VBox/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn.pressed.connect(func(): _select_gender("male"))
	$PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn.pressed.connect(func(): _select_gender("female"))
	$PageContainer/Page2_Gender/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page2_Gender/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page3_Background/ScrollContainer/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page4_University/ScrollContainer/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page5_Major/ScrollContainer/VBox/NavButtons/NextBtn.pressed.connect(func(): _next_page())
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PrevPageBtn.pressed.connect(_prev_major_page)
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/NextPageBtn.pressed.connect(_next_major_page)
	$PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/PrevPageBtn.pressed.connect(_prev_bg_page)
	$PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/NextPageBtn.pressed.connect(_next_bg_page)
	$PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn.pressed.connect(_roll_talents)
	$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/BackBtn.pressed.connect(func(): _prev_page())
	$PageContainer/Page6_Talent/ScrollContainer/VBox/NavButtons/StartBtn.pressed.connect(_start_game)

# ──────────────────────────────────────────────
#  页面切换（带统一过渡动画）
# ──────────────────────────────────────────────
func _show_page(page: int) -> void:
	current_page = page
	for i in range(total_pages):
		pages[i].visible = (i == page - 1)
	_update_progress_dots()
	_update_budget_display()
	if page >= 3 and page <= 5:
		_update_selection_summary(page)
	match page:
		3:
			_update_bg_selection()
		4:
			_update_university_selection()
		5:
			_update_major_selection()

	# 统一入场动画
	var target: Control = pages[page - 1] as Control
	target.modulate = Color(1, 1, 1, 0)
	target.position.y = 12
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(target, "modulate:a", 1.0, ANIM_DURATION)
	tw.parallel().tween_property(target, "position:y", 0.0, ANIM_DURATION)

func _next_page() -> void:
	if current_page == 1:
		var name_input: LineEdit = $PageContainer/Page1_Name/VBox/NameInput
		var input_name: String = name_input.text.strip_edges()
		if input_name.length() == 0:
			_shake_node(name_input)
			return
		player_name = input_name
	if current_page == 5 and selected_major_profile.is_empty():
		return
	if current_page < total_pages:
		_show_page(current_page + 1)

func _prev_page() -> void:
	if current_page > 1:
		_show_page(current_page - 1)

func _shake_node(node: Control) -> void:
	# 输入验证失败时的抖动反馈
	var original_x := node.position.x
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "position:x", original_x + 8, 0.05)
	tw.tween_property(node, "position:x", original_x - 8, 0.05)
	tw.tween_property(node, "position:x", original_x + 5, 0.05)
	tw.tween_property(node, "position:x", original_x - 5, 0.05)
	tw.tween_property(node, "position:x", original_x, 0.05)

func _update_progress_dots() -> void:
	for i in range(total_pages):
		var s := StyleBoxFlat.new()
		if i == current_page - 1:
			s.bg_color = colors.accent_bright
			progress_dots[i].custom_minimum_size = Vector2(36, 6)
		elif i < current_page:
			s.bg_color = colors.accent
			progress_dots[i].custom_minimum_size = Vector2(28, 6)
		else:
			s.bg_color = Color("#1c2e44")
			progress_dots[i].custom_minimum_size = Vector2(28, 6)
		s.set_corner_radius_all(6)
		progress_dots[i].add_theme_stylebox_override("panel", s)

# ──────────────────────────────────────────────
#  性别
# ──────────────────────────────────────────────
func _select_gender(gender: String) -> void:
	selected_gender = gender
	($PageContainer/Page2_Gender/VBox/SelectionHint as Label).text = "当前身份：%s" % ("男生" if gender == "male" else "女生")
	if gender == "female":
		_show_toast("女性角色开发中，敬请期待~", colors.warn)
	_update_gender_selection()

func _update_gender_selection() -> void:
	var male_btn: Button = $PageContainer/Page2_Gender/VBox/GenderButtons/MaleBtn
	var female_btn: Button = $PageContainer/Page2_Gender/VBox/GenderButtons/FemaleBtn
	_style_gender_card(male_btn, Color("#3a6ec0"), selected_gender == "male")
	_style_gender_card(female_btn, Color("#b8486e"), selected_gender == "female")

func _show_toast(text: String, color: Color = Color.WHITE) -> void:
	# 统一的 toast 提示
	var toast := Label.new()
	toast.text = text
	toast.add_theme_color_override("font_color", color)
	toast.add_theme_font_size_override("font_size", 17)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_top = -80
	toast.modulate = Color(1, 1, 1, 0)
	add_child(toast)
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.8)
	tw.tween_property(toast, "modulate:a", 0.0, 0.6)
	tw.tween_callback(toast.queue_free)

# ──────────────────────────────────────────────
#  分配点数系统
# ──────────────────────────────────────────────
func _get_background_cost(bg_id: String) -> int:
	return GameStaticData.get_background_cost(bg_id)

func _get_university_cost(tier: String) -> int:
	return int(GameStaticData.get_university_by_tier(tier).get("cost", 0))

func _get_major_cost(major_id: String) -> int:
	return int(GameStaticData.get_major_by_id(major_id).get("cost", 0))

func _get_budget_spent() -> int:
	return _get_background_cost(selected_background) + _get_university_cost(selected_university_tier) + _get_major_cost(selected_major_id)

func _get_budget_left() -> int:
	return TOTAL_SELECTION_BUDGET - _get_budget_spent()

func _can_afford_change(category: String, next_cost: int) -> bool:
	var current_cost := 0
	match category:
		"background":
			current_cost = _get_background_cost(selected_background)
		"university":
			current_cost = _get_university_cost(selected_university_tier)
		"major":
			current_cost = _get_major_cost(selected_major_id)
	return _get_budget_spent() - current_cost + next_cost <= TOTAL_SELECTION_BUDGET

func _can_reroll_talents() -> bool:
	return current_talents.size() == 0 or talent_reroll_count < MAX_TALENT_PAID_REROLLS

func _set_budget_hint(page_idx: int, text: String, color: Color) -> void:
	var path := ""
	if page_idx == 3:
		path = "PageContainer/Page3_Background/ScrollContainer/VBox/BudgetBar/VBox/HeaderRow/BudgetHint"
	elif page_idx == 4:
		path = "PageContainer/Page4_University/ScrollContainer/VBox/BudgetBar/HBox/BudgetHint"
	elif page_idx == 5:
		path = "PageContainer/Page5_Major/ScrollContainer/VBox/BudgetBar/HBox/BudgetHint"
	elif page_idx == 6:
		path = "PageContainer/Page6_Talent/ScrollContainer/VBox/BudgetBar/HBox/BudgetHint"
	var label := get_node_or_null(path) as Label
	if label == null:
		return
	label.text = text
	label.add_theme_color_override("font_color", color)

func _update_budget_display() -> void:
	var spent := _get_budget_spent()
	var left := _get_budget_left()
	for path in [
		"PageContainer/Page3_Background/ScrollContainer/VBox/BudgetBar/VBox/HeaderRow/BudgetValue",
		"PageContainer/Page4_University/ScrollContainer/VBox/BudgetBar/HBox/BudgetValue",
		"PageContainer/Page5_Major/ScrollContainer/VBox/BudgetBar/HBox/BudgetValue",
	]:
		var label := get_node_or_null(path) as Label
		if label == null:
			continue
		label.text = "%d / %d" % [spent, TOTAL_SELECTION_BUDGET]
		label.add_theme_color_override("font_color", colors.warn if left <= 2 else colors.accent_bright)

	var bg_meter := $PageContainer/Page3_Background/ScrollContainer/VBox/BudgetBar/VBox/BudgetMeter as ProgressBar
	bg_meter.max_value = TOTAL_SELECTION_BUDGET
	bg_meter.value = spent

	_set_budget_hint(3, "剩余分配点数 %d · 先决定出身基底" % left, colors.dim)
	_set_budget_hint(4, "剩余分配点数 %d · 院校越高压通常越贵" % left, colors.dim)
	_set_budget_hint(5, "剩余分配点数 %d · 专业决定长期负荷" % left, colors.dim)

	var reroll_value := get_node_or_null("PageContainer/Page6_Talent/ScrollContainer/VBox/BudgetBar/HBox/BudgetValue") as Label
	if reroll_value != null:
		reroll_value.text = "%d / %d" % [talent_reroll_count, MAX_TALENT_PAID_REROLLS]
		reroll_value.add_theme_color_override("font_color", colors.warn if talent_reroll_count >= MAX_TALENT_PAID_REROLLS else colors.accent_bright)

	var roll_btn := $PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn as Button
	if current_talents.is_empty():
		roll_btn.text = "免费抽取天赋"
		roll_btn.disabled = false
		_set_budget_hint(6, "首次抽取免费 · 还可重抽 %d 次" % MAX_TALENT_PAID_REROLLS, colors.dim)
	elif talent_reroll_count >= MAX_TALENT_PAID_REROLLS:
		roll_btn.text = "重抽次数已用完"
		roll_btn.disabled = true
		_set_budget_hint(6, "天赋不占分配点数 · 已完成 %d 次重抽" % MAX_TALENT_PAID_REROLLS, colors.warn)
	else:
		roll_btn.text = "重新抽取天赋"
		roll_btn.disabled = false
		_set_budget_hint(6, "天赋不占分配点数 · 还可重抽 %d 次" % [MAX_TALENT_PAID_REROLLS - talent_reroll_count], colors.dim)

# ──────────────────────────────────────────────
#  Page3 背景列表
# ──────────────────────────────────────────────
func _build_background_list() -> void:
	bg_page_index = 0
	_render_background_page()

func _get_background_ids() -> Array[String]:
	var ids: Array[String] = []
	for bg_id in GameStaticData.BACKGROUNDS.keys():
		ids.append(str(bg_id))
	ids.sort()
	return ids

func _render_background_page() -> void:
	var list := $PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundList
	for child in list.get_children():
		child.queue_free()
	bg_buttons.clear()

	var background_ids := _get_background_ids()
	var start_index := bg_page_index * BACKGROUNDS_PER_PAGE
	var end_index := mini(start_index + BACKGROUNDS_PER_PAGE, background_ids.size())
	for i in range(start_index, end_index):
		var bg_id := background_ids[i]
		var card := _create_background_card(bg_id)
		list.add_child(card)
		bg_buttons[bg_id] = card

	var total_bg_pages := maxi(1, int(ceil(float(background_ids.size()) / float(BACKGROUNDS_PER_PAGE))))
	var page_label: Label = $PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/PageLabel
	page_label.text = "第 %d / %d 组" % [bg_page_index + 1, total_bg_pages]
	$PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/PrevPageBtn.visible = bg_page_index > 0
	$PageContainer/Page3_Background/ScrollContainer/VBox/BackgroundPager/NextPageBtn.visible = bg_page_index < total_bg_pages - 1
	_update_bg_selection()
	_on_bg_hovered(selected_background)

func _create_background_card(bg_id: String) -> Button:
	var bg: Dictionary = GameStaticData.get_background(bg_id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(375, 160)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.clip_text = false
	btn.focus_mode = Control.FOCUS_ALL
	btn.text = _format_background_text(bg_id)
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(_on_bg_selected.bind(bg_id))
	btn.mouse_entered.connect(_on_bg_hovered.bind(bg_id))
	btn.focus_entered.connect(_on_bg_hovered.bind(bg_id))
	var icon_path := str(bg.get("icon_path", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
		btn.expand_icon = false
	_style_select_card(btn, false)
	return btn

func _on_bg_hovered(bg_id: String) -> void:
	var root := get_node_or_null("PageContainer/Page3_Background/ScrollContainer/VBox/SelectionSummary") as PanelContainer
	if root == null:
		return
	var body := root.get_node("Margin/VBox/SummaryBody") as Label
	var impact := root.get_node("Margin/VBox/SummaryImpact") as Label
	var data := _format_page3_summary(bg_id)
	body.text = str(data.get("body", ""))
	impact.text = str(data.get("impact", ""))

func _prev_bg_page() -> void:
	if bg_page_index <= 0:
		return
	bg_page_index -= 1
	_render_background_page()

func _next_bg_page() -> void:
	var total_bg_pages := maxi(1, int(ceil(float(_get_background_ids().size()) / float(BACKGROUNDS_PER_PAGE))))
	if bg_page_index >= total_bg_pages - 1:
		return
	bg_page_index += 1
	_render_background_page()

func _get_background_card_impacts(bg_id: String) -> Array[String]:
	var all_lines := GameStaticData.get_background_impact_summary(bg_id)
	if all_lines.size() <= 3:
		return all_lines
	return all_lines.slice(0, 3)

func _on_bg_selected(bg_id: String) -> void:
	var next_cost := _get_background_cost(bg_id)
	if not _can_afford_change("background", next_cost):
		_set_budget_hint(3, "分配点数不够，换个更省的出身或先调整院校/专业", colors.warn)
		_show_toast("分配点数不足", colors.warn)
		return
	selected_background = bg_id
	_update_bg_selection()
	_update_selection_summary(3)
	_update_university_selection()
	_render_major_page()
	_update_budget_display()

func _update_bg_selection() -> void:
	for id in bg_buttons:
		var btn: Button = bg_buttons[id]
		var disabled := not _can_afford_change("background", _get_background_cost(id))
		_style_select_card(btn, id == selected_background, disabled, colors.accent)

# ──────────────────────────────────────────────
#  Page4 大学列表
# ──────────────────────────────────────────────
func _build_university_list() -> void:
	var list := $PageContainer/Page4_University/ScrollContainer/VBox/UniversityList
	for child in list.get_children():
		child.queue_free()
	university_buttons.clear()
	for option in GameStaticData.UNIVERSITY_OPTIONS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(764, 108)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.clip_text = false
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = _format_university_text(option)
		btn.pressed.connect(_on_university_selected.bind(option.get("tier", ""), option.get("name", "")))
		list.add_child(btn)
		university_buttons[option.get("tier", "")] = btn
		_style_select_card(btn, false)
	_update_university_selection()

func _on_university_selected(tier: String, school_name: String) -> void:
	var next_cost := _get_university_cost(tier)
	if not _can_afford_change("university", next_cost):
		_set_budget_hint(4, "分配点数不够，先降一点背景或专业路线", colors.warn)
		_show_toast("分配点数不足", colors.warn)
		return
	selected_university_tier = tier
	selected_university_name = school_name
	_update_bg_selection()
	_update_university_selection()
	_update_selection_summary(4)
	_render_major_page()
	_update_budget_display()

func _update_university_selection() -> void:
	for tier in university_buttons:
		var btn: Button = university_buttons[tier]
		var disabled := not _can_afford_change("university", _get_university_cost(tier))
		_style_select_card(btn, tier == selected_university_tier, disabled, colors.accent)

# ──────────────────────────────────────────────
#  Page5 专业列表
# ──────────────────────────────────────────────
func _build_major_list() -> void:
	major_page_index = 0
	selected_major_profile = GameStaticData.get_major_by_id(selected_major_id)
	_render_major_page()

func _render_major_page() -> void:
	var list := $PageContainer/Page5_Major/ScrollContainer/VBox/MajorList
	for child in list.get_children():
		child.queue_free()
	major_buttons.clear()

	var start_index := major_page_index * MAJORS_PER_PAGE
	var end_index := mini(start_index + MAJORS_PER_PAGE, GameStaticData.MAJOR_OPTIONS.size())

	for i in range(start_index, end_index):
		var major: Dictionary = GameStaticData.MAJOR_OPTIONS[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(247, 108)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.clip_text = false
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 12)
		btn.text = _format_major_text(major)
		btn.pressed.connect(_on_major_selected.bind(major.get("id", "")))
		list.add_child(btn)
		major_buttons[major.get("id", "")] = btn
		_style_select_card(btn, false)

	var page_label: Label = $PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PageLabel
	var total_major_pages := maxi(1, int(ceil(float(GameStaticData.MAJOR_OPTIONS.size()) / float(MAJORS_PER_PAGE))))
	page_label.text = "第 %d / %d 组" % [major_page_index + 1, total_major_pages]
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/PrevPageBtn.visible = major_page_index > 0
	$PageContainer/Page5_Major/ScrollContainer/VBox/MajorPager/NextPageBtn.visible = major_page_index < total_major_pages - 1
	_update_major_selection()
	_update_selection_summary(5)

func _on_major_selected(major_id: String) -> void:
	var next_cost := _get_major_cost(major_id)
	if not _can_afford_change("major", next_cost):
		_set_budget_hint(5, "分配点数不够，这个专业需要你从别处省一点", colors.warn)
		_show_toast("分配点数不足", colors.warn)
		return
	selected_major_id = major_id
	selected_major_profile = GameStaticData.get_major_by_id(major_id)
	_update_bg_selection()
	_update_university_selection()
	_update_major_selection()
	_update_selection_summary(5)
	_update_budget_display()

func _update_major_selection() -> void:
	for id in major_buttons:
		var btn: Button = major_buttons[id]
		var disabled := not _can_afford_change("major", _get_major_cost(id))
		_style_select_card(btn, id == selected_major_id, disabled, colors.accent)

func _prev_major_page() -> void:
	if major_page_index <= 0:
		return
	major_page_index -= 1
	_render_major_page()

func _next_major_page() -> void:
	var total_major_pages := maxi(1, int(ceil(float(GameStaticData.MAJOR_OPTIONS.size()) / float(MAJORS_PER_PAGE))))
	if major_page_index >= total_major_pages - 1:
		return
	major_page_index += 1
	_render_major_page()

func _tier_str(t: String) -> String:
	match t:
		"985":   return "985高校"
		"normal": return "普通一本"
		"low":   return "二本院校"
		_:       return "大学"

# ──────────────────────────────────────────────
#  Page6 天赋
# ──────────────────────────────────────────────
func _roll_talents() -> void:
	var talent_module: TalentModule = null
	if ModuleManager:
		talent_module = ModuleManager.get_module("talent") as TalentModule

	if not talent_module:
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "天赋模块未加载，暂时无法抽取天赋"
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.bad)
		return

	var is_first_roll := current_talents.is_empty()
	if not is_first_roll:
		if talent_reroll_count >= MAX_TALENT_PAID_REROLLS:
			$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "天赋重抽次数已用完"
			$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.warn)
			_update_budget_display()
			return
		talent_reroll_count += 1

	current_talents = talent_module.roll_talents()
	_display_talents()
	if is_first_roll:
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "首次抽取免费，后续还可再重抽 2 次"
	else:
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "本次重抽不消耗分配点数，确认后进入舍友抽取"
	$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.dim)
	_update_budget_display()

func _display_talents() -> void:
	var list := $PageContainer/Page6_Talent/ScrollContainer/VBox/TalentList
	for child in list.get_children():
		child.queue_free()

	for t: Dictionary in current_talents:
		var card := PanelContainer.new()
		var is_good: bool = str(t.get("type", "bad")) == "good"
		card.custom_minimum_size = Vector2(764, 0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

		var s := StyleBoxFlat.new()
		s.bg_color = Color("#102338") if is_good else Color("#1a1522")
		s.border_width_left = 2
		s.border_width_top = 2
		s.border_width_right = 2
		s.border_width_bottom = 2
		s.border_color = colors.good if is_good else colors.bad
		s.set_corner_radius_all(CARD_CORNER)
		s.content_margin_left = 20
		s.content_margin_right = 20
		s.content_margin_top = 16
		s.content_margin_bottom = 16
		s.shadow_size = 10
		s.shadow_color = Color((colors.good if is_good else colors.bad).r, (colors.good if is_good else colors.bad).g, (colors.good if is_good else colors.bad).b, 0.12)
		card.add_theme_stylebox_override("panel", s)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)

		var top_row := HBoxContainer.new()
		top_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		top_row.add_theme_constant_override("separation", 10)
		vbox.add_child(top_row)

		var name_lbl := Label.new()
		name_lbl.text = str(t.get("name", "未知天赋"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 19)
		name_lbl.add_theme_color_override("font_color", colors.text)
		top_row.add_child(name_lbl)

		var tag_lbl := Label.new()
		tag_lbl.text = "增益" if is_good else "减益"
		tag_lbl.add_theme_font_size_override("font_size", 13)
		tag_lbl.add_theme_color_override("font_color", colors.good if is_good else colors.bad)
		top_row.add_child(tag_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(t.get("desc", ""))
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", colors.text_secondary)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)

		list.add_child(card)

		card.modulate = Color(1, 1, 1, 0)
		card.position.x = 20
		var idx := list.get_child_count() - 1
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_interval(idx * 0.08)
		tw.parallel().tween_property(card, "modulate:a", 1.0, 0.3)
		tw.parallel().tween_property(card, "position:x", 0.0, 0.3)

# ──────────────────────────────────────────────
#  开始游戏
# ──────────────────────────────────────────────
func _start_game() -> void:
	if current_talents.size() == 0:
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "请先抽取天赋！"
		$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.accent_bright)
		_shake_node($PageContainer/Page6_Talent/ScrollContainer/VBox/RollBtn)
		return

	var talent_module: TalentModule = null
	if ModuleManager:
		talent_module = ModuleManager.get_module("talent") as TalentModule
	if talent_module:
		talent_module.set_talents(current_talents)

	NamePool.init_new_game()

	_pending_init_data = {
		"player_name": player_name,
		"player_gender": selected_gender,
		"save_slot": save_slot,
		"is_new_game": true,
		"background": selected_background,
		"university_tier": selected_university_tier,
		"university_name": selected_university_name,
		"major_id": selected_major_id,
		"major_profile": selected_major_profile.duplicate(true),
		"selection_budget_spent": _get_budget_spent(),
		"selection_budget_left": _get_budget_left(),
		"talents": current_talents.duplicate(true),
	}

	_start_roommate_draw()

func _start_roommate_draw() -> void:
	if _roommate_draw_ui != null:
		_roommate_draw_ui.queue_free()
	_roommate_draw_ui = ROOMMATE_DRAW_UI_SCENE.instantiate() as CanvasLayer
	add_child(_roommate_draw_ui)
	if not _roommate_draw_ui.draw_completed.is_connected(_on_roommates_drawn):
		_roommate_draw_ui.draw_completed.connect(_on_roommates_drawn)
	if not _roommate_draw_ui.draw_cancelled.is_connected(_on_roommate_draw_cancelled):
		_roommate_draw_ui.draw_cancelled.connect(_on_roommate_draw_cancelled)
	_roommate_draw_ui.start_draw()

func _on_roommates_drawn(roommates: Array, draw_summary: Dictionary) -> void:
	SaveManager.set_roommates(roommates)
	var final_init_data: Dictionary = _pending_init_data.duplicate(true)
	final_init_data["roommates"] = roommates.duplicate(true)
	final_init_data["roommate_draw_summary"] = draw_summary.duplicate(true)
	SaveManager.store_temp("pending_game_init", final_init_data)
	if ModuleManager:
		var achievement_module := ModuleManager.get_module("achievement")
		if achievement_module and achievement_module.has_method("add_counter"):
			achievement_module.add_counter("roommate_draw_total", int(draw_summary.get("draw_count", 0)))
			achievement_module.add_counter("roommate_ssr_total", int(draw_summary.get("ssr_draw_count", 0)))
	SceneTransitions.creation_to_game()

func _on_roommate_draw_cancelled() -> void:
	$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.text = "已取消抽舍友，可重新开始抽取"
	$PageContainer/Page6_Talent/ScrollContainer/VBox/HintLabel.add_theme_color_override("font_color", colors.accent_bright)

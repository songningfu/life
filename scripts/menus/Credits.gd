extends PanelContainer

signal close_requested()

@onready var scroll: ScrollContainer = $VBox/Scroll
@onready var content: RichTextLabel = $VBox/Scroll/CreditsText
@onready var close_btn: Button = $VBox/Footer/CloseBtn

var _scroll_speed := 42.0
var _running := false

func _ready() -> void:
	content.text = _build_credits_text()
	_apply_visual_style()
	close_btn.pressed.connect(func():
		_running = false
		visible = false
		close_requested.emit()
	)

func _process(delta: float) -> void:
	if not _running:
		return
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	bar.value += _scroll_speed * delta
	if bar.value >= bar.max_value:
		bar.value = 0

func start_scroll() -> void:
	visible = true
	_running = true
	scroll.scroll_vertical = 0

func _build_credits_text() -> String:
	return """
[center][font_size=32][b]制作人员[/b][/font_size][/center]

[center]LIFE 项目开发组[/center]
[center]策划 / 程序 / 美术：项目团队[/center]

[center][font_size=24][b]第三方开源许可[/b][/font_size][/center]

Dialogic 2 — MIT License — dialogic-godot
Toast Party — MIT License — godot-journey-adventures
Scene Manager — MIT License — glass-brick
Maaack's Game Template — MIT License — Maaack
gd-achievements — MIT License — 5FB5
GDQuest VFX Assets — MIT License — GDQuest

[center]感谢所有开源作者和贡献者。[/center]
"""

func _apply_visual_style() -> void:
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
	add_theme_stylebox_override("panel", panel)
	$VBox/Header.add_theme_color_override("font_color", Color("#e4f0ff"))
	content.add_theme_color_override("default_color", Color("#d7e5fb"))
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
	close_btn.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color("#243b70")
	close_btn.add_theme_stylebox_override("hover", h)
	close_btn.add_theme_color_override("font_color", Color("#edf3ff"))

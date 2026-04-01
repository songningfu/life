extends PanelContainer

signal close_requested()

@onready var scroll: ScrollContainer = $VBox/Scroll
@onready var content: RichTextLabel = $VBox/Scroll/CreditsText
@onready var close_btn: Button = $VBox/Footer/CloseBtn

var _scroll_speed := 42.0
var _running := false

func _ready() -> void:
	content.text = _build_credits_text()
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

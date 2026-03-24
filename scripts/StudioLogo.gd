extends Control

# ══════════════════════════════════════════════
#            工作室 Logo 展示页（纯脚本版）
# ══════════════════════════════════════════════

var can_skip: bool = false
var has_jumped: bool = false

func _init():
	# 在 _init 里设置自身属性，确保最早执行
	name = "StudioLogo"

func _ready():
	# 全屏
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 黑色背景
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 居中容器
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Logo + 文字的纵向容器
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	# Logo 图片
	var logo = TextureRect.new()
	var tex = load("res://images/studio_logo.png")
	if tex:
		logo.texture = tex
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(360, 180)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(logo)
	
	# 底部小字
	var skip_label = Label.new()
	skip_label.text = "点击屏幕或按任意键跳过"
	skip_label.add_theme_font_size_override("font_size", 13)
	skip_label.add_theme_color_override("font_color", Color(0.3, 0.32, 0.38))
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	skip_label.offset_top = -50
	add_child(skip_label)
	
	# 整体初始透明
	modulate = Color(1, 1, 1, 0)
	
	# 动画序列：淡入 → 停留 → 淡出 → 跳转
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.2)
	tw.tween_callback(func(): can_skip = true)
	tw.tween_interval(2.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_callback(_go_to_menu)

func _input(event):
	if not can_skip or has_jumped:
		return
	if (event is InputEventMouseButton and event.pressed) or \
	   (event is InputEventKey and event.pressed):
		has_jumped = true
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(_go_to_menu)

func _go_to_menu():
	if has_jumped and get_tree().current_scene != self:
		return
	has_jumped = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

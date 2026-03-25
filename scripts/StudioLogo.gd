extends Control

# ══════════════════════════════════════════════
#            工作室 Logo 展示页（动画增强版）
# ══════════════════════════════════════════════

var can_skip: bool = false
var has_jumped: bool = false
var logo: TextureRect
var particle_nodes: Array = []

func _init():
	name = "StudioLogo"

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# ===== 纯黑背景 =====
	var bg = ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.02, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# ===== 微光粒子背景 =====
	_create_particles()
	
	# ===== 居中容器 =====
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# ===== Logo 图片 =====
	logo = TextureRect.new()
	var tex = load("res://images/studio_logo.png")
	if tex:
		logo.texture = tex
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(420, 210)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.modulate = Color(1, 1, 1, 0)
	logo.scale = Vector2(0.85, 0.85)
	logo.pivot_offset = Vector2(210, 105)
	center.add_child(logo)
	
	# ===== 底部小字 =====
	var skip_label = Label.new()
	skip_label.name = "SkipLabel"
	skip_label.text = "点击屏幕或按任意键跳过"
	skip_label.add_theme_font_size_override("font_size", 12)
	skip_label.add_theme_color_override("font_color", Color(0.25, 0.27, 0.32, 0))
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	skip_label.offset_top = -40
	add_child(skip_label)
	
	# ═══════════════════════════════════════
	#            动画编排
	# ═══════════════════════════════════════
	
	await get_tree().create_timer(0.3).timeout
	
	# ── Logo 淡入 + 缩放弹性进入（1.5秒）──
	var tw1 = create_tween().set_parallel(true)
	tw1.tween_property(logo, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw1.tween_property(logo, "scale", Vector2(1.0, 1.0), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tw1.finished
	
	# ── 跳过提示淡入 ──
	var tw2 = create_tween()
	tw2.tween_property(skip_label, "theme_override_colors/font_color", Color(0.25, 0.27, 0.32, 1.0), 0.6)
	
	can_skip = true
	
	# ── 停留 3.5 秒 ──
	await get_tree().create_timer(3.5).timeout
	
	if not has_jumped:
		_do_exit()

# ═══════════════════════════════════════
#          微光粒子
# ═══════════════════════════════════════

func _create_particles():
	for i in 20:
		var dot = ColorRect.new()
		var size = randf_range(1.5, 3.5)
		dot.custom_minimum_size = Vector2(size, size)
		dot.size = Vector2(size, size)
		dot.color = Color(0.3, 0.6, 0.9, randf_range(0.03, 0.12))
		dot.position = Vector2(randf_range(0, 960), randf_range(0, 540))
		add_child(dot)
		particle_nodes.append(dot)
		
		var tw = create_tween().set_loops()
		var duration = randf_range(6.0, 14.0)
		var drift_x = randf_range(-30, 30)
		tw.tween_property(dot, "position:y", dot.position.y - randf_range(40, 100), duration)
		tw.parallel().tween_property(dot, "position:x", dot.position.x + drift_x, duration)
		tw.parallel().tween_property(dot, "modulate:a", randf_range(0.2, 0.6), duration * 0.5)
		tw.tween_property(dot, "modulate:a", 0.0, duration * 0.5)
		tw.tween_callback(func():
			dot.position = Vector2(randf_range(0, 960), randf_range(400, 600))
		)

# ═══════════════════════════════════════
#          退出动画
# ═══════════════════════════════════════

func _do_exit():
	if has_jumped:
		return
	has_jumped = true
	can_skip = false
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(logo, "position:y", logo.position.y - 20, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(logo, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	
	for dot in particle_nodes:
		if is_instance_valid(dot):
			tw.tween_property(dot, "modulate:a", 0.0, 0.6)
	
	await tw.finished
	await get_tree().create_timer(0.3).timeout
	_go_to_menu()

func _input(event):
	if not can_skip or has_jumped:
		return
	if (event is InputEventMouseButton and event.pressed) or \
	   (event is InputEventKey and event.pressed):
		_do_exit()

func _go_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

extends CanvasLayer
# ══════════════════════════════════════════════
#             手机系统 UI v2.0
# ══════════════════════════════════════════════

signal phone_opened
signal phone_closed

var is_open: bool = false
var current_app: String = ""
var _nav_stack: Array[String] = []

# ========== UI 节点 ==========
var phone_panel: PanelContainer
var phone_screen: VBoxContainer
var status_bar_top: HBoxContainer
var app_container: VBoxContainer
var back_btn: Button
var home_btn: Button
var app_pages: Dictionary = {}
var _time_label: Label
var _title_label: Label

# ========== 动画 ==========
var _anim_tween: Tween
const ANIM_DURATION := 0.3

# ========== 颜色主题 ==========
var phone_colors = {
	"bg":       Color(0.06, 0.065, 0.09, 1),
	"screen":   Color(0.08, 0.085, 0.11, 1),
	"header":   Color(0.10, 0.11, 0.15, 1),
	"accent":   Color(0.30, 0.70, 0.90, 1),
	"text":     Color(0.92, 0.93, 0.96, 1),
	"text_secondary": Color(0.65, 0.67, 0.72, 1),
	"dim":      Color(0.45, 0.47, 0.52, 1),
	"card":     Color(0.12, 0.13, 0.17, 1),
	"card_hover": Color(0.15, 0.16, 0.21, 1),
	"btn":      Color(0.16, 0.17, 0.22, 1),
	"divider":  Color(0.18, 0.19, 0.24, 0.6),
	"green":    Color(0.30, 0.78, 0.42, 1),
	"red":      Color(0.92, 0.28, 0.32, 1),
	"orange":   Color(1.0, 0.65, 0.25, 1),
	"nav_bg":   Color(0.04, 0.042, 0.058, 0.95),
	"status_bg": Color(0.04, 0.042, 0.058, 1),
	"bubble_player":  Color(0.18, 0.42, 0.28, 1),
	"bubble_npc":     Color(0.16, 0.17, 0.23, 1),
}

# ========== APP 定义 ==========
var apps = [
	{
		"id": "contacts", "name": "通讯录", "icon": "👥",
		"color_top": Color(0.25, 0.55, 1.0), "color_bottom": Color(0.15, 0.38, 0.85),
	},
	{
		"id": "wechat", "name": "微信", "icon": "💬",
		"color_top": Color(0.22, 0.78, 0.38), "color_bottom": Color(0.12, 0.58, 0.25),
	},
	{
		"id": "moments", "name": "朋友圈", "icon": "📷",
		"color_top": Color(0.95, 0.50, 0.20), "color_bottom": Color(0.80, 0.35, 0.12),
	},
	{
		"id": "schedule", "name": "日程", "icon": "📅",
		"color_top": Color(0.98, 0.55, 0.25), "color_bottom": Color(0.85, 0.40, 0.15),
	},
	{
		"id": "notes", "name": "备忘录", "icon": "📝",
		"color_top": Color(1.0, 0.80, 0.18), "color_bottom": Color(0.90, 0.65, 0.10),
	},
	{
		"id": "settings", "name": "设置", "icon": "⚙️",
		"color_top": Color(0.52, 0.56, 0.62), "color_bottom": Color(0.38, 0.42, 0.48),
	},
]

# ========== 状态栏自定义绘制图标 ==========
class SignalIcon extends Control:
	var bar_count: int = 4
	var max_bars: int = 4
	var active_color: Color = Color(0.92, 0.93, 0.96)
	var inactive_color: Color = Color(0.3, 0.31, 0.35)
	
	func _init(bars: int = 4, color: Color = Color(0.92, 0.93, 0.96)):
		bar_count = bars
		active_color = color
		custom_minimum_size = Vector2(16, 12)
	
	func _draw():
		var total_w = size.x
		var total_h = size.y
		var bar_w = 2.5
		var gap = 1.5
		var start_x = (total_w - (max_bars * bar_w + (max_bars - 1) * gap)) / 2.0
		for i in max_bars:
			var bar_h = total_h * (0.3 + 0.7 * (float(i) / float(max_bars - 1)))
			var x = start_x + i * (bar_w + gap)
			var y = total_h - bar_h
			var color = active_color if i < bar_count else inactive_color
			draw_rect(Rect2(x, y, bar_w, bar_h), color, true)

class WifiIcon extends Control:
	var strength: int = 3
	var active_color: Color = Color(0.92, 0.93, 0.96)
	var inactive_color: Color = Color(0.3, 0.31, 0.35)
	
	func _init(level: int = 3, color: Color = Color(0.92, 0.93, 0.96)):
		strength = level
		active_color = color
		custom_minimum_size = Vector2(15, 12)
	
	func _draw():
		var cx = size.x / 2.0
		var bottom = size.y - 1.0
		draw_circle(Vector2(cx, bottom - 1.0), 1.5, active_color)
		var arcs = [
			{"radius": 4.0, "level": 1},
			{"radius": 7.0, "level": 2},
			{"radius": 10.0, "level": 3},
		]
		for arc_info in arcs:
			var r = arc_info.radius
			var color = active_color if strength >= arc_info.level else inactive_color
			var center = Vector2(cx, bottom)
			var segments = 12
			var start_angle = -PI * 0.75
			var end_angle = -PI * 0.25
			var points = PackedVector2Array()
			for i in range(segments + 1):
				var angle = start_angle + (end_angle - start_angle) * (float(i) / float(segments))
				points.append(center + Vector2(cos(angle), sin(angle)) * r)
			for offset in [-0.5, 0.0, 0.5]:
				var offset_points = PackedVector2Array()
				for p in points:
					var dir = (p - center).normalized()
					offset_points.append(p + dir * offset)
				draw_polyline(offset_points, color, 1.0, true)

class BatteryIcon extends Control:
	var level: float = 0.86
	var body_color: Color = Color(0.92, 0.93, 0.96)
	var fill_color: Color = Color(0.30, 0.78, 0.42)
	var low_color: Color = Color(0.92, 0.28, 0.32)
	
	func _init(battery_level: float = 0.86, color: Color = Color(0.92, 0.93, 0.96)):
		level = battery_level
		body_color = color
		if level <= 0.2:
			fill_color = low_color
		custom_minimum_size = Vector2(26, 12)
	
	func _draw():
		var margin_y = 1.0
		var body_w = 20.0
		var body_h = size.y - margin_y * 2
		var body_x = 0.0
		var body_y = margin_y
		var corner = 2.5
		var tip_w = 2.5
		var tip_h = body_h * 0.4
		var tip_x = body_x + body_w + 0.5
		var tip_y = body_y + (body_h - tip_h) / 2.0
		var border_w = 1.2
		
		# 电池外框（描边圆角矩形）
		_draw_rounded_rect_outline(
			Rect2(body_x, body_y, body_w, body_h), corner, body_color, border_w
		)
		# 电池头
		_draw_rounded_rect_fill(
			Rect2(tip_x, tip_y, tip_w, tip_h), 1.0, body_color
		)
		# 电量填充
		var fill_margin = border_w + 1.5
		var fill_max_w = body_w - fill_margin * 2
		var fill_h = body_h - fill_margin * 2
		var fill_w = fill_max_w * clampf(level, 0.0, 1.0)
		var fc = low_color if level <= 0.2 else fill_color
		if fill_w > 0:
			_draw_rounded_rect_fill(
				Rect2(body_x + fill_margin, body_y + fill_margin, fill_w, fill_h),
				maxf(corner - 1.5, 1.0), fc
			)
	
	func _draw_rounded_rect_fill(rect: Rect2, radius: float, color: Color):
		var r = minf(radius, minf(rect.size.x / 2, rect.size.y / 2))
		draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2, rect.size.y), color)
		draw_rect(Rect2(rect.position.x, rect.position.y + r, r, rect.size.y - r * 2), color)
		draw_rect(Rect2(rect.position.x + rect.size.x - r, rect.position.y + r, r, rect.size.y - r * 2), color)
		draw_circle(Vector2(rect.position.x + r, rect.position.y + r), r, color)
		draw_circle(Vector2(rect.position.x + rect.size.x - r, rect.position.y + r), r, color)
		draw_circle(Vector2(rect.position.x + r, rect.position.y + rect.size.y - r), r, color)
		draw_circle(Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r), r, color)
	
	func _draw_rounded_rect_outline(rect: Rect2, radius: float, color: Color, width: float):
		var r = minf(radius, minf(rect.size.x / 2, rect.size.y / 2))
		var x1 = rect.position.x; var y1 = rect.position.y
		var x2 = x1 + rect.size.x; var y2 = y1 + rect.size.y
		draw_line(Vector2(x1 + r, y1), Vector2(x2 - r, y1), color, width, true)
		draw_line(Vector2(x1 + r, y2), Vector2(x2 - r, y2), color, width, true)
		draw_line(Vector2(x1, y1 + r), Vector2(x1, y2 - r), color, width, true)
		draw_line(Vector2(x2, y1 + r), Vector2(x2, y2 - r), color, width, true)
		for data in [
			[Vector2(x1 + r, y1 + r), PI, PI * 1.5],
			[Vector2(x2 - r, y1 + r), -PI * 0.5, 0.0],
			[Vector2(x1 + r, y2 - r), PI * 0.5, PI],
			[Vector2(x2 - r, y2 - r), 0.0, PI * 0.5],
		]:
			var pts = PackedVector2Array()
			for i in range(9):
				var angle = data[1] + (data[2] - data[1]) * (float(i) / 8.0)
				pts.append(data[0] + Vector2(cos(angle), sin(angle)) * r)
			draw_polyline(pts, color, width, true)

# ══════════════════════════════════════════════
#              初始化
# ══════════════════════════════════════════════
func _ready():
	layer = 100
	_init_ui_nodes()
	phone_panel.visible = false
	var ov = get_node_or_null("PhoneOverlay")
	if ov:
		ov.visible = false

	if get_tree().current_scene == self:
		_test_mode()

func _process(_delta):
	if is_open and _time_label:
		_update_status_bar_time()

func _init_ui_nodes():
	phone_panel = $PhonePanel
	phone_screen = $PhonePanel/PhoneScreen
	status_bar_top = $PhonePanel/PhoneScreen/StatusBarBg/StatusBar
	app_container = $PhonePanel/PhoneScreen/ScreenBg/AppContainer
	back_btn = $PhonePanel/PhoneScreen/NavBarBg/NavBar/BackBtn
	home_btn = $PhonePanel/PhoneScreen/NavBarBg/NavBar/HomeBtn
	var close_btn = $PhonePanel/PhoneScreen/NavBarBg/NavBar/CloseBtn

	_setup_styles()
	_setup_status_bar()
	_setup_nav_buttons()

	back_btn.pressed.connect(_on_back)
	home_btn.pressed.connect(_show_home_screen)
	close_btn.pressed.connect(close_phone)

	var overlay = $PhoneOverlay
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			close_phone()
	)

# ══════════════════════════════════════════════
#              样式系统
# ══════════════════════════════════════════════
func _setup_styles():
	# --- 状态栏背景 ---
	var status_bg = $PhonePanel/PhoneScreen/StatusBarBg
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = phone_colors.status_bg
	bar_style.corner_radius_top_left = 16
	bar_style.corner_radius_top_right = 16
	bar_style.content_margin_left = 18
	bar_style.content_margin_right = 18
	bar_style.content_margin_top = 6
	bar_style.content_margin_bottom = 4
	status_bg.add_theme_stylebox_override("panel", bar_style)

	# --- 屏幕主体 ---
	var screen_bg = $PhonePanel/PhoneScreen/ScreenBg
	var screen_style = StyleBoxFlat.new()
	screen_style.bg_color = phone_colors.screen
	screen_bg.add_theme_stylebox_override("panel", screen_style)

	# --- 导航栏 ---
	var nav_bg = $PhonePanel/PhoneScreen/NavBarBg
	var nav_style = StyleBoxFlat.new()
	nav_style.bg_color = phone_colors.nav_bg
	nav_style.corner_radius_bottom_left = 16
	nav_style.corner_radius_bottom_right = 16
	nav_style.content_margin_top = 6
	nav_style.content_margin_bottom = 10
	nav_bg.add_theme_stylebox_override("panel", nav_style)

func _setup_status_bar():
	for child in status_bar_top.get_children():
		child.queue_free()

	# 左侧: 时间
	_time_label = Label.new()
	_time_label.text = "12:00"
	_time_label.add_theme_font_size_override("font_size", 13)
	_time_label.add_theme_color_override("font_color", phone_colors.text)
	_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar_top.add_child(_time_label)

	# 中间: 灵动岛
	var notch = PanelContainer.new()
	notch.custom_minimum_size = Vector2(85, 22)
	var notch_style = StyleBoxFlat.new()
	notch_style.bg_color = Color(0, 0, 0, 1)
	notch_style.set_corner_radius_all(11)
	notch.add_theme_stylebox_override("panel", notch_style)
	status_bar_top.add_child(notch)

	# 右侧: 图标组
	var icons_box = HBoxContainer.new()
	icons_box.add_theme_constant_override("separation", 5)
	icons_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icons_box.alignment = BoxContainer.ALIGNMENT_END
	status_bar_top.add_child(icons_box)

	# 信号格（自定义绘制）
	var signal_icon = SignalIcon.new(4, phone_colors.text)
	signal_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icons_box.add_child(signal_icon)

	# 网络类型
	var net_lbl = Label.new()
	net_lbl.text = "5G"
	net_lbl.add_theme_font_size_override("font_size", 10)
	net_lbl.add_theme_color_override("font_color", phone_colors.text)
	net_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icons_box.add_child(net_lbl)

	# WiFi（自定义绘制）
	var wifi_icon = WifiIcon.new(3, phone_colors.text)
	wifi_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icons_box.add_child(wifi_icon)

	# 电池（自定义绘制）
	var battery_icon = BatteryIcon.new(0.86, phone_colors.text)
	battery_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icons_box.add_child(battery_icon)

	# 电量数字
	var pct_lbl = Label.new()
	pct_lbl.text = "86%"
	pct_lbl.add_theme_font_size_override("font_size", 11)
	pct_lbl.add_theme_color_override("font_color", phone_colors.text)
	pct_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icons_box.add_child(pct_lbl)

func _update_status_bar_time():
	# 使用游戏内时间（如果有的话），否则用系统时间
	var game_node = get_tree().get_first_node_in_group("game")
	if game_node and game_node.has_method("get_game_time_string"):
		_time_label.text = game_node.get_game_time_string()
	else:
		var time = Time.get_time_dict_from_system()
		_time_label.text = "%02d:%02d" % [time.hour, time.minute]

func _setup_nav_buttons():
	var buttons = [back_btn, home_btn, $PhonePanel/PhoneScreen/NavBarBg/NavBar/CloseBtn]
	var symbols = ["◁", "○", "▷"]  # 返回、主页、最近/关闭
	var sizes = [18, 22, 18]

	for i in buttons.size():
		var btn = buttons[i]
		btn.text = symbols[i]
		btn.add_theme_font_size_override("font_size", sizes[i])
		btn.add_theme_color_override("font_color", Color(0.55, 0.57, 0.62))
		btn.custom_minimum_size = Vector2(56, 32)

		# 正常状态：透明
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0, 0, 0, 0)
		btn.add_theme_stylebox_override("normal", normal)

		# 悬停：微弱高亮
		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(1, 1, 1, 0.06)
		hover.set_corner_radius_all(16)
		btn.add_theme_stylebox_override("hover", hover)

		# 按下：稍深
		var pressed = StyleBoxFlat.new()
		pressed.bg_color = Color(1, 1, 1, 0.03)
		pressed.set_corner_radius_all(16)
		btn.add_theme_stylebox_override("pressed", pressed)

	# 主页按钮底部加一条指示线
	# (会在 home_btn 下方加一个小装饰)

# ══════════════════════════════════════════════
#              主屏幕
# ══════════════════════════════════════════════
func _show_home_screen():
	current_app = ""
	_nav_stack.clear()
	_clear_app_container()

	# 顶部间距 + 日期显示
	var top_section = VBoxContainer.new()
	top_section.add_theme_constant_override("separation", 4)
	app_container.add_child(top_section)

	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 22)
	top_margin.add_theme_constant_override("margin_right", 22)
	top_margin.add_theme_constant_override("margin_top", 18)
	top_section.add_child(top_margin)

	var date_vbox = VBoxContainer.new()
	date_vbox.add_theme_constant_override("separation", 2)
	top_margin.add_child(date_vbox)

	# 日期和星期
	var game_node = get_tree().get_first_node_in_group("game")
	var date_text = "今天"
	if game_node and game_node.has_method("get_game_date_string"):
		date_text = game_node.get_game_date_string()

	var date_lbl = Label.new()
	date_lbl.text = date_text
	date_lbl.add_theme_font_size_override("font_size", 14)
	date_lbl.add_theme_color_override("font_color", phone_colors.text_secondary)
	date_vbox.add_child(date_lbl)

	# APP 网格
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	app_container.add_child(margin)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 22)
	margin.add_child(grid)

	for app in apps:
		grid.add_child(_create_app_icon(app))

	# 底部 Dock（可选：放常用APP）
	_add_home_dock()

func _create_app_icon(app: Dictionary) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 图标背景（模拟渐变）
	var icon_panel = PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(64, 64)

	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = app.color_top
	icon_style.set_corner_radius_all(16)
	# 内阴影效果（通过 border 模拟光泽）
	icon_style.border_width_top = 1
	icon_style.border_color = Color(1, 1, 1, 0.15)  # 顶部高光
	icon_style.shadow_color = Color(0, 0, 0, 0.35)
	icon_style.shadow_size = 5
	icon_style.shadow_offset = Vector2(0, 3)
	icon_panel.add_theme_stylebox_override("panel", icon_style)

	# Emoji 图标
	var icon_label = Label.new()
	icon_label.text = app.icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(icon_label)

	# 可点击按钮覆盖
	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_invisible_button(btn, 16)
	btn.pressed.connect(_open_app_animated.bind(app.id))
	icon_panel.add_child(btn)

	container.add_child(icon_panel)

	# 未读徽章
	if app.id == "wechat":
		var unread = _get_total_unread()
		if unread > 0:
			var badge = _create_badge(unread)
			badge.position = Vector2(46, -6)
			icon_panel.add_child(badge)

	# APP 名称
	var name_lbl = Label.new()
	name_lbl.text = app.name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", phone_colors.text_secondary)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_lbl)

	return container

func _create_badge(count: int) -> PanelContainer:
	var badge = PanelContainer.new()
	var w = 20 if count < 10 else 26
	badge.custom_minimum_size = Vector2(w, 20)

	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = phone_colors.red
	badge_style.set_corner_radius_all(10)
	badge_style.shadow_color = Color(phone_colors.red.r, phone_colors.red.g, phone_colors.red.b, 0.4)
	badge_style.shadow_size = 3
	badge.add_theme_stylebox_override("panel", badge_style)

	var badge_text = Label.new()
	badge_text.text = str(min(count, 99)) if count <= 99 else "99+"
	badge_text.add_theme_font_size_override("font_size", 10)
	badge_text.add_theme_color_override("font_color", Color.WHITE)
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_text)

	return badge

func _add_home_dock():
	# 底部分隔线
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_container.add_child(spacer)

	var dock_margin = MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 30)
	dock_margin.add_theme_constant_override("margin_right", 30)
	dock_margin.add_theme_constant_override("margin_bottom", 12)
	app_container.add_child(dock_margin)

	var dock = PanelContainer.new()
	var dock_style = StyleBoxFlat.new()
	dock_style.bg_color = Color(0.12, 0.13, 0.17, 0.8)
	dock_style.set_corner_radius_all(20)
	dock_style.content_margin_left = 16
	dock_style.content_margin_right = 16
	dock_style.content_margin_top = 10
	dock_style.content_margin_bottom = 10
	dock.add_theme_stylebox_override("panel", dock_style)
	dock_margin.add_child(dock)

	var dock_hbox = HBoxContainer.new()
	dock_hbox.add_theme_constant_override("separation", 20)
	dock_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_child(dock_hbox)

	# Dock 里放3个常用app的小图标
	var dock_apps = ["contacts", "wechat", "schedule"]
	var dock_emojis = {"contacts": "👥", "wechat": "💬", "schedule": "📅"}
	var dock_colors = {
		"contacts": Color(0.25, 0.55, 1.0),
		"wechat": Color(0.22, 0.78, 0.38),
		"schedule": Color(0.98, 0.55, 0.25),
	}

	for app_id in dock_apps:
		var dock_icon = PanelContainer.new()
		dock_icon.custom_minimum_size = Vector2(44, 44)
		var di_style = StyleBoxFlat.new()
		di_style.bg_color = dock_colors[app_id]
		di_style.set_corner_radius_all(12)
		dock_icon.add_theme_stylebox_override("panel", di_style)

		var di_label = Label.new()
		di_label.text = dock_emojis[app_id]
		di_label.add_theme_font_size_override("font_size", 22)
		di_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		di_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		di_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		di_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dock_icon.add_child(di_label)

		var di_btn = Button.new()
		di_btn.flat = true
		di_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		di_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_invisible_button(di_btn, 12)
		di_btn.pressed.connect(_open_app_animated.bind(app_id))
		dock_icon.add_child(di_btn)

		dock_hbox.add_child(dock_icon)

# ══════════════════════════════════════════════
#              打开/关闭手机（带动画）
# ══════════════════════════════════════════════
func open_phone():
	if is_open:
		return
	is_open = true
	phone_panel.visible = true
	var ov = get_node_or_null("PhoneOverlay")
	if ov:
		ov.visible = true
		ov.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.tween_property(ov, "modulate", Color(1, 1, 1, 1), 0.2)

	# 弹出动画：从底部滑入 + 缩放
	phone_panel.pivot_offset = phone_panel.size / 2.0
	phone_panel.scale = Vector2(0.9, 0.9)
	phone_panel.modulate = Color(1, 1, 1, 0)

	if _anim_tween:
		_anim_tween.kill()
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_anim_tween.tween_property(phone_panel, "scale", Vector2.ONE, ANIM_DURATION)
	_anim_tween.tween_property(phone_panel, "modulate", Color(1, 1, 1, 1), ANIM_DURATION * 0.6).set_trans(Tween.TRANS_QUAD)

	_show_home_screen()
	phone_opened.emit()

func close_phone():
	if not is_open:
		return
	is_open = false

	# 关闭动画
	phone_panel.pivot_offset = phone_panel.size / 2.0

	if _anim_tween:
		_anim_tween.kill()
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_anim_tween.tween_property(phone_panel, "scale", Vector2(0.85, 0.85), ANIM_DURATION * 0.7)
	_anim_tween.tween_property(phone_panel, "modulate", Color(1, 1, 1, 0), ANIM_DURATION * 0.7)

	var ov = get_node_or_null("PhoneOverlay")
	if ov:
		_anim_tween.tween_property(ov, "modulate", Color(1, 1, 1, 0), ANIM_DURATION * 0.5)

	_anim_tween.chain().tween_callback(func():
		phone_panel.visible = false
		phone_panel.scale = Vector2.ONE
		phone_panel.modulate = Color.WHITE
		if ov:
			ov.visible = false
			ov.modulate = Color.WHITE
		current_app = ""
	)

	phone_closed.emit()

func toggle_phone():
	if is_open:
		close_phone()
	else:
		open_phone()

# ══════════════════════════════════════════════
#              APP 路由（带过渡动画）
# ══════════════════════════════════════════════
func _open_app_animated(app_id: String):
	# 页面切换过渡
	var screen_bg = $PhonePanel/PhoneScreen/ScreenBg
	var tw = create_tween()
	tw.tween_property(screen_bg, "modulate", Color(1, 1, 1, 0.3), 0.08)
	tw.tween_callback(func(): _open_app(app_id))
	tw.tween_property(screen_bg, "modulate", Color(1, 1, 1, 1), 0.15)

func _open_app(app_id: String):
	_nav_stack.append(current_app)
	current_app = app_id
	_clear_app_container()
	match app_id:
		"contacts":
			_show_contacts()
		"wechat":
			_show_wechat_list()
		"moments":
			_show_moments()
		"schedule":
			_show_schedule()
		"notes":
			_show_notes()
		"settings":
			_show_settings()

func _on_back():
	if current_app == "wechat_chat":
		_open_app_animated("wechat")
	elif current_app != "":
		_nav_stack.clear()
		var screen_bg = $PhonePanel/PhoneScreen/ScreenBg
		var tw = create_tween()
		tw.tween_property(screen_bg, "modulate", Color(1, 1, 1, 0.3), 0.08)
		tw.tween_callback(func(): _show_home_screen())
		tw.tween_property(screen_bg, "modulate", Color(1, 1, 1, 1), 0.15)

# ══════════════════════════════════════════════
#          APP: 通讯录
# ══════════════════════════════════════════════
func _show_contacts():
	_clear_app_container()
	_add_app_header("通讯录", "👥")

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	app_container.add_child(scroll)

	var list_margin = MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 10)
	list_margin.add_theme_constant_override("margin_right", 10)
	list_margin.add_theme_constant_override("margin_top", 8)
	list_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_margin)

	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_margin.add_child(list)

	var met_npcs = RelationshipManager.get_met_npcs()
	if met_npcs.size() == 0:
		var empty_box = _create_empty_state("还没有认识任何人", "去和别人打个招呼吧 👋")
		list.add_child(empty_box)
		return

	for role_id in met_npcs:
		var info = RelationshipManager.get_npc_display(role_id)
		var card = _create_contact_card(info)
		list.add_child(card)

func _create_contact_card(info: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = phone_colors.card
	card_style.set_corner_radius_all(12)
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	# 微妙的边框
	card_style.border_width_top = 1
	card_style.border_color = Color(1, 1, 1, 0.04)
	card.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# 头像（圆形背景 + emoji）
	var avatar = _create_avatar(info.get("icon", "👤"), 44,
		Color.from_string(info.get("color", "#4488cc"), Color(0.3, 0.5, 0.8)))
	hbox.add_child(avatar)

	# 信息列
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# 姓名行
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	vbox.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = info.get("name", "???")
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", phone_colors.text)
	name_row.add_child(name_lbl)

	# 角色标签（带小背景）
	var role_tag = _create_tag(info.get("role", ""), phone_colors.accent)
	name_row.add_child(role_tag)

	# 性格描述
	var personality_lbl = Label.new()
	personality_lbl.text = info.get("personality", "")
	personality_lbl.add_theme_font_size_override("font_size", 12)
	personality_lbl.add_theme_color_override("font_color", phone_colors.text_secondary)
	personality_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(personality_lbl)

	# 好感度条
	var affinity_row = HBoxContainer.new()
	affinity_row.add_theme_constant_override("separation", 8)
	vbox.add_child(affinity_row)

	var level_color = _get_level_color(info.get("level", 0))
	var rel_lbl = Label.new()
	rel_lbl.text = info.get("level_name", "陌生人")
	rel_lbl.add_theme_font_size_override("font_size", 12)
	rel_lbl.add_theme_color_override("font_color", level_color)
	affinity_row.add_child(rel_lbl)

	# 进度条（更精致的样式）
	var bar = ProgressBar.new()
	bar.min_value = -20; bar.max_value = 100
	bar.value = info.get("affinity", 0)
	bar.custom_minimum_size = Vector2(90, 8)
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.13, 0.17)
	bar_bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = level_color
	bar_fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", bar_fill)
	affinity_row.add_child(bar)

	var val_lbl = Label.new()
	val_lbl.text = "%d" % info.get("affinity", 0)
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.add_theme_color_override("font_color", phone_colors.dim)
	affinity_row.add_child(val_lbl)

	return card

func _create_avatar(emoji: String, size: int, bg_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(size, size)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, 0.2)
	style.set_corner_radius_all(size / 2)  # 圆形
	panel.add_theme_stylebox_override("panel", style)

	var lbl = Label.new()
	lbl.text = emoji
	lbl.add_theme_font_size_override("font_size", int(size * 0.55))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)

	return panel

func _create_tag(text: String, color: Color) -> PanelContainer:
	var tag = PanelContainer.new()
	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = Color(color.r, color.g, color.b, 0.15)
	tag_style.set_corner_radius_all(4)
	tag_style.content_margin_left = 6
	tag_style.content_margin_right = 6
	tag_style.content_margin_top = 1
	tag_style.content_margin_bottom = 1
	tag.add_theme_stylebox_override("panel", tag_style)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	tag.add_child(lbl)

	return tag

func _get_level_color(level: int) -> Color:
	match level:
		0: return Color(0.50, 0.52, 0.56)
		1: return Color(0.58, 0.63, 0.70)
		2: return Color(0.30, 0.70, 0.92)
		3: return Color(0.35, 0.80, 0.50)
		4: return Color(1.00, 0.85, 0.22)
		5: return Color(1.00, 0.45, 0.62)
		6: return Color(0.90, 0.25, 0.45)
		7: return Color(0.45, 0.47, 0.52)
	return Color.WHITE

# ══════════════════════════════════════════════
#          APP: 微信聊天列表
# ══════════════════════════════════════════════
func _show_wechat_list():
	_clear_app_container()
	_add_app_header("微信", "💬")

	# 搜索栏（装饰性）
	var search_margin = MarginContainer.new()
	search_margin.add_theme_constant_override("margin_left", 12)
	search_margin.add_theme_constant_override("margin_right", 12)
	search_margin.add_theme_constant_override("margin_top", 8)
	search_margin.add_theme_constant_override("margin_bottom", 4)
	app_container.add_child(search_margin)

	var search_bar = PanelContainer.new()
	var search_style = StyleBoxFlat.new()
	search_style.bg_color = Color(0.12, 0.13, 0.17, 0.8)
	search_style.set_corner_radius_all(8)
	search_style.content_margin_left = 12
	search_style.content_margin_right = 12
	search_style.content_margin_top = 8
	search_style.content_margin_bottom = 8
	search_bar.add_theme_stylebox_override("panel", search_style)
	search_margin.add_child(search_bar)

	var search_lbl = Label.new()
	search_lbl.text = "🔍 搜索"
	search_lbl.add_theme_font_size_override("font_size", 13)
	search_lbl.add_theme_color_override("font_color", phone_colors.dim)
	search_bar.add_child(search_lbl)

	# 消息列表
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	app_container.add_child(scroll)

	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var active = WechatSystem.get_active_conversations()
	if active.size() == 0:
		var empty = _create_empty_state("暂无消息", "新的消息会出现在这里")
		list.add_child(empty)
		return

	for i in active.size():
		var role_id = active[i]
		var conv = WechatSystem.get_conversation(role_id)
		var info = RelationshipManager.get_npc_display(role_id)
		var card = _create_wechat_card(role_id, info, conv)
		list.add_child(card)
		# 分隔线（非最后一个）
		if i < active.size() - 1:
			var divider = _create_divider()
			list.add_child(divider)

func _create_wechat_card(role_id: String, info: Dictionary, conv: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0, 0, 0, 0)
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)

	# 按钮覆盖
	var btn = Button.new()
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var btn_n = StyleBoxFlat.new()
	btn_n.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", btn_n)
	var btn_h = StyleBoxFlat.new()
	btn_h.bg_color = Color(1, 1, 1, 0.04)
	btn.add_theme_stylebox_override("hover", btn_h)
	var btn_p = StyleBoxFlat.new()
	btn_p.bg_color = Color(1, 1, 1, 0.02)
	btn.add_theme_stylebox_override("pressed", btn_p)
	btn.pressed.connect(_open_chat.bind(role_id))

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)
	card.add_child(btn)

	# 头像
	var npc_color = Color.from_string(info.get("color", "#4488cc"), Color(0.3, 0.5, 0.8))
	var avatar = _create_avatar(info.get("icon", "👤"), 48, npc_color)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(avatar)

	# 信息区
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	# 第一行：名称 + 时间
	var top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)

	var name_lbl = Label.new()
	name_lbl.text = info.get("nickname", "???")
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", phone_colors.text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(name_lbl)

	# 时间戳
	var messages = conv.get("messages", [])
	if messages.size() > 0:
		var last_msg = messages[messages.size() - 1]
		var time_text = _format_message_time(last_msg)
		var time_lbl = Label.new()
		time_lbl.text = time_text
		time_lbl.add_theme_font_size_override("font_size", 11)
		time_lbl.add_theme_color_override("font_color", phone_colors.dim)
		time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.add_child(time_lbl)

	# 第二行：消息预览 + 状态
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 6)
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_row)

	if messages.size() > 0:
		var last = messages[messages.size() - 1]
		var preview = Label.new()
		var prefix = "你: " if last.sender == "player" else ""
		var txt = last.text
		if txt.length() > 18:
			txt = txt.substr(0, 18) + "..."
		preview.text = prefix + txt
		preview.add_theme_font_size_override("font_size", 13)
		preview.add_theme_color_override("font_color", phone_colors.dim)
		preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom_row.add_child(preview)

	# 未读红点
	var has_unread = WechatSystem.has_unread(role_id)
	if has_unread:
		var dot = PanelContainer.new()
		dot.custom_minimum_size = Vector2(10, 10)
		var dot_style = StyleBoxFlat.new()
		dot_style.bg_color = phone_colors.red
		dot_style.set_corner_radius_all(5)
		dot.add_theme_stylebox_override("panel", dot_style)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bottom_row.add_child(dot)

	# 待回复标记
	if conv.get("pending_reply") != null:
		var pending_tag = _create_tag("待回复", phone_colors.orange)
		pending_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom_row.add_child(pending_tag)

	return card

func _format_message_time(msg: Dictionary) -> String:
	# 如果消息有时间戳字段就格式化，否则返回空
	if msg.has("day"):
		var game_node = get_tree().get_first_node_in_group("game")
		if game_node:
			var current_day = game_node.day_index
			var msg_day = msg.day
			if msg_day == current_day:
				return "今天"
			elif msg_day == current_day - 1:
				return "昨天"
			else:
				return "%d天前" % (current_day - msg_day)
	return ""

# ══════════════════════════════════════════════
#          APP: 微信聊天详情
# ══════════════════════════════════════════════
func _open_chat(role_id: String):
	current_app = "wechat_chat"
	_clear_app_container()

	var info = RelationshipManager.get_npc_display(role_id)
	_add_app_header(info.get("nickname", "???"), info.get("icon", "👤"))

	if RelationshipManager.npc_data.has(role_id):
		RelationshipManager.npc_data[role_id].unread_messages = 0

	# 聊天背景（略带纹理感的深色）
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.name = "ChatScroll"
	app_container.add_child(scroll)

	var chat_margin = MarginContainer.new()
	chat_margin.add_theme_constant_override("margin_left", 10)
	chat_margin.add_theme_constant_override("margin_right", 10)
	chat_margin.add_theme_constant_override("margin_top", 10)
	chat_margin.add_theme_constant_override("margin_bottom", 10)
	chat_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(chat_margin)

	var chat_list = VBoxContainer.new()
	chat_list.add_theme_constant_override("separation", 10)
	chat_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_margin.add_child(chat_list)

	var conv = WechatSystem.get_conversation(role_id)
	var messages = conv.get("messages", [])

	if messages.size() == 0:
		var empty = _create_empty_state("暂无聊天记录", "对话开始后消息会显示在这里")
		chat_list.add_child(empty)
	else:
		var last_day = -1
		for msg in messages:
			# 日期分隔
			var msg_day = msg.get("day", -1)
			if msg_day != last_day and msg_day >= 0:
				var day_sep = _create_day_separator(msg_day)
				chat_list.add_child(day_sep)
				last_day = msg_day

			var bubble = _create_chat_bubble(msg, info)
			chat_list.add_child(bubble)

	# 自动滚动到底部
	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

	# 待回复区域
	var pending = conv.get("pending_reply")
	if pending != null:
		var reply_section = _create_reply_section(role_id, pending)
		app_container.add_child(reply_section)

func _create_day_separator(day: int) -> CenterContainer:
	var center = CenterContainer.new()
	var tag = PanelContainer.new()
	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = Color(0.1, 0.1, 0.13, 0.8)
	tag_style.set_corner_radius_all(10)
	tag_style.content_margin_left = 10
	tag_style.content_margin_right = 10
	tag_style.content_margin_top = 3
	tag_style.content_margin_bottom = 3
	tag.add_theme_stylebox_override("panel", tag_style)

	var lbl = Label.new()
	var game_node = get_tree().get_first_node_in_group("game")
	if game_node:
		var current_day = game_node.day_index
		if day == current_day:
			lbl.text = "今天"
		elif day == current_day - 1:
			lbl.text = "昨天"
		else:
			lbl.text = "第%d天" % (day + 1)
	else:
		lbl.text = "第%d天" % (day + 1)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", phone_colors.dim)
	tag.add_child(lbl)
	center.add_child(tag)
	return center

func _create_chat_bubble(msg: Dictionary, npc_info: Dictionary = {}) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var is_player = msg.sender == "player"

	if is_player:
		# 右对齐：左侧弹簧
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.custom_minimum_size = Vector2(40, 0)
		row.add_child(spacer)
	else:
		# NPC头像（小号）
		var npc_color = Color.from_string(npc_info.get("color", "#4488cc"), Color(0.3, 0.5, 0.8))
		var mini_avatar = _create_avatar(npc_info.get("icon", "👤"), 32, npc_color)
		row.add_child(mini_avatar)

	var bubble = PanelContainer.new()
	var bs = StyleBoxFlat.new()
	if is_player:
		bs.bg_color = phone_colors.bubble_player
		bs.corner_radius_top_left = 12
		bs.corner_radius_top_right = 4  # 右上角小圆角→气泡尖角感
		bs.corner_radius_bottom_left = 12
		bs.corner_radius_bottom_right = 12
	else:
		bs.bg_color = phone_colors.bubble_npc
		bs.corner_radius_top_left = 4  # 左上角小圆角
		bs.corner_radius_top_right = 12
		bs.corner_radius_bottom_left = 12
		bs.corner_radius_bottom_right = 12
	bs.content_margin_left = 12
	bs.content_margin_right = 12
	bs.content_margin_top = 8
	bs.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", bs)

	var lbl = Label.new()
	lbl.text = msg.text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", phone_colors.text)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(lbl)
	row.add_child(bubble)

	if is_player:
		# 玩家头像
		var player_avatar = _create_avatar("🙂", 32, Color(0.3, 0.7, 0.5))
		row.add_child(player_avatar)
	else:
		# 左对齐：右侧弹簧
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.custom_minimum_size = Vector2(40, 0)
		row.add_child(spacer)

	return row

func _create_reply_section(role_id: String, pending: Dictionary) -> PanelContainer:
	var section = PanelContainer.new()
	var section_style = StyleBoxFlat.new()
	section_style.bg_color = Color(0.08, 0.085, 0.11, 1)
	section_style.border_width_top = 1
	section_style.border_color = phone_colors.divider
	section_style.content_margin_left = 12
	section_style.content_margin_right = 12
	section_style.content_margin_top = 10
	section_style.content_margin_bottom = 10
	section.add_theme_stylebox_override("panel", section_style)

	var reply_box = VBoxContainer.new()
	reply_box.add_theme_constant_override("separation", 6)
	section.add_child(reply_box)

	var hint = Label.new()
	hint.text = "选择回复"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", phone_colors.accent)
	reply_box.add_child(hint)

	var replies = pending.get("replies", [])
	for i in replies.size():
		var reply = replies[i]
		var rbtn = Button.new()
		rbtn.text = reply["text"]
		rbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		rbtn.custom_minimum_size = Vector2(0, 38)
		rbtn.add_theme_font_size_override("font_size", 14)
		rbtn.add_theme_color_override("font_color", phone_colors.text)
		rbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var rs = StyleBoxFlat.new()
		rs.bg_color = Color(0.14, 0.15, 0.20)
		rs.set_corner_radius_all(8)
		rs.content_margin_left = 12
		rs.content_margin_right = 12
		rs.border_width_left = 3
		rs.border_color = phone_colors.green
		rbtn.add_theme_stylebox_override("normal", rs)

		var rh = rs.duplicate()
		rh.bg_color = Color(0.18, 0.20, 0.26)
		rh.border_color = Color(0.4, 0.9, 0.55)
		rbtn.add_theme_stylebox_override("hover", rh)

		var rp = rs.duplicate()
		rp.bg_color = Color(0.12, 0.13, 0.18)
		rbtn.add_theme_stylebox_override("pressed", rp)

		rbtn.pressed.connect(_on_reply.bind(role_id, i))
		reply_box.add_child(rbtn)

	return section

func _on_reply(role_id: String, reply_index: int):
	var day_index = 0
	var game_node = get_tree().get_first_node_in_group("game")
	if game_node:
		day_index = game_node.day_index

	var result = WechatSystem.player_reply(role_id, reply_index, day_index)
	if result.is_empty():
		return

	if game_node:
		var effects = result.get("effects", {})
		for attr in effects:
			var val = float(effects[attr])
			game_node._set_attr(attr, game_node._get_attr(attr) + val)
		game_node._clamp_all()
		game_node.update_ui()

		for tag in result.get("add_tags", []):
			if tag not in game_node.tags:
				game_node.tags.append(tag)

	var affinity_change = result.get("affinity", 0)
	if affinity_change != 0:
		RelationshipManager.change_affinity(role_id, affinity_change, day_index)

	_open_chat(role_id)

# ══════════════════════════════════════════════
#         占位 APP（更美观的空状态）
# ══════════════════════════════════════════════
func _show_moments():
	_clear_app_container()
	_add_app_header("朋友圈", "📷")
	_add_coming_soon("朋友圈动态", "查看好友的最新动态", "📸")

func _show_schedule():
	_clear_app_container()
	_add_app_header("日程", "📅")
	_add_coming_soon("日程表", "管理你的每日安排", "🗓️")

func _show_notes():
	_clear_app_container()
	_add_app_header("备忘录", "📝")
	_add_coming_soon("备忘录", "记录重要的事情", "✏️")

func _show_settings():
	_clear_app_container()
	_add_app_header("设置", "⚙️")
	_add_coming_soon("系统设置", "调整手机的各项设置", "🔧")

func _add_coming_soon(title: String, subtitle: String, emoji: String):
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	app_container.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var icon_lbl = Label.new()
	icon_lbl.text = emoji
	icon_lbl.add_theme_font_size_override("font_size", 48)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_lbl)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", phone_colors.text)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = subtitle
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", phone_colors.dim)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub_lbl)

	var tag = _create_tag("即将开放", phone_colors.accent)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(tag)

# ══════════════════════════════════════════════
#              UI 工具函数
# ══════════════════════════════════════════════
func _clear_app_container():
	for child in app_container.get_children():
		child.queue_free()

func _add_app_header(title: String, emoji: String = ""):
	var header = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = phone_colors.header
	header_style.content_margin_left = 16
	header_style.content_margin_right = 16
	header_style.content_margin_top = 10
	header_style.content_margin_bottom = 10
	# 底部微妙分隔
	header_style.border_width_bottom = 1
	header_style.border_color = phone_colors.divider
	header.add_theme_stylebox_override("panel", header_style)
	app_container.add_child(header)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)

	if emoji != "":
		var icon_lbl = Label.new()
		icon_lbl.text = emoji
		icon_lbl.add_theme_font_size_override("font_size", 18)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon_lbl)

	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", phone_colors.text)
	row.add_child(lbl)

func _create_empty_state(title: String, subtitle: String) -> CenterContainer:
	var center = CenterContainer.new()
	center.custom_minimum_size = Vector2(0, 200)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	center.add_child(vbox)

	var t_lbl = Label.new()
	t_lbl.text = title
	t_lbl.add_theme_font_size_override("font_size", 16)
	t_lbl.add_theme_color_override("font_color", phone_colors.dim)
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(t_lbl)

	var s_lbl = Label.new()
	s_lbl.text = subtitle
	s_lbl.add_theme_font_size_override("font_size", 13)
	s_lbl.add_theme_color_override("font_color", Color(phone_colors.dim.r, phone_colors.dim.g, phone_colors.dim.b, 0.6))
	s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(s_lbl)

	return center

func _create_divider() -> PanelContainer:
	var divider = PanelContainer.new()
	divider.custom_minimum_size = Vector2(0, 1)
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 70)
	divider.add_child(margin_container)
	var div_style = StyleBoxFlat.new()
	div_style.bg_color = phone_colors.divider
	div_style.content_margin_left = 70
	divider.add_theme_stylebox_override("panel", div_style)
	return divider

func _style_invisible_button(btn: Button, corner_radius: int = 0):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	if corner_radius > 0:
		normal.set_corner_radius_all(corner_radius)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.12)
	if corner_radius > 0:
		hover.set_corner_radius_all(corner_radius)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0, 0, 0, 0.15)
	if corner_radius > 0:
		pressed.set_corner_radius_all(corner_radius)
	btn.add_theme_stylebox_override("pressed", pressed)

func _get_total_unread() -> int:
	var total = 0
	if RelationshipManager and RelationshipManager.npc_data.size() > 0:
		for role_id in RelationshipManager.npc_data:
			total += RelationshipManager.npc_data[role_id].get("unread_messages", 0)
	return total

# ══════════════════════════════════════════════
#              序列化
# ══════════════════════════════════════════════
func serialize() -> Dictionary:
	return {}

func deserialize(_data: Dictionary):
	pass

# ══════════════════════════════════════════════
#              测试模式
# ══════════════════════════════════════════════
func _test_mode():
	print("📱 PhoneUI v2.0 测试模式")
	open_phone()

	var test_btn = Button.new()
	test_btn.text = "切换手机"
	test_btn.custom_minimum_size = Vector2(120, 40)
	test_btn.position = Vector2(20, 20)
	test_btn.pressed.connect(toggle_phone)
	add_child(test_btn)

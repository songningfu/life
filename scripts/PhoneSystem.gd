extends CanvasLayer
# ══════════════════════════════════════════════
#             手机系统 UI
# ══════════════════════════════════════════════

signal phone_opened
signal phone_closed

var is_open: bool = false
var current_app: String = ""

# ========== UI 节点 ==========
var phone_panel: PanelContainer
var phone_screen: VBoxContainer
var status_bar_top: HBoxContainer
var app_container: VBoxContainer
var back_btn: Button
var home_btn: Button
var app_pages: Dictionary = {}

const UI_ICON_PATHS = {
	"camera": "res://images/phone_icons/camera.png",
	"messages": "res://images/phone_icons/messages.png",
	"gallery": "res://images/phone_icons/gallery.png",
	"settings_app": "res://images/phone_icons/settings.png",
	"music": "res://images/phone_icons/music.png",
	"weather": "res://images/phone_icons/weather.png",
	"maps": "res://images/phone_icons/maps.png",
	"calendar": "res://images/phone_icons/calendar.png",
	"social": "res://images/phone_icons/social.png",
	"email": "res://images/phone_icons/email.png",
	"phone": "res://images/phone_icons/phone.png",
	"clock": "res://images/phone_icons/clock.png",
	"globe": "res://images/phone_icons/globe.png",
	"folder": "res://images/phone_icons/folder.png",
	"notes_app": "res://images/phone_icons/notes.png",
	"play": "res://images/phone_icons/play.png",
	"contacts": "res://images/phone_icons/phone.png",
	"wechat": "res://images/phone_icons/messages.png",
	"moments": "res://images/phone_icons/social.png",
	"schedule": "res://images/phone_icons/calendar.png",
	"notes": "res://images/phone_icons/notes.png",
	"settings": "res://images/phone_icons/settings.png",
	"signal": "res://icons/kenney_game-icons/PNG/White/1x/signal3.png",
	"battery": "res://icons/kenney_game-icons/PNG/White/1x/power.png",
	"back": "res://icons/kenney_game-icons/PNG/White/1x/arrowLeft.png",
	"home": "res://icons/kenney_game-icons/PNG/White/1x/home.png",
	"close": "res://icons/kenney_game-icons/PNG/White/1x/buttonX.png",
}

# ========== 颜色 ==========
var phone_colors = {
	"bg": Color(0.08, 0.09, 0.12, 1),
	"screen": Color(0.1, 0.11, 0.15, 1),
	"header": Color(0.12, 0.13, 0.18, 1),
	"accent": Color(0.3, 0.7, 0.9, 1),
	"text": Color(0.9, 0.92, 0.95, 1),
	"dim": Color(0.5, 0.52, 0.58, 1),
	"card": Color(0.14, 0.15, 0.2, 1),
	"btn": Color(0.18, 0.2, 0.26, 1),
	"green": Color(0.3, 0.75, 0.4, 1),
	"red": Color(0.9, 0.3, 0.35, 1),
}

# ========== APP 定义 ==========
var apps = [
	{"id": "contacts", "name": "通讯录", "icon_path": UI_ICON_PATHS.contacts, "color": Color(0.3, 0.7, 0.9)},
	{"id": "wechat", "name": "微信", "icon_path": UI_ICON_PATHS.wechat, "color": Color(0.3, 0.75, 0.4)},
	{"id": "moments", "name": "朋友圈", "icon_path": UI_ICON_PATHS.moments, "color": Color(0.3, 0.75, 0.4)},
	{"id": "schedule", "name": "日程", "icon_path": UI_ICON_PATHS.schedule, "color": Color(1.0, 0.6, 0.3)},
	{"id": "notes", "name": "备忘录", "icon_path": UI_ICON_PATHS.notes, "color": Color(1.0, 0.85, 0.2)},
	{"id": "settings", "name": "设置", "icon_path": UI_ICON_PATHS.settings, "color": Color(0.6, 0.62, 0.68)},
]

func _ready():
	layer = 100
	_build_phone_ui()
	phone_panel.visible = false
	var ov = get_node_or_null("PhoneOverlay")
	if ov:
		ov.visible = false

# ══════════════════════════════════════════════
#              构建手机 UI
# ══════════════════════════════════════════════
func _build_phone_ui():
	var overlay = ColorRect.new()
	overlay.name = "PhoneOverlay"
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			close_phone()
	)
	add_child(overlay)

	phone_panel = PanelContainer.new()
	phone_panel.name = "PhonePanel"
	phone_panel.custom_minimum_size = Vector2(360, 640)
	phone_panel.set_anchors_preset(Control.PRESET_CENTER)
	phone_panel.position = Vector2(-180, -320)

	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.06, 0.06, 0.08, 1)
	frame_style.set_corner_radius_all(20)
	frame_style.border_width_left = 2; frame_style.border_width_right = 2
	frame_style.border_width_top = 2; frame_style.border_width_bottom = 2
	frame_style.border_color = Color(0.25, 0.27, 0.32, 1)
	frame_style.content_margin_left = 8; frame_style.content_margin_right = 8
	frame_style.content_margin_top = 8; frame_style.content_margin_bottom = 8
	phone_panel.add_theme_stylebox_override("panel", frame_style)
	add_child(phone_panel)

	phone_screen = VBoxContainer.new()
	phone_screen.add_theme_constant_override("separation", 0)
	phone_panel.add_child(phone_screen)

	_build_status_bar()

	app_container = VBoxContainer.new()
	app_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var screen_bg = PanelContainer.new()
	var screen_style = StyleBoxFlat.new()
	screen_style.bg_color = phone_colors.screen
	screen_style.set_corner_radius_all(0)
	screen_bg.add_theme_stylebox_override("panel", screen_style)
	screen_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_screen.add_child(screen_bg)
	screen_bg.add_child(app_container)

	_build_nav_bar()
	_show_home_screen()

func _build_status_bar():
	status_bar_top = HBoxContainer.new()
	status_bar_top.custom_minimum_size = Vector2(0, 28)
	status_bar_top.add_theme_constant_override("separation", 0)

	var bar_bg = PanelContainer.new()
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.05, 0.05, 0.07, 1)
	bar_style.corner_radius_top_left = 12; bar_style.corner_radius_top_right = 12
	bar_style.content_margin_left = 15; bar_style.content_margin_right = 15
	bar_style.content_margin_top = 4
	bar_bg.add_theme_stylebox_override("panel", bar_style)
	phone_screen.add_child(bar_bg)
	bar_bg.add_child(status_bar_top)

	var time_lbl = Label.new()
	time_lbl.text = "9:41"
	time_lbl.add_theme_font_size_override("font_size", 13)
	time_lbl.add_theme_color_override("font_color", phone_colors.text)
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_bar_top.add_child(time_lbl)

	var icons_box = HBoxContainer.new()
	icons_box.add_theme_constant_override("separation", 8)
	status_bar_top.add_child(icons_box)
	icons_box.add_child(_make_small_icon(UI_ICON_PATHS.signal, 13))
	icons_box.add_child(_make_small_icon(UI_ICON_PATHS.battery, 13))

func _build_nav_bar():
	var nav = HBoxContainer.new()
	nav.custom_minimum_size = Vector2(0, 48)
	nav.add_theme_constant_override("separation", 20)
	nav.alignment = BoxContainer.ALIGNMENT_CENTER

	var nav_bg = PanelContainer.new()
	var nav_style = StyleBoxFlat.new()
	nav_style.bg_color = Color(0.05, 0.05, 0.07, 1)
	nav_style.corner_radius_bottom_left = 12; nav_style.corner_radius_bottom_right = 12
	nav_style.content_margin_top = 4; nav_style.content_margin_bottom = 8
	nav_bg.add_theme_stylebox_override("panel", nav_style)
	phone_screen.add_child(nav_bg)
	nav_bg.add_child(nav)

	back_btn = _make_nav_button("返回", UI_ICON_PATHS.back, phone_colors.accent)
	back_btn.pressed.connect(_on_back)
	nav.add_child(back_btn)

	home_btn = _make_nav_button("主屏", UI_ICON_PATHS.home, phone_colors.text)
	home_btn.pressed.connect(_show_home_screen)
	nav.add_child(home_btn)

	var close_btn = _make_nav_button("关闭", UI_ICON_PATHS.close, phone_colors.red)
	close_btn.pressed.connect(close_phone)
	nav.add_child(close_btn)

# ══════════════════════════════════════════════
#              主屏幕（APP图标）
# ══════════════════════════════════════════════
func _show_home_screen():
	current_app = ""
	_clear_app_container()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 10)
	app_container.add_child(margin)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 20)
	margin.add_child(grid)

	for app in apps:
		var app_btn = VBoxContainer.new()
		app_btn.add_theme_constant_override("separation", 4)
		app_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var icon_btn = Button.new()
		icon_btn.custom_minimum_size = Vector2(84, 84)
		icon_btn.icon = _load_icon(app.icon_path, 62)
		icon_btn.expand_icon = true

		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = Color(0, 0, 0, 0)
		icon_style.set_corner_radius_all(22)
		icon_style.content_margin_left = 4
		icon_style.content_margin_right = 4
		icon_style.content_margin_top = 4
		icon_style.content_margin_bottom = 4
		icon_btn.add_theme_stylebox_override("normal", icon_style)
		var icon_hover = icon_style.duplicate()
		icon_hover.bg_color = Color(app.color.r, app.color.g, app.color.b, 0.14)
		icon_btn.add_theme_stylebox_override("hover", icon_hover)
		var icon_pressed = icon_style.duplicate()
		icon_pressed.bg_color = Color(app.color.r, app.color.g, app.color.b, 0.22)
		icon_btn.add_theme_stylebox_override("pressed", icon_pressed)
		icon_btn.pressed.connect(_open_app.bind(app.id))
		app_btn.add_child(icon_btn)

		if app.id == "wechat" and RelationshipManager.npc_data.size() > 0:
			var unread = _get_total_unread()
			if unread > 0:
				var badge = Label.new()
				badge.text = str(unread)
				badge.add_theme_font_size_override("font_size", 11)
				badge.add_theme_color_override("font_color", Color.WHITE)
				icon_btn.add_child(badge)

		var name_lbl = Label.new()
		name_lbl.text = app.name
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", phone_colors.text)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		app_btn.add_child(name_lbl)

		grid.add_child(app_btn)

func _get_total_unread() -> int:
	var total = 0
	if RelationshipManager and RelationshipManager.npc_data.size() > 0:
		for role_id in RelationshipManager.npc_data:
			total += RelationshipManager.npc_data[role_id].get("unread_messages", 0)
	return total

# ══════════════════════════════════════════════
#              打开/关闭手机
# ══════════════════════════════════════════════
func open_phone():
	if is_open:
		return
	is_open = true
	phone_panel.visible = true
	var ov = get_node_or_null("PhoneOverlay")
	if ov:
		ov.visible = true
	_show_home_screen()
	phone_opened.emit()

func close_phone():
	is_open = false
	phone_panel.visible = false
	var ov = get_node_or_null("PhoneOverlay")
	if ov:
		ov.visible = false
	current_app = ""
	phone_closed.emit()

func toggle_phone():
	if is_open:
		close_phone()
	else:
		open_phone()

# ══════════════════════════════════════════════
#              APP 路由
# ══════════════════════════════════════════════
func _open_app(app_id: String):
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
		_show_wechat_list()
		current_app = "wechat"
	elif current_app != "":
		_show_home_screen()

# ══════════════════════════════════════════════
#          APP: 通讯录（人物关系）
# ══════════════════════════════════════════════
func _show_contacts():
	_clear_app_container()
	_add_app_header("通讯录", UI_ICON_PATHS.contacts)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	app_container.add_child(scroll)

	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var met_npcs = RelationshipManager.get_met_npcs()
	if met_npcs.size() == 0:
		var empty = Label.new()
		empty.text = "\n  还没有认识任何人..."
		empty.add_theme_color_override("font_color", phone_colors.dim)
		empty.add_theme_font_size_override("font_size", 14)
		list.add_child(empty)
		return

	for role_id in met_npcs:
		var info = RelationshipManager.get_npc_display(role_id)
		var card = _create_contact_card(info)
		list.add_child(card)

func _create_contact_card(info: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = phone_colors.card
	card_style.set_corner_radius_all(10)
	card_style.content_margin_left = 12; card_style.content_margin_right = 12
	card_style.content_margin_top = 10; card_style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	var icon_lbl = Label.new()
	icon_lbl.text = info.get("icon", "👤")
	icon_lbl.add_theme_font_size_override("font_size", 32)
	icon_lbl.custom_minimum_size = Vector2(45, 45)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_row = HBoxContainer.new()
	vbox.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = info.get("name", "???")
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.from_string(info.get("color", "#ffffff"), Color.WHITE))
	name_row.add_child(name_lbl)

	var role_lbl = Label.new()
	role_lbl.text = "  [%s]" % info.get("role", "")
	role_lbl.add_theme_font_size_override("font_size", 12)
	role_lbl.add_theme_color_override("font_color", phone_colors.dim)
	name_row.add_child(role_lbl)

	var personality_lbl = Label.new()
	personality_lbl.text = info.get("personality", "")
	personality_lbl.add_theme_font_size_override("font_size", 12)
	personality_lbl.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	personality_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(personality_lbl)

	var affinity_row = HBoxContainer.new()
	affinity_row.add_theme_constant_override("separation", 8)
	vbox.add_child(affinity_row)

	var rel_lbl = Label.new()
	rel_lbl.text = info.get("level_name", "陌生人")
	rel_lbl.add_theme_font_size_override("font_size", 13)
	var rel_color = _get_level_color(info.get("level", 0))
	rel_lbl.add_theme_color_override("font_color", rel_color)
	affinity_row.add_child(rel_lbl)

	var bar = ProgressBar.new()
	bar.min_value = -20; bar.max_value = 100
	bar.value = info.get("affinity", 0)
	bar.custom_minimum_size = Vector2(100, 12)
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.16, 0.2)
	bar_bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = rel_color
	bar_fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", bar_fill)
	affinity_row.add_child(bar)

	var val_lbl = Label.new()
	val_lbl.text = "%d" % info.get("affinity", 0)
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", phone_colors.dim)
	affinity_row.add_child(val_lbl)

	return card

func _get_level_color(level: int) -> Color:
	match level:
		0: return Color(0.5, 0.5, 0.5)
		1: return Color(0.6, 0.65, 0.7)
		2: return Color(0.3, 0.7, 0.9)
		3: return Color(0.4, 0.8, 0.5)
		4: return Color(1.0, 0.85, 0.2)
		5: return Color(1.0, 0.4, 0.6)
		6: return Color(1.0, 0.3, 0.5)
		7: return Color(0.5, 0.5, 0.55)
	return Color.WHITE

# ══════════════════════════════════════════════
#          APP: 微信聊天列表
# ══════════════════════════════════════════════
func _show_wechat_list():
	_clear_app_container()
	_add_app_header("微信", UI_ICON_PATHS.wechat)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 450)
	app_container.add_child(scroll)

	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var active = WechatSystem.get_active_conversations()
	if active.size() == 0:
		var empty = Label.new()
		empty.text = "\n  暂无消息"
		empty.add_theme_color_override("font_color", phone_colors.dim)
		empty.add_theme_font_size_override("font_size", 16)
		list.add_child(empty)
		return

	for role_id in active:
		var conv = WechatSystem.get_conversation(role_id)
		var info = RelationshipManager.get_npc_display(role_id)
		var card = _create_wechat_card(role_id, info, conv)
		list.add_child(card)

func _create_wechat_card(role_id: String, info: Dictionary, conv: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = phone_colors.card
	card_style.content_margin_left = 12; card_style.content_margin_right = 12
	card_style.content_margin_top = 10; card_style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_style)

	var btn = Button.new()
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var btn_s = StyleBoxFlat.new()
	btn_s.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", btn_s)
	var btn_h = StyleBoxFlat.new()
	btn_h.bg_color = Color(1, 1, 1, 0.05)
	btn.add_theme_stylebox_override("hover", btn_h)
	btn.pressed.connect(_open_chat.bind(role_id))

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)
	card.add_child(btn)

	var icon = Label.new()
	icon.text = info.get("icon", "👤")
	icon.add_theme_font_size_override("font_size", 28)
	icon.custom_minimum_size = Vector2(40, 40)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	var name_row = HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = info.get("nickname", "???")
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", phone_colors.text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(name_lbl)

	var has_unread = WechatSystem.has_unread(role_id)
	if has_unread:
		var dot = Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 14)
		dot.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_row.add_child(dot)

	if conv.get("pending_reply") != null:
		var pending_lbl = Label.new()
		pending_lbl.text = "[待回复]"
		pending_lbl.add_theme_font_size_override("font_size", 12)
		pending_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
		pending_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_row.add_child(pending_lbl)

	var messages = conv.get("messages", [])
	if messages.size() > 0:
		var last = messages[messages.size() - 1]
		var preview = Label.new()
		var prefix = "你: " if last.sender == "player" else ""
		var txt = last.text
		if txt.length() > 20:
			txt = txt.substr(0, 20) + "..."
		preview.text = prefix + txt
		preview.add_theme_font_size_override("font_size", 13)
		preview.add_theme_color_override("font_color", phone_colors.dim)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(preview)

	return card

# ══════════════════════════════════════════════
#          APP: 微信聊天详情
# ══════════════════════════════════════════════
func _open_chat(role_id: String):
	current_app = "wechat_chat"
	_clear_app_container()

	var info = RelationshipManager.get_npc_display(role_id)
	_add_app_header(info.get("nickname", "???"), UI_ICON_PATHS.wechat)

	if RelationshipManager.npc_data.has(role_id):
		RelationshipManager.npc_data[role_id].unread_messages = 0

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 350)
	app_container.add_child(scroll)

	var chat_list = VBoxContainer.new()
	chat_list.add_theme_constant_override("separation", 8)
	chat_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(chat_list)

	var conv = WechatSystem.get_conversation(role_id)
	var messages = conv.get("messages", [])

	if messages.size() == 0:
		var empty = Label.new()
		empty.text = "\n  暂无聊天记录"
		empty.add_theme_color_override("font_color", phone_colors.dim)
		empty.add_theme_font_size_override("font_size", 14)
		chat_list.add_child(empty)
	else:
		for msg in messages:
			var bubble = _create_chat_bubble(msg)
			chat_list.add_child(bubble)

	var pending = conv.get("pending_reply")
	if pending != null:
		var sep = HSeparator.new()
		app_container.add_child(sep)

		var reply_box = VBoxContainer.new()
		reply_box.add_theme_constant_override("separation", 6)
		app_container.add_child(reply_box)

		var hint = Label.new()
		hint.text = "  选择回复:"
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", phone_colors.accent)
		reply_box.add_child(hint)

		var replies = pending.get("replies", [])
		for i in replies.size():
			var reply = replies[i]
			var rbtn = Button.new()
			rbtn.text = "  " + reply["text"]
			rbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			rbtn.custom_minimum_size = Vector2(0, 36)
			rbtn.add_theme_font_size_override("font_size", 14)
			rbtn.add_theme_color_override("font_color", phone_colors.text)
			var rs = StyleBoxFlat.new()
			rs.bg_color = Color(0.16, 0.18, 0.24)
			rs.set_corner_radius_all(6)
			rs.content_margin_left = 10
			rs.border_width_left = 3
			rs.border_color = phone_colors.green
			rbtn.add_theme_stylebox_override("normal", rs)
			var rh = rs.duplicate()
			rh.bg_color = Color(0.2, 0.24, 0.3)
			rbtn.add_theme_stylebox_override("hover", rh)
			rbtn.pressed.connect(_on_reply.bind(role_id, i))
			reply_box.add_child(rbtn)

func _create_chat_bubble(msg: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var is_player = msg.sender == "player"

	if is_player:
		var spacer_left = Control.new()
		spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_left)

	var bubble = PanelContainer.new()
	var bs = StyleBoxFlat.new()
	if is_player:
		bs.bg_color = Color(0.2, 0.45, 0.3, 1)
	else:
		bs.bg_color = Color(0.18, 0.2, 0.26, 1)
	bs.set_corner_radius_all(10)
	bs.content_margin_left = 12; bs.content_margin_right = 12
	bs.content_margin_top = 8; bs.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", bs)
	bubble.custom_minimum_size = Vector2(250, 0)

	var lbl = Label.new()
	lbl.text = msg.text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", phone_colors.text)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(lbl)
	row.add_child(bubble)

	if not is_player:
		var spacer_right = Control.new()
		spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_right)

	return row

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
#         占位 APP
# ══════════════════════════════════════════════
func _show_moments():
	_clear_app_container()
	_add_app_header("朋友圈", UI_ICON_PATHS.moments)
	_add_placeholder("朋友圈动态 - 下次更新")

func _show_schedule():
	_clear_app_container()
	_add_app_header("日程", UI_ICON_PATHS.schedule)
	_add_placeholder("日程课表 - 下次更新")

func _show_notes():
	_clear_app_container()
	_add_app_header("备忘录", UI_ICON_PATHS.notes)
	_add_placeholder("备忘录 - 下次更新")

func _show_settings():
	_clear_app_container()
	_add_app_header("设置", UI_ICON_PATHS.settings)
	_add_placeholder("系统设置 - 下次更新")

# ══════════════════════════════════════════════
#              UI 工具
# ══════════════════════════════════════════════
func _clear_app_container():
	for child in app_container.get_children():
		child.queue_free()

func _add_app_header(title: String, icon_path: String = ""):
	var header = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = phone_colors.header
	header_style.content_margin_left = 15; header_style.content_margin_right = 15
	header_style.content_margin_top = 10; header_style.content_margin_bottom = 10
	header.add_theme_stylebox_override("panel", header_style)
	app_container.add_child(header)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)

	if icon_path != "":
		row.add_child(_make_small_icon(icon_path, 16, phone_colors.text))

	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", phone_colors.text)
	row.add_child(lbl)

func _add_placeholder(text: String):
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	app_container.add_child(margin)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", phone_colors.dim)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(lbl)

# ══════════════════════════════════════════════
#              序列化
# ══════════════════════════════════════════════
func serialize() -> Dictionary:
	return {}

func deserialize(_data: Dictionary):
	pass

func _load_icon(path: String, size: int = 0) -> Texture2D:
	if size <= 0:
		return load(path) as Texture2D
	var image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return load(path) as Texture2D
	image.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func _make_small_icon(path: String, size: int = 16, modulate_color: Color = Color.WHITE) -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = _load_icon(path, size)
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = modulate_color
	return icon

func _make_nav_button(label: String, icon_path: String, font_color: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.icon = _load_icon(icon_path, 22)
	btn.expand_icon = true
	btn.custom_minimum_size = Vector2(86, 0)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_constant_override("h_separation", 8)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	return btn

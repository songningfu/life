## PhoneSystem.gd - 手机系统 UI（重构版）
## 适配模块架构，支持模块注入的App面板

extends CanvasLayer

# ==================== 信号 ====================

signal phone_opened
signal phone_closed
signal message_sent(role_id: String, message: String)
signal app_opened(app_id: String)

# ==================== 常量 ====================

const ANIM_DURATION: float = 0.3
const MAX_DAILY_MESSAGES: int = 3  # 每天主动发消息上限

# ==================== 成员变量 ====================

var is_open: bool = false
var current_app: String = ""
var _nav_stack: Array[String] = []

# 每日消息计数
var _daily_message_count: int = 0
var _last_message_day: int = -1

# UI 节点
var phone_panel: PanelContainer
var phone_screen: VBoxContainer
var status_bar_top: HBoxContainer
var app_container: VBoxContainer
var back_btn: Button
var home_btn: Button
var app_pages: Dictionary = {}
var _time_label: Label
var _title_label: Label

# 动画
var _anim_tween: Tween
var _overlay: ColorRect

# ==================== 颜色主题 ====================

var phone_colors: Dictionary = {
	"bg": Color(0.06, 0.065, 0.09, 1),
	"screen": Color(0.08, 0.085, 0.11, 1),
	"header": Color(0.10, 0.11, 0.15, 1),
	"accent": Color(0.30, 0.70, 0.90, 1),
	"text": Color(0.92, 0.93, 0.96, 1),
	"text_secondary": Color(0.65, 0.67, 0.72, 1),
	"dim": Color(0.45, 0.47, 0.52, 1),
	"card": Color(0.12, 0.13, 0.17, 1),
	"card_hover": Color(0.15, 0.16, 0.21, 1),
	"btn": Color(0.16, 0.17, 0.22, 1),
	"divider": Color(0.18, 0.19, 0.24, 0.6),
	"green": Color(0.30, 0.78, 0.42, 1),
	"red": Color(0.92, 0.28, 0.32, 1),
	"orange": Color(1.0, 0.65, 0.25, 1),
	"nav_bg": Color(0.04, 0.042, 0.058, 0.95),
	"status_bg": Color(0.04, 0.042, 0.058, 1),
	"bubble_player": Color(0.18, 0.42, 0.28, 1),
	"bubble_npc": Color(0.16, 0.17, 0.23, 1),
}

# ==================== 内置APP定义 ====================

var _builtin_apps: Array[Dictionary] = [
	{"id": "contacts", "name": "通讯录", "icon": "👥", "color": Color(0.25, 0.55, 1.0)},
	{"id": "wechat", "name": "微信", "icon": "💬", "color": Color(0.22, 0.78, 0.38)},
	{"id": "moments", "name": "朋友圈", "icon": "📷", "color": Color(0.95, 0.50, 0.20)},
	{"id": "schedule", "name": "日程", "icon": "📅", "color": Color(0.98, 0.55, 0.25)},
	{"id": "notes", "name": "备忘录", "icon": "📝", "color": Color(1.0, 0.80, 0.18)},
	{"id": "settings", "name": "设置", "icon": "⚙️", "color": Color(0.52, 0.56, 0.62)},
]

# 当前显示的所有APP（包括模块注入的）
var _current_apps: Array[Dictionary] = []

# 微信页状态
var _wechat_current_role: String = ""
var _wechat_chat_content: RichTextLabel
var _wechat_partner_list: VBoxContainer
var _wechat_send_options: VBoxContainer

# ==================== 生命周期 ====================

func _ready() -> void:
	_setup_ui()
	_setup_connections()
	_refresh_apps()
	hide()

func _setup_connections() -> void:
	# 连接模块管理器信号
	if ModuleManager:
		ModuleManager.player_state_changed.connect(_on_player_state_changed)

func _on_player_state_changed(key: String, value: Variant) -> void:
	if key == "day_index":
		_reset_daily_message_count(value)

# ==================== APP管理 ====================

## 刷新APP列表（收集模块注入的APP）
func _refresh_apps() -> void:
	_current_apps = _builtin_apps.duplicate()
	
	# 收集模块注入的APP
	if ModuleManager:
		var module_panels: Array[Dictionary] = ModuleManager.collect_ui_panels()
		for panel: Dictionary in module_panels:
			_current_apps.append({
				"id": panel["id"],
				"name": panel["name"],
				"icon": panel.get("icon", "📱"),
				"color": Color(0.5, 0.5, 0.5),
				"is_module": true,
				"scene": panel.get("scene", "")
			})

## 获取所有APP
func get_apps() -> Array[Dictionary]:
	return _current_apps.duplicate()

# ==================== 消息系统 ====================

## 重置每日消息计数
func _reset_daily_message_count(day: int) -> void:
	if day != _last_message_day:
		_daily_message_count = 0
		_last_message_day = day

## 检查是否可以发送消息
func can_send_message() -> bool:
	return _daily_message_count < MAX_DAILY_MESSAGES

## 获取剩余可发送消息数
func get_remaining_messages() -> int:
	return MAX_DAILY_MESSAGES - _daily_message_count

## 发送消息
func send_message(role_id: String, message: String) -> bool:
	if not can_send_message():
		_log("今日消息已用完")
		return false
	
	_daily_message_count += 1
	
	# 转发给WechatSystem
	if WechatSystem:
		WechatSystem.send_message(role_id, message)
	
	message_sent.emit(role_id, message)
	_log("发送消息给 %s: %s" % [role_id, message])
	
	return true

## 接收消息
func receive_message(role_id: String, message: String) -> void:
	if WechatSystem:
		WechatSystem.receive_message(role_id, message)
	_log("接收消息来自 %s: %s" % [role_id, message])

## 获取可发送消息选项
func get_sendable_messages(role_id: String) -> Array[Dictionary]:
	if ModuleManager:
		var context: Dictionary = _build_message_context(role_id)
		return ModuleManager.collect_sendable_messages(role_id, context)
	return []

## 构建消息上下文
func _build_message_context(role_id: String) -> Dictionary:
	var context: Dictionary = {
		"day": _get_current_day(),
		"phase": _get_current_phase()
	}
	
	# 获取关系数据
	if RelationshipManager:
		var relationship: Dictionary = RelationshipManager.get_relationship(role_id)
		context["affinity"] = relationship.get("affinity", 0)
		context["relationship_level"] = relationship.get("level", "stranger")
	
	return context

# ==================== UI设置 ====================

func _setup_ui() -> void:
	# 创建手机面板
	phone_panel = PanelContainer.new()
	phone_panel.name = "PhonePanel"
	phone_panel.custom_minimum_size = Vector2(380, 720)
	phone_panel.size = Vector2(380, 720)
	phone_panel.position = Vector2(770, 1080)  # 初始位置在屏幕下方
	
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = phone_colors["bg"]
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.shadow_color = Color(0, 0, 0, 0.4)
	panel_style.shadow_size = 20
	phone_panel.add_theme_stylebox_override("panel", panel_style)

	# 创建遮罩
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "PhoneOverlay"
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			close_phone()
	)
	add_child(overlay)
	_overlay = overlay
	
	add_child(phone_panel)
	
	# 创建主容器
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_panel.add_child(main_vbox)
	
	# 状态栏
	_setup_status_bar(main_vbox)
	
	# 屏幕区域
	phone_screen = VBoxContainer.new()
	phone_screen.name = "PhoneScreen"
	phone_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phone_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(phone_screen)
	
	# 底部导航栏
	_setup_nav_bar(main_vbox)
	
	# 初始化主屏幕
	_show_home_screen()

func _setup_status_bar(parent: VBoxContainer) -> void:
	status_bar_top = HBoxContainer.new()
	status_bar_top.name = "StatusBar"
	status_bar_top.custom_minimum_size = Vector2(0, 28)
	status_bar_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var status_style: StyleBoxFlat = StyleBoxFlat.new()
	status_style.bg_color = phone_colors["status_bg"]
	status_bar_top.add_theme_stylebox_override("panel", status_style)
	
	parent.add_child(status_bar_top)
	
	# 时间标签
	_time_label = Label.new()
	_time_label.text = _get_current_time()
	_time_label.add_theme_color_override("font_color", phone_colors["text"])
	status_bar_top.add_child(_time_label)
	
	# 定时更新时间
	var timer: Timer = Timer.new()
	timer.wait_time = 60.0
	timer.timeout.connect(func(): _time_label.text = _get_current_time())
	add_child(timer)
	timer.start()

func _setup_nav_bar(parent: VBoxContainer) -> void:
	var nav_bar: HBoxContainer = HBoxContainer.new()
	nav_bar.name = "NavBar"
	nav_bar.custom_minimum_size = Vector2(0, 50)
	nav_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var nav_style: StyleBoxFlat = StyleBoxFlat.new()
	nav_style.bg_color = phone_colors["nav_bg"]
	nav_bar.add_theme_stylebox_override("panel", nav_style)
	
	parent.add_child(nav_bar)
	
	# 返回按钮
	back_btn = Button.new()
	back_btn.text = "◀"
	back_btn.flat = true
	back_btn.add_theme_color_override("font_color", phone_colors["text"])
	back_btn.pressed.connect(_on_back_pressed)
	nav_bar.add_child(back_btn)
	
	# 主页按钮
	home_btn = Button.new()
	home_btn.text = "○"
	home_btn.flat = true
	home_btn.add_theme_color_override("font_color", phone_colors["text"])
	home_btn.pressed.connect(_on_home_pressed)
	nav_bar.add_child(home_btn)

# ==================== 屏幕管理 ====================

func _show_home_screen() -> void:
	# 清空屏幕
	for child: Node in phone_screen.get_children():
		child.queue_free()
	
	current_app = ""
	_nav_stack.clear()
	
	# 创建APP网格
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_screen.add_child(grid)
	
	# 添加APP图标
	for app: Dictionary in _current_apps:
		var app_btn: Button = _create_app_button(app)
		grid.add_child(app_btn)

func _create_app_button(app: Dictionary) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(100, 100)
	btn.text = app["icon"] + "\n" + app["name"]
	btn.add_theme_color_override("font_color", phone_colors["text"])
	
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = app.get("color", phone_colors["accent"])
	btn_style.corner_radius_top_left = 16
	btn_style.corner_radius_top_right = 16
	btn_style.corner_radius_bottom_left = 16
	btn_style.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("normal", btn_style)
	
	btn.pressed.connect(func(): _open_app(app["id"]))
	
	return btn

func _open_app(app_id: String) -> void:
	if current_app != "":
		_nav_stack.append(current_app)
	
	current_app = app_id
	app_opened.emit(app_id)
	
	# 根据APP ID打开对应界面
	match app_id:
		"contacts":
			_show_contacts_app()
		"wechat":
			_show_wechat_app()
		"moments":
			_show_moments_app()
		"schedule":
			_show_schedule_app()
		"notes":
			_show_notes_app()
		"settings":
			_show_settings_app()
		_:
			# 检查是否为模块注入的APP
			_show_module_app(app_id)

func _show_module_app(app_id: String) -> void:
	# 查找模块APP
	for app: Dictionary in _current_apps:
		if app["id"] == app_id and app.get("is_module", false):
			# TODO: 加载模块APP场景
			_log("打开模块APP: %s" % app_id)
			_show_placeholder_app(app["name"])
			return
	
	_show_placeholder_app("未知应用")

func _show_placeholder_app(app_name: String) -> void:
	for child: Node in phone_screen.get_children():
		child.queue_free()
	
	var label: Label = Label.new()
	label.text = app_name + "\n\n（功能开发中）"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", phone_colors["text"])
	phone_screen.add_child(label)

# ==================== 各APP界面 ====================

func _show_contacts_app() -> void:
	for child: Node in phone_screen.get_children():
		child.queue_free()
	
	# 标题
	_title_label = Label.new()
	_title_label.text = "通讯录"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", phone_colors["text"])
	_title_label.add_theme_font_size_override("font_size", 20)
	phone_screen.add_child(_title_label)
	
	# 联系人列表
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_screen.add_child(scroll)
	
	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	
	# 获取联系人
	if RelationshipManager:
		for role_id: String in RelationshipManager.get_all_relationships():
			var relationship: Dictionary = RelationshipManager.get_relationship(role_id)
			var contact_btn: Button = _create_contact_button(role_id, relationship)
			list.add_child(contact_btn)

func _create_contact_button(role_id: String, relationship: Dictionary) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0, 64)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var name: String = relationship.get("name", role_id)
	var affinity: int = relationship.get("affinity", 0)
	var level_name: String = relationship.get("level_name", "")
	var unread: int = WechatSystem.get_unread_count(role_id) if WechatSystem else 0
	btn.text = "👤 %s  [%s %d]" % [name, level_name, affinity]
	if unread > 0:
		btn.text += "   ·   未读 %d" % unread
	
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.11, 0.13, 0.18, 1)
	normal_style.set_corner_radius_all(10)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.25, 0.33, 0.45, 1)
	btn.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(0.16, 0.2, 0.28, 1)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.add_theme_color_override("font_color", phone_colors["text"])
	btn.pressed.connect(func(): _open_chat(role_id))
	
	return btn

func _show_wechat_app() -> void:
	for child: Node in phone_screen.get_children():
		child.queue_free()
	
	var root := HBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	phone_screen.add_child(root)
	
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(130, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_style := StyleBoxFlat.new()
	left_style.bg_color = Color(0.09, 0.11, 0.15, 1)
	left_style.set_corner_radius_all(8)
	left_panel.add_theme_stylebox_override("panel", left_style)
	root.add_child(left_panel)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 6)
	left_panel.add_child(left_vbox)
	
	var contacts_title := Label.new()
	contacts_title.text = "聊天"
	contacts_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contacts_title.add_theme_color_override("font_color", phone_colors["text"])
	contacts_title.add_theme_font_size_override("font_size", 16)
	left_vbox.add_child(contacts_title)
	
	var partner_scroll := ScrollContainer.new()
	partner_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partner_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(partner_scroll)
	
	_wechat_partner_list = VBoxContainer.new()
	_wechat_partner_list.add_theme_constant_override("separation", 4)
	partner_scroll.add_child(_wechat_partner_list)
	
	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 6)
	root.add_child(right_panel)
	
	var chat_header := Label.new()
	chat_header.text = "微信"
	chat_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chat_header.add_theme_color_override("font_color", phone_colors["green"])
	chat_header.add_theme_font_size_override("font_size", 18)
	right_panel.add_child(chat_header)
	
	var chat_panel := PanelContainer.new()
	chat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var chat_style := StyleBoxFlat.new()
	chat_style.bg_color = Color(0.08, 0.1, 0.13, 1)
	chat_style.set_corner_radius_all(8)
	chat_panel.add_theme_stylebox_override("panel", chat_style)
	right_panel.add_child(chat_panel)
	
	var chat_margin := MarginContainer.new()
	chat_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_margin.add_theme_constant_override("margin_left", 8)
	chat_margin.add_theme_constant_override("margin_top", 8)
	chat_margin.add_theme_constant_override("margin_right", 8)
	chat_margin.add_theme_constant_override("margin_bottom", 8)
	chat_panel.add_child(chat_margin)
	
	var chat_scroll := ScrollContainer.new()
	chat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_margin.add_child(chat_scroll)
	
	_wechat_chat_content = RichTextLabel.new()
	_wechat_chat_content.bbcode_enabled = true
	_wechat_chat_content.fit_content = false
	_wechat_chat_content.scroll_following = true
	_wechat_chat_content.add_theme_color_override("default_color", phone_colors["text"])
	chat_scroll.add_child(_wechat_chat_content)
	
	var send_panel := PanelContainer.new()
	send_panel.custom_minimum_size = Vector2(0, 130)
	var send_style := StyleBoxFlat.new()
	send_style.bg_color = Color(0.10, 0.12, 0.16, 1)
	send_style.set_corner_radius_all(8)
	send_panel.add_theme_stylebox_override("panel", send_style)
	right_panel.add_child(send_panel)
	
	var send_margin := MarginContainer.new()
	send_margin.add_theme_constant_override("margin_left", 8)
	send_margin.add_theme_constant_override("margin_top", 8)
	send_margin.add_theme_constant_override("margin_right", 8)
	send_margin.add_theme_constant_override("margin_bottom", 8)
	send_panel.add_child(send_margin)
	
	var send_vbox := VBoxContainer.new()
	send_vbox.add_theme_constant_override("separation", 4)
	send_margin.add_child(send_vbox)
	
	var send_title := Label.new()
	send_title.text = "可发送消息（今日剩余 %d）" % get_remaining_messages()
	send_title.add_theme_color_override("font_color", phone_colors["text_secondary"])
	send_title.add_theme_font_size_override("font_size", 12)
	send_vbox.add_child(send_title)
	
	var send_scroll := ScrollContainer.new()
	send_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	send_vbox.add_child(send_scroll)
	
	_wechat_send_options = VBoxContainer.new()
	_wechat_send_options.add_theme_constant_override("separation", 4)
	send_scroll.add_child(_wechat_send_options)
	
	_refresh_wechat_partners()
	_refresh_wechat_chat()
	_refresh_wechat_send_options()

func _open_chat(role_id: String) -> void:
	if current_app == "wechat":
		_wechat_current_role = role_id
		if WechatSystem:
			WechatSystem.open_chat(role_id)
		_refresh_wechat_chat()
		_refresh_wechat_send_options()
		_refresh_wechat_partners()
		return
	if WechatSystem:
		WechatSystem.open_chat(role_id)

func _refresh_wechat_partners() -> void:
	if not _wechat_partner_list:
		return
	for child: Node in _wechat_partner_list.get_children():
		child.queue_free()
	
	if not RelationshipManager:
		return
	
	var role_ids: Array = RelationshipManager.get_all_relationships()
	if _wechat_current_role.is_empty() and not role_ids.is_empty():
		_wechat_current_role = role_ids[0]
	
	for role_id in role_ids:
		var rel: Dictionary = RelationshipManager.get_relationship(role_id)
		if rel.is_empty():
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var unread: int = WechatSystem.get_unread_count(role_id) if WechatSystem else 0
		var name: String = rel.get("name", role_id)
		btn.text = "%s%s" % [name, ("  (%d)" % unread) if unread > 0 else ""]
		btn.pressed.connect(_on_partner_selected.bind(role_id))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.14, 0.17, 0.22, 1) if role_id == _wechat_current_role else Color(0.1, 0.12, 0.16, 1)
		normal.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_color_override("font_color", phone_colors["text"])
		_wechat_partner_list.add_child(btn)

func _on_partner_selected(role_id: String) -> void:
	_open_chat(role_id)

func _refresh_wechat_chat() -> void:
	if not _wechat_chat_content:
		return
	_wechat_chat_content.clear()
	
	if _wechat_current_role.is_empty():
		_wechat_chat_content.append_text("请选择一个联系人开始聊天。")
		return
	
	var rel: Dictionary = RelationshipManager.get_relationship(_wechat_current_role) if RelationshipManager else {}
	var display_name: String = rel.get("name", _wechat_current_role)
	_wechat_chat_content.append_text("[b]%s[/b]\n\n" % display_name)
	
	if not WechatSystem:
		_wechat_chat_content.append_text("微信系统不可用")
		return
	
	var history: Array[Dictionary] = WechatSystem.get_chat_history(_wechat_current_role)
	if history.is_empty():
		_wechat_chat_content.append_text("还没有聊天记录。")
		return
	
	for msg in history:
		var is_player: bool = msg.get("sender", "npc") == "player"
		var prefix: String = "你" if is_player else display_name
		var line_color: String = "#9EE6A8" if is_player else "#C8D4E6"
		_wechat_chat_content.append_text("[color=%s]%s：%s[/color]\n" % [line_color, prefix, msg.get("text", "")])

func _refresh_wechat_send_options() -> void:
	if not _wechat_send_options:
		return
	for child: Node in _wechat_send_options.get_children():
		child.queue_free()
	
	if _wechat_current_role.is_empty():
		var hint := Label.new()
		hint.text = "先选择联系人"
		hint.add_theme_color_override("font_color", phone_colors["dim"])
		_wechat_send_options.add_child(hint)
		return
	
	if not can_send_message():
		var limit := Label.new()
		limit.text = "今日主动消息已达上限"
		limit.add_theme_color_override("font_color", phone_colors["orange"])
		_wechat_send_options.add_child(limit)
		return
	
	var options: Array[Dictionary] = get_sendable_messages(_wechat_current_role)
	if options.is_empty():
		var fallback := ["在吗？", "一起吃饭吗？", "今天怎么样？"]
		for text in fallback:
			var btn := _make_send_option_button(text)
			_wechat_send_options.add_child(btn)
		return
	
	for option in options:
		var text: String = option.get("text", "")
		if text.is_empty():
			continue
		var btn := _make_send_option_button(text)
		_wechat_send_options.add_child(btn)

func _make_send_option_button(text: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 28)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = text
	btn.pressed.connect(func(): _on_send_option_pressed(text))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.19, 0.15, 1)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.86, 1))
	return btn

func _on_send_option_pressed(text: String) -> void:
	if _wechat_current_role.is_empty():
		return
	var ok: bool = send_message(_wechat_current_role, text)
	if not ok:
		return
	_refresh_wechat_chat()
	_refresh_wechat_send_options()
	_refresh_wechat_partners()

func _show_moments_app() -> void:
	_show_placeholder_app("朋友圈")

func _show_schedule_app() -> void:
	_show_placeholder_app("日程")

func _show_notes_app() -> void:
	_show_placeholder_app("备忘录")

func _show_settings_app() -> void:
	_show_placeholder_app("设置")

# ==================== 导航 ====================

func _on_back_pressed() -> void:
	if _nav_stack.is_empty():
		_close_phone()
	else:
		var prev_app: String = _nav_stack.pop_back()
		_open_app(prev_app)

func _on_home_pressed() -> void:
	_show_home_screen()

# ==================== 手机开关 ====================

func open_phone() -> void:
	if is_open:
		return
	
	is_open = true
	show()
	if _overlay:
		_overlay.visible = true
	
	# 动画
	if _anim_tween:
		_anim_tween.kill()
	_anim_tween = create_tween()
	_anim_tween.set_ease(Tween.EASE_OUT)
	_anim_tween.set_trans(Tween.TRANS_QUART)
	_anim_tween.tween_property(phone_panel, "position:y", 180.0, ANIM_DURATION)
	
	phone_opened.emit()
	_log("手机打开")

func close_phone() -> void:
	if not is_open:
		return
	
	_close_phone()

func _close_phone() -> void:
	is_open = false
	
	# 动画
	if _anim_tween:
		_anim_tween.kill()
	_anim_tween = create_tween()
	_anim_tween.set_ease(Tween.EASE_IN)
	_anim_tween.set_trans(Tween.TRANS_QUART)
	_anim_tween.tween_property(phone_panel, "position:y", 1080.0, ANIM_DURATION)
	if _overlay:
		_overlay.visible = false
	_anim_tween.tween_callback(func(): hide())
	
	phone_closed.emit()
	_log("手机关闭")

func toggle_phone() -> void:
	if is_open:
		close_phone()
	else:
		open_phone()

# ==================== 工具方法 ====================

func _get_current_time() -> String:
	var time: Dictionary = Time.get_time_dict_from_system()
	return "%02d:%02d" % [time.hour, time.minute]

func _get_current_day() -> int:
	# 从ModuleManager玩家状态获取当前天数
	if ModuleManager:
		var state: Dictionary = ModuleManager.get_player_state()
		return state.get("day_index", 0)
	return 0

func _get_current_phase() -> String:
	# 从ModuleManager玩家状态获取当前阶段
	if ModuleManager:
		var state: Dictionary = ModuleManager.get_player_state()
		return state.get("phase", "")
	return ""

func _log(message: String) -> void:
	print("[PhoneSystem] %s" % message)

# ==================== 公共接口 ====================

## 检查手机是否打开
func is_phone_open() -> bool:
	return is_open

## 获取当前打开的APP
func get_current_app() -> String:
	return current_app

## 刷新界面
func refresh() -> void:
	_refresh_apps()
	if current_app == "":
		_show_home_screen()

# ✅ 阶段5完成

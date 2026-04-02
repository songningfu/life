# res://scripts/ui/ChatWindow.gd
extends PanelContainer

const MESSAGE_BUBBLE_SCENE := preload("res://scenes/ui/MessageBubble.tscn")
const REPLY_OPTION_BUTTON_SCENE := preload("res://scenes/ui/ReplyOptionButton.tscn")

signal back_pressed

var current_contact_id: String = ""

@onready var back_button: Button = $VBox2/ChatTopBar/BackButton
@onready var send_button: Button = $VBox2/InputBar/SendButton
@onready var input_field: LineEdit = $VBox2/InputBar/InputField
@onready var chat_title: Label = $VBox2/ChatTopBar/ChatTitle
@onready var message_list: VBoxContainer = $VBox2/ScrollContainer/MessageList
@onready var reply_options: VBoxContainer = $VBox2/ReplyOptions
@onready var input_bar: HBoxContainer = $VBox2/InputBar
@onready var scroll_container: ScrollContainer = $VBox2/ScrollContainer

func _ready() -> void:
	visible = false

	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	if not send_button.pressed.is_connected(_on_send_button_pressed):
		send_button.pressed.connect(_on_send_button_pressed)

	if not input_field.text_submitted.is_connected(_on_input_submitted):
		input_field.text_submitted.connect(_on_input_submitted)

func load_chat(contact_id: String) -> void:
	current_contact_id = contact_id
	visible = true

	var contact_info: Dictionary = {}
	if WechatSystem and WechatSystem.has_method("get_contact_info"):
		contact_info = WechatSystem.get_contact_info(contact_id)

	chat_title.text = str(contact_info.get("name", contact_id))

	for child: Node in message_list.get_children():
		child.queue_free()

	if WechatSystem and WechatSystem.has_method("get_chat_history"):
		var history: Array = WechatSystem.get_chat_history(contact_id)
		for msg_item: Variant in history:
			if msg_item is Dictionary:
				_add_message_bubble(msg_item as Dictionary)

	if WechatSystem and WechatSystem.has_method("get_sendable_messages"):
		var options: Array = WechatSystem.get_sendable_messages(contact_id)
		_show_reply_options(options)

	if WechatSystem and WechatSystem.has_method("mark_as_read"):
		WechatSystem.mark_as_read(contact_id)

	_scroll_to_bottom()

func _add_message_bubble(msg: Dictionary) -> void:
	var bubble := MESSAGE_BUBBLE_SCENE.instantiate() as HBoxContainer
	if bubble == null:
		return

	var left_spacer := bubble.get_node("LeftSpacer") as Control
	var right_spacer := bubble.get_node("RightSpacer") as Control
	var bubble_panel := bubble.get_node("BubblePanel") as PanelContainer
	var message_label := bubble.get_node("BubblePanel/BubbleMargin/MessageLabel") as RichTextLabel
	if left_spacer == null or right_spacer == null or bubble_panel == null or message_label == null:
		return

	var sender: String = str(msg.get("from", "npc"))
	var text: String = str(msg.get("text", ""))
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(14)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0

	if sender == "player":
		left_spacer.size_flags_stretch_ratio = 1.3
		right_spacer.size_flags_stretch_ratio = 0.35
		style.bg_color = Color(0.12, 0.32, 0.46, 0.96)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.34, 0.72, 0.92, 0.88)
		message_label.text = "[right][color=#9fe7ff][b]你[/b][/color]\n%s[/right]" % text
	else:
		left_spacer.size_flags_stretch_ratio = 0.35
		right_spacer.size_flags_stretch_ratio = 1.3
		style.bg_color = Color(0.10, 0.12, 0.18, 0.96)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.26, 0.30, 0.40, 0.9)
		message_label.text = "[left][color=#ffffff][b]对方[/b][/color]\n%s[/left]" % text

	bubble_panel.add_theme_stylebox_override("panel", style)
	message_list.add_child(bubble)

func _show_reply_options(options: Array) -> void:
	for child: Node in reply_options.get_children():
		child.queue_free()

	if options.size() > 0:
		reply_options.visible = true
		input_bar.visible = false

		for item: Variant in options:
			if item is Dictionary:
				var option: Dictionary = item
				var btn := REPLY_OPTION_BUTTON_SCENE.instantiate() as Button
				if btn == null:
					continue
				btn.text = str(option.get("text", "（空消息）"))
				btn.pressed.connect(_on_reply_option_pressed.bind(option))
				reply_options.add_child(btn)
	else:
		reply_options.visible = false
		input_bar.visible = true

func _on_reply_option_pressed(option: Dictionary) -> void:
	if current_contact_id.is_empty():
		return
	if not WechatSystem:
		return

	WechatSystem.send_message(current_contact_id, option)
	load_chat(current_contact_id)

func _on_send_button_pressed() -> void:
	_send_free_text()

func _on_input_submitted(_text: String) -> void:
	_send_free_text()

func _send_free_text() -> void:
	if current_contact_id.is_empty():
		return
	if not WechatSystem:
		return

	var text: String = input_field.text.strip_edges()
	if text.is_empty():
		return

	var message: Dictionary = {
		"id": "free_input",
		"text": text,
		"effects": {}
	}
	WechatSystem.send_message(current_contact_id, message)
	input_field.text = ""
	load_chat(current_contact_id)

func _on_back_button_pressed() -> void:
	back_pressed.emit()

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

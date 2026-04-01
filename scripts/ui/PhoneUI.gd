# res://scripts/ui/PhoneUI.gd
extends CanvasLayer

signal phone_opened
signal phone_closed

var is_open: bool = false
var unread_count: int = 0
var current_contact_id: String = ""

func _ready() -> void:
	layer = 10
	visible = true

	%PhoneBG.visible = false
	%PhonePanel.visible = false
	%ChatWindow.visible = false

	if not %CloseBtn.pressed.is_connected(close_phone):
		%CloseBtn.pressed.connect(close_phone)

	if not %PhoneToggleBtn.pressed.is_connected(toggle_phone):
		%PhoneToggleBtn.pressed.connect(toggle_phone)

	if not %ChatWindow.back_pressed.is_connected(_on_chat_back_pressed):
		%ChatWindow.back_pressed.connect(_on_chat_back_pressed)

	if WechatSystem:
		if WechatSystem.has_signal("message_received") and not WechatSystem.message_received.is_connected(_on_message_received):
			WechatSystem.message_received.connect(_on_message_received)
		if WechatSystem.has_signal("contacts_updated") and not WechatSystem.contacts_updated.is_connected(_refresh_contacts):
			WechatSystem.contacts_updated.connect(_refresh_contacts)

	_refresh_contacts()
	_refresh_badge()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_phone"):
		toggle_phone()
		get_viewport().set_input_as_handled()
		return

	if is_open and event.is_action_pressed("ui_cancel"):
		if %ChatWindow.visible:
			_on_chat_back_pressed()
		else:
			close_phone()
		get_viewport().set_input_as_handled()

func toggle_phone() -> void:
	if is_open:
		close_phone()
	else:
		open_phone()

func open_phone() -> void:
	if is_open:
		return
	is_open = true
	%PhoneBG.visible = true
	%PhonePanel.visible = true

	_refresh_contacts()
	_refresh_badge()

	if %AnimPlayer and %AnimPlayer.has_animation("phone_slide_in"):
		%AnimPlayer.play("phone_slide_in")

	phone_opened.emit()

func close_phone() -> void:
	if not is_open:
		return

	if %AnimPlayer and %AnimPlayer.has_animation("phone_slide_out"):
		%AnimPlayer.play("phone_slide_out")
		await %AnimPlayer.animation_finished

	is_open = false
	%PhoneBG.visible = false
	%PhonePanel.visible = false
	%ChatWindow.visible = false
	current_contact_id = ""

	phone_closed.emit()

func _refresh_contacts() -> void:
	for child: Node in %ContactList.get_children():
		child.queue_free()

	if not WechatSystem:
		return

	var contacts: Array = WechatSystem.get_contacts()
	for item: Variant in contacts:
		if item is Dictionary:
			var contact: Dictionary = item
			var contact_id: String = str(contact.get("id", ""))
			if contact_id.is_empty():
				continue

			var row: HBoxContainer = HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var btn: Button = Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.text = _build_contact_button_text(contact)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(_open_chat.bind(contact_id))
			row.add_child(btn)

			var contact_unread: int = int(contact.get("unread_count", 0))
			if contact_unread > 0:
				var badge: Label = Label.new()
				badge.text = str(contact_unread)
				badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				badge.custom_minimum_size = Vector2(26, 26)
				badge.add_theme_color_override("font_color", Color(1, 1, 1, 1))
				row.add_child(badge)

			%ContactList.add_child(row)

	_recalculate_total_unread()

func _build_contact_button_text(contact: Dictionary) -> String:
	var name_text: String = str(contact.get("name", contact.get("id", "未知联系人")))
	var preview: String = str(contact.get("last_preview", ""))
	if preview.is_empty():
		return name_text
	return "%s\n%s" % [name_text, preview]

func _open_chat(contact_id: String) -> void:
	current_contact_id = contact_id
	%ChatWindow.visible = true
	%ChatWindow.load_chat(contact_id)

	if WechatSystem and WechatSystem.has_method("mark_as_read"):
		WechatSystem.mark_as_read(contact_id)

	_refresh_contacts()
	_refresh_badge()

func _on_chat_back_pressed() -> void:
	%ChatWindow.visible = false
	current_contact_id = ""
	_refresh_contacts()
	_refresh_badge()

func _on_message_received(from_id: String, _message: Dictionary) -> void:
	if is_open and %ChatWindow.visible and current_contact_id == from_id:
		%ChatWindow.load_chat(from_id)
		if WechatSystem and WechatSystem.has_method("mark_as_read"):
			WechatSystem.mark_as_read(from_id)

	_refresh_contacts()
	_refresh_badge()

func _recalculate_total_unread() -> void:
	unread_count = 0
	if not WechatSystem:
		return
	var contacts: Array = WechatSystem.get_contacts()
	for item: Variant in contacts:
		if item is Dictionary:
			unread_count += int((item as Dictionary).get("unread_count", 0))

func _refresh_badge() -> void:
	_recalculate_total_unread()
	if unread_count > 0:
		%NotificationBadge.visible = true
		%NotificationBadge.text = str(unread_count)
	else:
		%NotificationBadge.visible = false
		%NotificationBadge.text = ""

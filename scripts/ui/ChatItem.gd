extends PanelContainer

signal chat_opened()

var _npc_data := {}

func setup(npc_data: Dictionary):
	_npc_data = npc_data
	$HBox/InfoVBox/NpcName.text = npc_data.get("name", "")
	var last_data: Dictionary = WechatSystem.get_last_message(npc_data.get("id", ""))
	var last_text: String = last_data.get("text", "") if last_data is Dictionary else ""
	$HBox/InfoVBox/LastMsg.text = last_text if not last_text.is_empty() else "暂无消息"
	$HBox/UnreadDot.visible = WechatSystem.get_unread_count(npc_data.get("id", "")) > 0

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chat_opened.emit()
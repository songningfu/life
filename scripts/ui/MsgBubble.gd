extends HBoxContainer

@onready var left_spacer := $LeftSpacer
@onready var bubble := $Bubble
@onready var msg_label := $Bubble/MsgLabel
@onready var right_spacer := $RightSpacer

func setup(text: String, is_self: bool):
	msg_label.text = text
	left_spacer.visible = is_self
	right_spacer.visible = not is_self
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#295238") if is_self else UIColors.CARD_BG
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	bubble.add_theme_stylebox_override("panel", style)
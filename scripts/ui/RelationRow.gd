extends HBoxContainer

@onready var npc_name := $NpcName
@onready var hearts_container := $HeartsContainer
@onready var status_tag := $StatusTag

func _ready():
	for i in range(5):
		if i >= hearts_container.get_child_count():
			break
		var heart = hearts_container.get_child(i)
		if heart is TextureRect and heart.texture == null:
			var label = Label.new()
			label.text = "♥"
			label.add_theme_font_size_override("font_size", 12)
			hearts_container.add_child(label)
			hearts_container.move_child(label, i)
			heart.queue_free()

func setup(char_name: String, affection: float, status: String):
	npc_name.text = char_name
	status_tag.text = status

	var full_hearts := int(affection / 20.0)
	for i in range(min(5, hearts_container.get_child_count())):
		var heart = hearts_container.get_child(i)
		if heart is TextureRect:
			heart.modulate = UIColors.ACCENT_RED if i < full_hearts else UIColors.TEXT_SECONDARY
		elif heart is Label:
			heart.add_theme_color_override("font_color", UIColors.ACCENT_RED if i < full_hearts else UIColors.TEXT_SECONDARY)
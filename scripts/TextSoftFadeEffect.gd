@tool
extends RichTextEffect

var bbcode := "soft"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var span := float(char_fx.env.get("span", 0.28))
	var delay := float(char_fx.env.get("delay", 0.012))
	var distance := float(char_fx.env.get("distance", 10.0))
	var rise := float(char_fx.env.get("rise", 3.0))

	var elapsed := char_fx.elapsed_time - float(char_fx.relative_index) * delay
	var t := clampf(elapsed / max(span, 0.001), 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)

	var color := char_fx.color
	color.a *= 0.32 + eased * 0.68
	char_fx.color = color
	char_fx.offset = Vector2((1.0 - eased) * distance, (1.0 - eased) * rise)
	return true

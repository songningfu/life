@tool
extends RichTextEffect

var bbcode := "mark"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var strength := float(char_fx.env.get("strength", 0.1))
	var speed := float(char_fx.env.get("speed", 1.6))
	var phase := float(char_fx.env.get("phase", 0.16))

	var wave := 0.5 + 0.5 * sin(char_fx.elapsed_time * speed + float(char_fx.relative_index) * phase)
	var lift := strength * (0.65 + wave * 0.35)

	var color := char_fx.color
	color.r = min(color.r + lift * 0.55, 1.0)
	color.g = min(color.g + lift * 0.75, 1.0)
	color.b = min(color.b + lift, 1.0)
	char_fx.color = color
	return true

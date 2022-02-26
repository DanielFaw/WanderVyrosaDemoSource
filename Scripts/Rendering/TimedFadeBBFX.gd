extends RichTextEffect
class_name RichTextFade

var bbcode = "fadeLine"
var resetTimer = true;
var startTime = 0; 

func _process_custom_fx(line_fx):
	
	# ColorHex form = #AARRGGBB
	var color = line_fx.env.get("colorHex", "#FFFFFFFF")
	var offset = line_fx.env.get("offset", 0.0)
	var fadeSpeed = line_fx.env.get("speed",1.0);
	color = Color(color)
	
	if(resetTimer):
		startTime = line_fx.elapsed_time
		resetTimer = false
		pass

	var alpha = lerp(1.0,0.0,(line_fx.elapsed_time - startTime - offset) * fadeSpeed);
	
	if(alpha <= 0):
		alpha = 0.0
	color.a = alpha
	line_fx.color = color 
	return true
	pass

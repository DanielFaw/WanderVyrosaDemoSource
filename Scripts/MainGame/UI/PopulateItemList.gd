extends ItemList


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = true
	_add_color_text()
	_set_font_color()
	select(Utilities.GetRandInt(0, get_item_count() - 1))
	pass # Replace with function body.

func _add_color_text():
	add_item("Red")
	add_item("Orange")
	add_item("Yellow")
	add_item("Lime")
	add_item("Green")
	add_item("Cyan")
	add_item("Blue")
	add_item("Purple")
	add_item("Lavender")
	add_item("Pink")
	pass

func _set_font_color():
	set_item_custom_fg_color(0, Color.red)
	set_item_custom_fg_color(1, Color.orange)
	set_item_custom_fg_color(2, Color.yellow)
	set_item_custom_fg_color(3, Color.greenyellow)
	set_item_custom_fg_color(4, Color.green)
	set_item_custom_fg_color(5, Color.cyan)
	set_item_custom_fg_color(6, Color.royalblue)
	set_item_custom_fg_color(7, Color.indigo)
	set_item_custom_fg_color(8, Color.purple)
	set_item_custom_fg_color(9, Color.deeppink)
	pass

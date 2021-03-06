extends Button

export var reference_path = ""
export(bool) var start_focused = false

func _ready() -> void:
	if(start_focused):
		grab_focus()
		
	connect("mouse_entered", self, "on_button_mouse_entered")
	connect("pressed", self, "on_button_pressed")

func on_button_mouse_entered():
	grab_focus()
	
func on_button_pressed():
	if(reference_path != ""):
		get_tree().change_scene(reference_path)
	else:
		get_tree().quit()

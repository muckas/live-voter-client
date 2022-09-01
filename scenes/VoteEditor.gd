extends Control

export(PackedScene) var vote_page_scene:PackedScene

onready var vbox:VBoxContainer = $VBoxContainer
onready var tab_container:TabContainer = $VBoxContainer/TabContainer
onready var new_page_popup:Popup = $PopupNewPage
onready var new_page_name:LineEdit = $PopupNewPage/VBoxContainer/PageNameEdit

func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()


func _on_viewport_size_changed() -> void:
	vbox.rect_position = Vector2(16, 16)
	vbox.rect_size = get_viewport_rect().size - Vector2(32, 32)

func _on_BtNewPage_pressed() -> void:
	new_page_name.text = ""
	new_page_popup.popup_centered()
	new_page_name.grab_focus()

func _on_PageNameEdit_text_entered(_new_text:String) -> void:
	new_page_popup.visible = false
	var vote_page_instance = vote_page_scene.instance()
	vote_page_instance.set_name(new_page_name.text)
	tab_container.add_child(vote_page_instance)

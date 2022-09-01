extends Control
class_name VoteItemEdit

var name_hover:bool = false

onready var vbox:VBoxContainer = $VBoxContainer
onready var name_edit:LineEdit = $VBoxContainer/NameEdit
onready var name_button:Button = $VBoxContainer/NameButton
onready var file_dialog:FileDialog = $FileDialog
onready var texture_rect:TextureRect = $VBoxContainer/TextureRect

func _ready() -> void:
	connect("resized", self, "_on_self_resized")
	_on_self_resized()


func _on_self_resized() -> void:
	vbox.rect_size = rect_size

func _on_NameButton_pressed() -> void:
	name_button.visible = false
	name_edit.visible = true
	name_edit.grab_focus()

func _on_NameEdit_text_entered(_new_text:String) -> void:
	name_button.text = name_edit.text
	name_button.visible = true
	name_edit.visible = false

func _on_BtRemove_pressed() -> void:
	queue_free()

func _on_BtLoadImage_pressed() -> void:
	if Global.file_dialog_path:
		file_dialog.set_current_dir(Global.file_dialog_path)
	file_dialog.popup_centered()

func _on_FileDialog_file_selected(path:String) -> void:
	file_dialog.visible = false
	Global.file_dialog_path = file_dialog.get_current_dir()
	var img = Image.new()
	var tex = ImageTexture.new()
	img.load(path)
	tex.create_from_image(img)
	texture_rect.texture = tex

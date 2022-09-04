extends Control
class_name VotePageEdit

export(PackedScene) var vote_item_scene:PackedScene

onready var vbox:VBoxContainer = $VBoxContainer
onready var grid:GridContainer = $VBoxContainer/GridContainer
onready var name_popup:Popup = $NamePopup
onready var name_edit:LineEdit = $NamePopup/VBoxContainer/PageNameEdit
onready var columns_spinbox:SpinBox = $VBoxContainer/HBoxContainer/ColumnsSpinBox

func _ready() -> void:
	connect("resized", self, "_on_self_resized")
	_on_self_resized()


func return_vote_page() -> Dictionary:
	var vote_page:Dictionary = Dictionary()
	vote_page["page_name"] = get_name()
	vote_page["page_columns"] = columns_spinbox.value
	vote_page["page_items"] = Dictionary()
	for index in range(grid.get_child_count()):
		vote_page["page_items"][index] = grid.get_child(index).return_vote_item()
	return vote_page


func _on_self_resized() -> void:
	vbox.rect_position = Vector2(16, 16)
	vbox.rect_size = rect_size - Vector2(32, 32)

func _on_BtNewItem_pressed() -> void:
	var vote_item_instance = vote_item_scene.instance()
	grid.add_child(vote_item_instance)

func _on_ColumnsSpinBox_value_changed(value:int) -> void:
	grid.columns = value

func _on_BtRenamePage_pressed():
	name_edit.text = get_name()
	name_popup.popup_centered()
	name_edit.grab_focus()

func _on_PageNameEdit_text_entered(_new_text:String) -> void:
	name_popup.visible = false
	set_name(name_edit.text)

func _on_BtDeletePage_pressed():
	queue_free()

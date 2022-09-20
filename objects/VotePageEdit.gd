extends Control
class_name VotePageEdit

export(PackedScene) var vote_item_scene:PackedScene

onready var grid_update_timer:Timer = $GridUpdateTimer
onready var vbox:VBoxContainer = $VBoxContainer
onready var grid:GridContainer = $VBoxContainer/GridContainer
onready var name_popup:Popup = $NamePopup
onready var name_edit:LineEdit = $NamePopup/VBoxContainer/PageNameEdit

func _ready() -> void:
	connect("resized", self, "_on_self_resized")
	_on_self_resized()


func return_vote_page() -> Dictionary:
	var vote_page:Dictionary = Dictionary()
	vote_page["page_name"] = get_name()
	vote_page["page_items"] = Dictionary()
	for index in range(grid.get_child_count()):
		vote_page["page_items"][index] = grid.get_child(index).return_vote_item()
	return vote_page

func set_page_name(name:String) -> void:
	set_name(name)

func add_vote_item(name:String, page_index:int, item_index:int) -> void:
	var vote_item_instance:VoteItemEdit = vote_item_scene.instance()
	grid.add_child(vote_item_instance)
	vote_item_instance.set_item_name(name)
	vote_item_instance.set_item_image(page_index, item_index)
	vote_item_instance.connect("item_removed", self, "_grid_children_changed")
	_grid_children_changed()

func upload_images(vote_id:String, page_index:int) -> bool:
	for item_index in range(grid.get_child_count()):
		if grid.get_child(item_index).upload_image(vote_id, page_index, item_index) == false:
			return false
	return true

func _on_self_resized() -> void:
	vbox.rect_position = Vector2(16, 16)
	vbox.rect_size = rect_size - Vector2(32, 32)

func _on_BtNewItem_pressed() -> void:
	var vote_item_instance = vote_item_scene.instance()
	grid.add_child(vote_item_instance)
	vote_item_instance.connect("item_removed", self, "_grid_children_changed")
	_grid_children_changed()

func _on_BtRenamePage_pressed() -> void:
	name_edit.text = get_name()
	name_popup.popup_centered()
	name_edit.grab_focus()

func _on_PageNameEdit_text_entered(_new_text:String) -> void:
	name_popup.visible = false
	set_name(name_edit.text)

func _on_BtDeletePage_pressed() -> void:
	queue_free()

func _grid_children_changed() -> void:
	grid_update_timer.start()

func _update_grid_columns() -> void:
	var columns:int = 1
	var item_count:int = grid.get_child_count()
	if item_count <= 3:
		columns = item_count
	else:
		columns = item_count / 2 + item_count % 2
	grid.columns = columns

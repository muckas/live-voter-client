extends Control
class_name VotePage

signal finished_presenting

export(PackedScene) var vote_item_scene:PackedScene

var presenting_item_index:int = 0

onready var vbox:VBoxContainer = $VBoxContainer
onready var name_label:Label = $VBoxContainer/NameLabel
onready var start_button:Button = $VBoxContainer/StartButton
onready var grid:GridContainer = $VBoxContainer/GridContainer
onready var presenting_vbox:Control = $VBoxContainer/PresentingVBox
onready var presentina_texture_rect:TextureRect = $VBoxContainer/PresentingVBox/TextureRect
onready var presenting_item_label:Label = $VBoxContainer/PresentingVBox/PresentingItemLabel

onready var fullscreen_popup:Popup = $FullscreenPopup
onready var fullscreen_label:Label = $FullscreenPopup/VBoxContainer/NameLabel
onready var fullscreen_texture:TextureRect = $FullscreenPopup/VBoxContainer/TextureRect

func _ready() -> void:
	connect("resized", self, "_on_self_resized")
	_on_self_resized()

func _present_item() -> void:
	if grid.get_child_count() > presenting_item_index:
		var vote_item:VoteItem = grid.get_child(presenting_item_index)
		presenting_item_label.text = vote_item.get_item_name()
		presentina_texture_rect.texture = vote_item.get_item_texture()
	else:
		finish_presenting()

func get_page_name() -> String:
	return name_label.text

func set_page_name(name:String) -> void:
	name_label.text = name

func get_vote_items() -> Dictionary:
	var vote_items:Dictionary = {}
	for index in range(grid.get_child_count()):
		vote_items[index] = {
				"item_name": grid.get_child(index).get_item_name(),
				"item_votes": 0
			}
	return vote_items

func add_vote_item(name:String, page_index:int, item_index:int) -> void:
	var vote_item_instance:VoteItem = vote_item_scene.instance()
	grid.add_child(vote_item_instance)
	vote_item_instance.connect("fullscreen_popup", self, "_on_fullscreen_popup")
	vote_item_instance.set_item_name(name)
	vote_item_instance.set_item_image(page_index, item_index)
	_update_grid_columns()

func display_votes(vote_items:Dictionary) -> void:
	for item_id in vote_items:
		grid.get_child(int(item_id)).set_votes(vote_items[item_id]["item_votes"])
	_update_grid_columns()

func display_all() -> void:
	for child in grid.get_children():
		child.visible = true
	_update_grid_columns()

func hide_all() -> void:
	for child in grid.get_children():
		child.visible = false
	_update_grid_columns()

func dislpay_winners(winner_ids:PoolIntArray) -> void:
	hide_all()
	for id in winner_ids:
		grid.get_child(id).visible = true
	_update_grid_columns()


func start_presenting() -> void:
	grid.visible = false
	presenting_vbox.visible = false

func _on_StartButton_pressed() -> void:
	name_label.size_flags_vertical = SIZE_FILL
	start_button.visible = false
	grid.visible = false
	presenting_vbox.visible = true
	presenting_item_index = 0
	_present_item()

func finish_presenting() -> void:
	presenting_vbox.visible = false
	grid.visible = true
	emit_signal("finished_presenting")


func _on_self_resized() -> void:
	vbox.rect_position = Vector2(16, 16)
	vbox.rect_size = rect_size - Vector2(32, 32)

func _on_BtPresentNext_pressed():
	presenting_item_index += 1
	_present_item()

func _on_fullscreen_popup(name:String, texture:Texture):
	fullscreen_label.text = name
	fullscreen_texture.texture = texture
	fullscreen_popup.rect_size = get_viewport_rect().size - Vector2(32, 32)
	fullscreen_popup.popup_centered()

func _update_grid_columns() -> void:
	var columns:int = 1
	var visible_item_count:int = 0
	for child in grid.get_children():
		if child.visible:
			visible_item_count += 1
	if visible_item_count <= 3:
		columns = visible_item_count
	else:
		columns = visible_item_count / 2 + visible_item_count % 2
	grid.columns = columns

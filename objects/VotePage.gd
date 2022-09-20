extends Control
class_name VotePage

signal finished_presenting

export(PackedScene) var vote_item_scene:PackedScene

var presenting_item_index:int = 0

onready var vbox:VBoxContainer = $VBoxContainer
onready var name_label:Label = $VBoxContainer/NameLabel
onready var grid:GridContainer = $VBoxContainer/GridContainer
onready var presenting_vbox:Control = $VBoxContainer/PresentingVBox
onready var presentina_texture_rect:TextureRect = $VBoxContainer/PresentingVBox/TextureRect
onready var presenting_item_label:Label = $VBoxContainer/PresentingVBox/PresentingItemLabel

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
	vote_item_instance.set_item_name(name)
	vote_item_instance.set_item_image(page_index, item_index)

func display_votes(vote_items:Dictionary) -> void:
	for item_id in vote_items:
		grid.get_child(int(item_id)).set_votes(vote_items[item_id]["item_votes"])

func display_all() -> void:
	for child in grid.get_children():
		child.visible = true

func hide_all() -> void:
	for child in grid.get_children():
		child.visible = false

func dislpay_winners(winner_ids:PoolIntArray) -> void:
	hide_all()
	for id in winner_ids:
		grid.get_child(id).visible = true


func start_presenting() -> void:
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

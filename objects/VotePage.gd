extends Control
class_name VotePage

signal finished_presenting

export(PackedScene) var vote_item_scene:PackedScene

var presenting_item_index:int = 0

onready var vbox:VBoxContainer = $VBoxContainer
onready var name_label:Label = $VBoxContainer/NameLabel
onready var voting_label:Label = $VBoxContainer/VotingLabel
onready var grid:GridContainer = $VBoxContainer/GridContainer
onready var presenting_popup:Popup = $PopupPresenting
onready var presentina_texture_rect:TextureRect = $PopupPresenting/VBoxContainer/TextureRect
onready var presenting_item_label:Label = $PopupPresenting/VBoxContainer/PopupItemLabel

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

func set_page_name(name:String) -> void:
	name_label.text = name

func add_vote_item(name:String, page_index:int, item_index:int) -> void:
	var vote_item_instance:VoteItem = vote_item_scene.instance()
	grid.add_child(vote_item_instance)
	vote_item_instance.set_item_name(name)
	vote_item_instance.set_item_image(page_index, item_index)

func start_presenting() -> void:
	presenting_popup.popup_centered(rect_size - Vector2(32, name_label.rect_size.y+32))
	presenting_popup.rect_position.y += name_label.rect_size.y / 2
	presenting_item_index = 0
	voting_label.visible = false
	_present_item()

func finish_presenting() -> void:
	presenting_popup.visible = false
	voting_label.visible = true
	grid.visible = true
	emit_signal("finished_presenting")


func _on_self_resized() -> void:
	vbox.rect_position = Vector2(16, 16)
	vbox.rect_size = rect_size - Vector2(32, 32)
	if presenting_popup.visible:
		presenting_popup.popup_centered(rect_size - Vector2(32, name_label.rect_size.y+32))
		presenting_popup.rect_position.y += name_label.rect_size.y / 2

func _on_BtPresentNext_pressed():
	presenting_item_index += 1
	_present_item()

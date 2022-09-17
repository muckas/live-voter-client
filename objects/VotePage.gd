extends Control
class_name VotePage

export(PackedScene) var vote_item_scene:PackedScene

onready var vbox:VBoxContainer = $VBoxContainer
onready var name_label:Label = $VBoxContainer/NameLabel
onready var grid:GridContainer = $VBoxContainer/GridContainer

func _ready() -> void:
	connect("resized", self, "_on_self_resized")
	_on_self_resized()


func set_page_name(name:String) -> void:
	name_label.text = name

func add_vote_item(name:String, page_index:int, item_index:int) -> void:
	var vote_item_instance:VoteItem = vote_item_scene.instance()
	grid.add_child(vote_item_instance)
	vote_item_instance.visible = false
	vote_item_instance.set_item_name(name)
	vote_item_instance.set_item_image(page_index, item_index)


func _on_self_resized() -> void:
	vbox.rect_position = Vector2(16, 16)
	vbox.rect_size = rect_size - Vector2(32, 32)

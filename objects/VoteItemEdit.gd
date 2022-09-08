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


func return_vote_item() -> Dictionary:
	var vote_item:Dictionary = Dictionary()
	vote_item["item_name"] = name_button.text
	return vote_item

func set_item_name(name:String):
	name_edit.text = name
	_on_NameEdit_text_entered(name)

func set_item_image(page_index:int, item_index:int) -> void:
	var endpoint:String = "/image/" + Global.active_vote_id + "/" + String(page_index) + "_" + String(item_index)
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_image_request_completed")
	http.request(Global.server_url + ":" + String(Global.server_port) + endpoint)

func upload_image(vote_id:String, page_index:int, item_index:int) -> bool:
	var img:Image = texture_rect.texture.get_data()
	var endpoint:String = "/upload-image/" + vote_id + "/" + String(page_index) + "_" + String(item_index)
	return Global.upload_image(img, endpoint)


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

func _on_image_request_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var image:Image = Image.new()
	var image_error:int = image.load_png_from_buffer(body)
	if image_error != OK:
		return
	var texture:ImageTexture = ImageTexture.new()
	texture.create_from_image(image)
	texture_rect.texture = texture

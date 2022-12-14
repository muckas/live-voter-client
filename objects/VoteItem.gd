extends Control
class_name VoteItem

signal fullscreen_popup

onready var vbox:VBoxContainer = $VBoxContainer
onready var texture_rect:TextureRect = $VBoxContainer/TextureRect
onready var name_label:Label = $VBoxContainer/HBoxContainer/NameLabel
onready var votes_label:Label = $VBoxContainer/HBoxContainer/VotesLabel

func _ready():
	connect("resized", self, "_on_self_resized")
	_on_self_resized()

func get_item_name() -> String:
	return name_label.text

func set_item_name(name:String):
	name_label.text = name

func get_item_texture() -> Texture:
	return texture_rect.texture

func set_item_image(page_index:int, item_index:int) -> void:
	var endpoint:String = Global.api_path + "image/" + Global.active_vote_id + "/" + String(page_index) + "_" + String(item_index)
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_image_request_completed")
	http.request(Global.server_url + ":" + String(Global.server_port) + endpoint)

func set_votes(num:int) -> void:
	votes_label.text = String(num)
	votes_label.visible = true


func _on_self_resized() -> void:
	vbox.rect_size = rect_size

func _on_FullscreenButton_pressed():
	emit_signal("fullscreen_popup", name_label.text, texture_rect.texture)

func _on_image_request_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var image:Image = Image.new()
	var image_error:int = image.load_png_from_buffer(body)
	if image_error != OK:
		return
	var texture:ImageTexture = ImageTexture.new()
	texture.create_from_image(image)
	texture_rect.texture = texture


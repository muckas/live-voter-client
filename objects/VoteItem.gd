extends Control
class_name VoteItem

onready var vbox:VBoxContainer = $VBoxContainer
onready var texture_rect:TextureRect = $VBoxContainer/TextureRect
onready var name_label:Label = $VBoxContainer/NameLabel

func _ready():
	connect("resized", self, "_on_self_resized")
	_on_self_resized()


func set_item_name(name:String):
	name_label.text = name

func set_item_image(page_index:int, item_index:int) -> void:
	var endpoint:String = "/image/" + Global.active_vote_id + "/" + String(page_index) + "_" + String(item_index)
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_image_request_completed")
	http.request(Global.server_url + ":" + String(Global.server_port) + endpoint)


func _on_self_resized() -> void:
	vbox.rect_size = rect_size

func _on_image_request_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var image:Image = Image.new()
	var image_error:int = image.load_png_from_buffer(body)
	if image_error != OK:
		return
	var texture:ImageTexture = ImageTexture.new()
	texture.create_from_image(image)
	texture_rect.texture = texture

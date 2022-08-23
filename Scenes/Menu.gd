extends Control

var server_base_url:String = "http://localhost"
var server_port:int = 8080

onready var check_label = $CheckLabel
onready var image_rect = $ImageRect


func _on_CheckButton_pressed() -> void:
	var endpoint:String = "/check"
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_check_completed")
	http.request(server_base_url + ":" + String(server_port) + endpoint)

func _on_check_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			check_label.text = response["message"]
	else:
		check_label.text = "Server not responding"

func _on_GetImageButton_pressed():
	var endpoint:String = "/image"
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_image_request_completed")
	http.request(server_base_url + ":" + String(server_port) + endpoint)

func _on_image_request_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var image:Image = Image.new()
	var image_error:int = image.load_png_from_buffer(body)
	if image_error != OK:
		print("Image download failed")
	var texture:ImageTexture = ImageTexture.new()
	texture.create_from_image(image)
	image_rect.texture = texture

func _on_SendImageButton_pressed():
	var file = File.new()
	file.open('res://icon.png', File.READ)
	var file_content = file.get_buffer(file.get_len())
	var body = PoolByteArray()
	body.append_array("\r\n--WebKitFormBoundaryePkpFF7tjBAqx29L\r\n".to_utf8())
	body.append_array("Content-Disposition: form-data; name=\"fileupload\"; filename=\"icon.png\"\r\n".to_utf8())
	body.append_array("Content-Type: image/png\r\n\r\n".to_utf8())
	body.append_array(file_content)
	body.append_array("\r\n--WebKitFormBoundaryePkpFF7tjBAqx29L--\r\n".to_utf8())
	var headers = [
		"Content-Type: multipart/form-data;boundary=\"WebKitFormBoundaryePkpFF7tjBAqx29L\""
	]
	var http = HTTPClient.new()
	http.connect_to_host(server_base_url, server_port, false)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		OS.delay_msec(500)
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED) # Could not connect
	var err = http.request_raw(HTTPClient.METHOD_POST, "/upload" , headers, body)
	assert(err == OK) # Make sure all is OK.
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			yield(Engine.get_main_loop(), "idle_frame")

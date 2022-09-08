extends Node

const VERSION = "0.3.0"

var server_url:String = "http://localhost"
var server_port:int = 8080
var server_ok:bool = false
var active_vote_id:String
var active_vote_data:Dictionary
var file_dialog_path:String


func upload_image(img:Image, endpoint:String) -> bool:
	var file_content:PoolByteArray = img.save_png_to_buffer()
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
	http.connect_to_host(server_url, server_port, false)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		OS.delay_msec(500)
	if http.get_status() != HTTPClient.STATUS_CONNECTED: # Could not connect
		return false
	var err = http.request_raw(HTTPClient.METHOD_POST, endpoint, headers, body)
	if err != OK: # Make sure all is OK.
		return false
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			yield(Engine.get_main_loop(), "idle_frame")
	return true

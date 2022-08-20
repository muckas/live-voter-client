extends Control

var server_base_url:String = "http://localhost:8080"

onready var check_label = $CheckLabel

func _on_CheckButton_pressed() -> void:
	var endpoint:String = "/check"
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_check_completed")
	http.request(server_base_url + endpoint)

func _on_check_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			check_label.text = response["message"]
	else:
		check_label.text = "Server not responding"

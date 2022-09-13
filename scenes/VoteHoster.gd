extends Control

onready var error_popup:Popup = $PopupError
onready var vote_name_label:Label = $VBoxVoteIntro/VoteNameLabel
onready var vote_code_label:Label = $VBoxVoteIntro/HBoxContainer/VoteCodeLabel
onready var client_count_label:Label = $VBoxVoteIntro/HBoxContainer/ClientCountLabel
onready var intro_container:Control = $VBoxVoteIntro


func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	vote_name_label.text = Global.active_vote_data["vote_name"]
	_request_vote_code()

func _error(error_text:String) -> void:
	error_popup.dialog_text = error_text
	error_popup.popup_centered()

func _on_viewport_size_changed() -> void:
	intro_container.rect_size = get_viewport_rect().size

func _request_vote_code() -> void:
	var query:String = JSON.print({"vote_name": Global.active_vote_data["vote_name"]})
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = "/host-vote"
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_host_vote_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_host_vote_request_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			Global.active_vote_code = response["message"]
			vote_code_label.text = "Vote code\n" + Global.active_vote_code.to_upper()
		else:
			_error(response["message"])
	else:
		_error("Server not responding")

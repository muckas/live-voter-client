extends Control

export(String) var _server_url = "http://localhost"
export(String) var _api_path = "/"
export(int) var _server_port = 8080

onready var error_popup:Popup = $PopupError
onready var hflow:HFlowContainer = $HFlowContainer
onready var version_label:Label = $HFlowContainer/VersionLabel
onready var server_label:Label = $HFlowContainer/ServerLabel
onready var server_addres_edit:LineEdit = $HFlowContainer/ServerAddress
onready var api_path_edit:LineEdit = $HFlowContainer/ApiPath
onready var server_port_edit:SpinBox = $HFlowContainer/PortContainer/ServerPort
onready var host_vote_popup:Popup = $PopupHostVote
onready var host_vote_edit:LineEdit = $PopupHostVote/VBoxContainer/HostVoteEdit
onready var join_vote_popup:Popup = $PopupJoinVote
onready var join_vote_edit:LineEdit = $PopupJoinVote/VBoxContainer/JoinVoteEdit

func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	version_label.text = "Client v" + Global.VERSION
	if Global.first_run:
		server_addres_edit.text = _server_url
		api_path_edit.text = _api_path
		server_port_edit.value = _server_port
		Global.first_run = false
	else:
		server_addres_edit.text = Global.server_url
		api_path_edit.text = Global.api_path
		server_port_edit.value = Global.server_port
	_on_server_connect()

func _on_viewport_size_changed() -> void:
	hflow.rect_position = (get_viewport_rect().size / 2) - (hflow.rect_size / 2)

func _on_server_connect() -> void:
	Global.server_url = server_addres_edit.text
	Global.api_path = api_path_edit.text
	Global.server_port = server_port_edit.value
	var endpoint:String = Global.api_path + "check"
	server_label.text = "Connecting..."
	var request_url = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_server_connect_complete")
	http.request(request_url)

func _on_server_connect_complete(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			server_label.text = "Server OK v" + response["message"]
			Global.server_ok = true
	else:
		server_label.text = "Server not responding"
		Global.server_ok = false

func _on_BtVoteEditor_pressed() -> void:
	if Global.server_ok:
		get_tree().change_scene("res://scenes/VoteEditor.tscn")
	else:
		error_popup.dialog_text = "Server not responding"
		error_popup.popup_centered()

func _on_BtHostVote_pressed() -> void:
	host_vote_edit.text = ""
	host_vote_popup.popup_centered()
	host_vote_edit.grab_focus()

func _on_HostVoteEdit_text_entered(_new_text:String) -> void:
	host_vote_popup.visible = false
	var vote_id:String = host_vote_edit.text
	Global.active_vote_id = vote_id
	var endpoint:String = Global.api_path + "vote-data/" + vote_id
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_host_vote_request_completed")
	http.request(request_url)

func _on_host_vote_request_completed(result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if result == HTTPRequest.RESULT_SUCCESS:
		if json.result:
			var vote_data:Dictionary = json.result
			Global.active_vote_data = vote_data
			get_tree().change_scene("res://scenes/VoteHoster.tscn")
		else:
			error_popup.dialog_text = "Vote not found"
			error_popup.popup_centered()
	else:
		error_popup.dialog_text = "Server not responding"
		error_popup.popup_centered()


func _on_BtJoinVote_pressed():
	join_vote_edit.text = ""
	join_vote_popup.popup_centered()
	join_vote_edit.grab_focus()

func _on_Key_pressed(key_char:String):
	join_vote_edit.text += key_char
	join_vote_edit.caret_position = len(join_vote_edit.text)

func _on_KeyClean_pressed():
	join_vote_edit.text = ""

func _on_JoinVoteEdit_text_changed(_new_text:String):
	join_vote_edit.text = join_vote_edit.text.to_upper()
	join_vote_edit.caret_position = len(join_vote_edit.text)

func _on_JoinVoteEdit_text_entered(_new_text:String) -> void:
	join_vote_popup.visible = false
	var vote_code:String = join_vote_edit.text.to_lower()
	Global.active_vote_code = vote_code
	var query:String = JSON.print({
		"id": Global.client_id,
		})
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = Global.api_path + "join-vote/" + vote_code
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_join_vote_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_join_vote_request_completed(result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if result == HTTPRequest.RESULT_SUCCESS:
		if json.result:
			var response:Dictionary = json.result
			if response["error"] == "OK":
				var vote_data:Dictionary = response["data"]
				Global.active_vote_data = vote_data
				get_tree().change_scene("res://scenes/VoteJoiner.tscn")
			else:
				error_popup.dialog_text = response["message"]
				error_popup.popup_centered()
		else:
			error_popup.dialog_text = "Server not responding"
			error_popup.popup_centered()
	else:
		error_popup.dialog_text = "Server not responding"
		error_popup.popup_centered()


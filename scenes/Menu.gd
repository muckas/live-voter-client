extends Control

export(String) var _server_url = "http://localhost"
export(int) var _server_port = 8080

onready var error_popup:Popup = $PopupError
onready var hflow:HFlowContainer = $HFlowContainer
onready var version_label:Label = $HFlowContainer/VersionLabel
onready var server_label:Label = $HFlowContainer/ServerLabel
onready var server_addres_edit:LineEdit = $HFlowContainer/ServerAddress
onready var server_port_edit:SpinBox = $HFlowContainer/PortContainer/ServerPort
onready var host_vote_popup:Popup = $PopupHostVote
onready var host_vote_edit:LineEdit = $PopupHostVote/VBoxContainer/HostVoteEdit

func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	version_label.text = "Client v" + Global.VERSION
	server_addres_edit.text = _server_url
	server_port_edit.value = _server_port
	_on_server_connect()

func _on_viewport_size_changed() -> void:
	hflow.rect_position = (get_viewport_rect().size / 2) - (hflow.rect_size / 2)

func _on_server_connect() -> void:
	var endpoint:String = "/check"
	Global.server_url = server_addres_edit.text
	Global.server_port = server_port_edit.value
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
	var endpoint:String = "/vote-data/" + vote_id
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

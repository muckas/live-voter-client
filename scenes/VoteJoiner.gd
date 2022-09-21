extends Control

var last_vote_state:String = ""
var selected_vote:int

onready var error_popup:Popup = $PopupError
onready var confirm_vote_popup:Popup = $ConfirmVotePopup
onready var main_container:Control = $VBoxContainer
onready var vote_name_label:Label = $VBoxContainer/VoteNameLabel
onready var page_name_label:Label = $VBoxContainer/PageNameLabel
onready var vote_status_label:Label = $VBoxContainer/VoteStatusLabel
onready var vote_items_box:VBoxContainer = $VBoxContainer/VoteItemsScroll/VoteItemsVBox


func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	_update_vote_info()


func _on_viewport_size_changed() -> void:
	main_container.rect_size= get_viewport_rect().size - Vector2(32, 32)
	main_container.rect_position = (get_viewport_rect().size / 2) - (main_container.rect_size / 2)

func _error(error_text:String) -> void:
	error_popup.dialog_text = error_text
	error_popup.popup_centered()


func _update_vote_info():
	vote_name_label.text = Global.active_vote_data["vote_name"]
	if Global.active_vote_data["page_name"]:
		page_name_label.text = Global.active_vote_data['page_name']
		page_name_label.visible = true
	else:
		page_name_label.visible = false
	var new_vote_state:String = Global.active_vote_data["state"]
	if new_vote_state != last_vote_state:
		match new_vote_state:
			"intro":
				vote_status_label.text = "Get ready for a vote"
			"presenting":
				_remove_vote_items()
				vote_status_label.text = "Look at the screen"
			"voting":
				vote_status_label.text = "Vote!"
				_create_vote_items()
			"outro":
				_remove_vote_items()
				vote_status_label.text = "Vote finished!"
		last_vote_state = new_vote_state


func _on_VoteRequestTimer_timeout():
	var query:String = JSON.print(
			{
				"id": Global.client_id,
			}
		)
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = "/get-active-vote/" + Global.active_vote_code
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_timed_vote_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_timed_vote_request_completed(
	_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray
	) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			Global.active_vote_data = response["data"]
			_update_vote_info()
		else:
			_error(response["message"])
	else:
		_error("Server not responding")

func _create_vote_items():
	var vote_items:Dictionary = Global.active_vote_data["vote_items"]
	var vote_item_button:Button
	for item_id in vote_items:
		vote_item_button = Button.new()
		vote_item_button.set_name(item_id)
		vote_item_button.text = vote_items[item_id]["item_name"]
		vote_item_button.size_flags_horizontal = SIZE_SHRINK_CENTER
		vote_item_button.connect("pressed", self, "_on_vote_item_selected", [int(item_id)])
		vote_items_box.add_child(vote_item_button)

func _remove_vote_items():
	for child in vote_items_box.get_children():
		child.queue_free()

func _on_vote_item_selected(item_id:int) -> void:
	selected_vote = item_id
	confirm_vote_popup.dialog_text = "Vote for " + vote_items_box.get_child(selected_vote).text + "?"
	confirm_vote_popup.popup_centered()

func _on_ConfirmVotePopup_confirmed() -> void:
	var query:String = JSON.print(
			{
				"id": Global.client_id,
				"item_id": selected_vote
			}
		)
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = "/send-vote/" + Global.active_vote_code
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_send_vote_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_send_vote_request_completed(
	_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray
	) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			_remove_vote_items()
			vote_status_label.text = "Vote sent!"
		else:
			_error(response["message"])
	else:
		_error("Server not responding")

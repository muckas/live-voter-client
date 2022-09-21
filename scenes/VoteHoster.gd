extends Control

export(PackedScene) var vote_page_scene:PackedScene

var current_page_index:int = 0
var vote_results:Dictionary = {}
var current_page_node:VotePage = null

onready var keep_alive_timer:Timer = $KeepAliveTimer
onready var error_popup:Popup = $PopupError
onready var exit_popup:Popup = $ExitPopup
onready var code_label:Label = $CodeLabel

onready var hoster_vbox:Control = $HosterVBox
onready var intro_container:Control = $HosterVBox/IntroContainer
onready var intro_info_container:Control = $HosterVBox/IntroContainer/IntroInfoContainer

onready var vote_page_container:Control = $HosterVBox/VotePages
onready var vote_name_label:Label = $HosterVBox/IntroContainer/VoteNameLabel
onready var vote_code_label:Label = $HosterVBox/IntroContainer/IntroInfoContainer/VoteCodeLabel
onready var client_count_label:Label = $HosterVBox/IntroContainer/IntroInfoContainer/ClientCountLabel

onready var voting_info_box:Control = $HosterVBox/VotingInfoVBox
onready var voting_info_label:Label = $HosterVBox/VotingInfoVBox/VotingInfoLabel
onready var voting_finish_button:Button = $HosterVBox/VotingInfoVBox/FinishVoteButton
onready var voting_retry_button:Button = $HosterVBox/VotingInfoVBox/RetryVoteButton
onready var voting_next_button:Button = $HosterVBox/VotingInfoVBox/NextPageButton

onready var results_tab_container:TabContainer = $HosterVBox/ResultsTabContainer


func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	vote_name_label.text = Global.active_vote_data["vote_name"]
	_request_vote_code()

func _error(error_text:String) -> void:
	error_popup.dialog_text = error_text
	error_popup.popup_centered()

func _on_viewport_size_changed() -> void:
	hoster_vbox.rect_position = Vector2(16, 16)
	hoster_vbox.rect_size = get_viewport_rect().size - Vector2(32, 32)

func _on_FullscreenButton_pressed():
	OS.window_fullscreen = !OS.window_fullscreen

func _on_ExitButton_pressed():
	exit_popup.popup_centered()

func _on_ExitPopup_confirmed():
	get_tree().change_scene("res://scenes/Menu.tscn")

func _load_vote_pages() -> void:
	var vote_pages:Dictionary = Global.active_vote_data["vote_pages"]
	for page_index in range(len(vote_pages)):
		var vote_page:Dictionary = vote_pages[String(page_index)]
		var vote_page_instance:VotePage = vote_page_scene.instance()
		vote_page_container.add_child(vote_page_instance)
		vote_page_instance.connect("finished_presenting", self, "_on_finished_presenting")
		vote_page_instance.set_page_name(vote_page["page_name"])
		for item_index in range(len(vote_page["page_items"])):
			vote_page_instance.visible = false
			vote_page_instance.add_vote_item(
				vote_page["page_items"][String(item_index)]["item_name"],
				page_index,
				item_index
				)

func _request_vote_code() -> void:
	var query:String = JSON.print({
		"host_id": Global.client_id,
		"vote_name": Global.active_vote_data["vote_name"]
		})
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
			code_label.text = Global.active_vote_code.to_upper()
			keep_alive_timer.start()
			_load_vote_pages()
		else:
			_error(response["message"])
	else:
		_error("Server not responding")


func _on_KeepAliveTimer_timeout() -> void:
	var endpoint:String = "/keep-active-vote/" + Global.active_vote_code
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_keep_vote_request_completed")
	http.request(request_url)

func _on_keep_vote_request_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] != "OK":
			_error(response["message"])
	else:
		_error("Server not responding")


func _on_StartVoteButton_pressed() -> void:
	current_page_index = 0
	intro_info_container.visible = false
	intro_container.size_flags_vertical = SIZE_FILL
	vote_page_container.visible = true
	_present_page()

func _present_page() -> void:
	if vote_page_container.get_child_count() > current_page_index:
		for child in vote_page_container.get_children():
			child.visible = false
		current_page_node = vote_page_container.get_child(current_page_index)
		_update_vote_presenting()
	else:
		_update_vote_outro()
		_display_results_screen()

func _update_vote_outro() -> void:
	var query:String = JSON.print(
			{
				"host_id": Global.client_id,
				"vote_data": {
					"state": "outro",
					"vote_name": Global.active_vote_data["vote_name"],
					"page_name": "",
					"vote_items": {}
				},
			}
		)
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = "/update-active-vote/" + Global.active_vote_code
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _update_vote_presenting() -> void:
	var query:String = JSON.print(
			{
				"host_id": Global.client_id,
				"vote_data": {
					"state": "presenting",
					"vote_name": Global.active_vote_data["vote_name"],
					"page_name": current_page_node.get_page_name(),
					"vote_items": {}
				},
			}
		)
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = "/update-active-vote/" + Global.active_vote_code
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_update_vote_presenting_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_update_vote_presenting_request_completed(
	_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray
	) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			current_page_node.visible = true
			voting_info_box.visible = false
			current_page_node.start_presenting()
		else:
			_error(response["message"])
	else:
		_error("Server not responding")


func _on_finished_presenting() -> void:
	_update_vote_voting()

func _update_vote_voting() -> void:
	var query:String = JSON.print(
			{
				"host_id": Global.client_id,
				"vote_data": {
					"state": "voting",
					"vote_name": Global.active_vote_data["vote_name"],
					"page_name": current_page_node.get_page_name(),
					"vote_items": current_page_node.get_vote_items()
				},
			}
		)
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = "/update-active-vote/" + Global.active_vote_code
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_update_vote_voting_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_update_vote_voting_request_completed(
	_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray
	) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			voting_info_label.text = "Voting... 0/0"
			voting_finish_button.visible = true
			voting_retry_button.visible = false
			voting_next_button.visible = false
		else:
			voting_info_label.text = "Error starting vote"
			voting_finish_button.visible = false
			voting_retry_button.visible = true
			voting_next_button.visible = false
			_error(response["message"])
	else:
		voting_info_label.text = "Error starting vote"
		voting_finish_button.visible = false
		voting_retry_button.visible = true
		voting_next_button.visible = false
		_error("Server not responding")
	voting_info_box.visible = true


func _on_FinishVoteButton_pressed() -> void:
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
	http.connect("request_completed", self, "_on_finish_vote_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_finish_vote_request_completed(
	_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray
	) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			_display_page_winners(response["data"])
		else:
			_error(response["message"])
	else:
		_error("Server not responding")

func _sort_by_votes(a, b) -> bool:
	if int(a[1]["item_votes"]) > int(b[1]["item_votes"]):
		return true
	return false

func _get_winner_ids(sorted_vote_items:Array) -> PoolIntArray:
	var winner_ids:PoolIntArray = []
	for index in range(len(sorted_vote_items)):
		if index == 0:
			winner_ids.append(sorted_vote_items[index][0])
		else:
			if sorted_vote_items[index][1]["item_votes"] == sorted_vote_items[index-1][1]["item_votes"]:
				winner_ids.append(sorted_vote_items[index][0])
			else:
				break
	return winner_ids

func _display_page_winners(active_vote_data:Dictionary) -> void:
	var vote_items:Dictionary = active_vote_data["vote_items"]
	current_page_node.display_votes(vote_items)
	var vote_items_array:Array = []
	for vote_item_id in vote_items:
		vote_items_array.append([vote_item_id, vote_items[vote_item_id]])
	vote_items_array.sort_custom(self, "_sort_by_votes")
	var winner_ids:PoolIntArray = _get_winner_ids(vote_items_array)
	current_page_node.dislpay_winners(winner_ids)
	if len(winner_ids) > 1:
		voting_info_label.text = "It's a tie!"
	else:
		voting_info_label.text = "We have a winner!"
	voting_finish_button.visible = false
	voting_retry_button.visible = false
	voting_next_button.visible = true


func _on_NextPageButton_pressed() -> void:
	current_page_index += 1
	if vote_page_container.get_child_count() == current_page_index+1:
		voting_next_button.text = "View results"
	_present_page()


func _display_results_screen() -> void:
	var index:int = 1
	for page_node in vote_page_container.get_children():
		page_node.display_all()
		page_node.set_name("Page " + String(index))
		vote_page_container.remove_child(page_node)
		results_tab_container.add_child(page_node)
		index += 1
	vote_page_container.visible = false
	voting_info_box.visible = false
	results_tab_container.visible = true



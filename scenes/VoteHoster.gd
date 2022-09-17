extends Control

export(PackedScene) var vote_page_scene:PackedScene

var vote_state:String = "intro"
var current_page_index:int = 0
var vote_results:Dictionary = {}
var current_page_node:VotePage = null

onready var keep_alive_timer:Timer = $KeepAliveTimer
onready var error_popup:Popup = $PopupError
onready var vote_name_label:Label = $VoteIntro/VoteNameLabel
onready var vote_code_label:Label = $VoteIntro/HBoxContainer/VoteCodeLabel
onready var client_count_label:Label = $VoteIntro/HBoxContainer/ClientCountLabel
onready var intro_container:Control = $VoteIntro
onready var vote_page_container:Control = $VotePages


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
	vote_page_container.rect_size = get_viewport_rect().size
	for child in vote_page_container.get_children():
		child.rect_size = vote_page_container.rect_size

func _load_vote_pages() -> void:
	var vote_pages:Dictionary = Global.active_vote_data["vote_pages"]
	for page_index in range(len(vote_pages)):
		var vote_page:Dictionary = vote_pages[String(page_index)]
		var vote_page_instance:VotePage = vote_page_scene.instance()
		vote_page_container.add_child(vote_page_instance)
		vote_page_instance.set_page_name(vote_page["page_name"])
		for item_index in range(len(vote_page["page_items"])):
			vote_page_instance.visible = false
			vote_page_instance.add_vote_item(
				vote_page["page_items"][String(item_index)]["item_name"],
				page_index,
				item_index
				)

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
	intro_container.visible = false
	vote_page_container.visible = true
	_present_page()

func _present_page() -> void:
	if vote_page_container.get_child_count() > current_page_index:
		for child in vote_page_container.get_children():
			child.visible = false
		current_page_node = vote_page_container.get_child(current_page_index)
		current_page_node.visible = true
		current_page_node.start_presenting()

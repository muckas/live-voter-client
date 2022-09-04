extends Control

export(PackedScene) var vote_page_scene:PackedScene

onready var error_popup:Popup = $PopupError
onready var vbox:VBoxContainer = $VBoxContainer
onready var exit_popup:Popup = $PopupExit
onready var tab_container:TabContainer = $VBoxContainer/TabContainer
onready var new_page_popup:Popup = $PopupNewPage
onready var new_page_name:LineEdit = $PopupNewPage/VBoxContainer/PageNameEdit
onready var vote_name_button:Button = $VBoxContainer/HBoxEdit/BtVoteName
onready var vote_name_edit:LineEdit = $VBoxContainer/HBoxEdit/VoteNameEdit
onready var new_vote_popup:Popup = $PopupNewVote
onready var new_vote_id:LineEdit = $PopupNewVote/VBoxContainer/NewVoteId

func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()


func _on_viewport_size_changed() -> void:
	vbox.rect_position = Vector2(16, 16)
	vbox.rect_size = get_viewport_rect().size - Vector2(32, 32)

func _on_BtExit_pressed():
	exit_popup.popup_centered()

func _on_PopupExit_confirmed():
	get_tree().change_scene("res://scenes/Menu.tscn")

func _on_BtNewPage_pressed() -> void:
	new_page_name.text = ""
	new_page_popup.popup_centered()
	new_page_name.grab_focus()

func _on_PageNameEdit_text_entered(_new_text:String) -> void:
	new_page_popup.visible = false
	var vote_page_instance = vote_page_scene.instance()
	vote_page_instance.set_name(new_page_name.text)
	tab_container.add_child(vote_page_instance)

func _on_BtVoteName_pressed() -> void:
	vote_name_button.visible = false
	vote_name_edit.visible = true
	vote_name_edit.grab_focus()

func _on_VoteNameEdit_text_entered(_new_text:String) -> void:
	vote_name_button.text = vote_name_edit.text
	vote_name_button.visible = true
	vote_name_edit.visible = false

func _on_BtSaveVote_pressed() -> void:
	var vote_data:Dictionary = Dictionary()
	vote_data["vote_name"] = vote_name_button.text
	vote_data["vote_pages"] = Dictionary()
	for index in range(tab_container.get_child_count()):
		vote_data["vote_pages"][index] = tab_container.get_child(index).return_vote_page()
	var query:String = JSON.print(vote_data)
	var headers:PoolStringArray = ["Content-Type: application/json"]
	var endpoint:String = "/new-vote"
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_new_vote_request_completed")
	http.request(request_url, headers, true, HTTPClient.METHOD_POST, query)

func _on_new_vote_request_completed(_result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if json.result:
		var response:Dictionary = json.result
		if response["error"] == "OK":
			new_vote_id.text = response["message"]
			new_vote_popup.popup_centered()
		else:
			error_popup.popup_centered()
	else:
		error_popup.popup_centered()

extends Control

export(PackedScene) var vote_page_scene:PackedScene

onready var info_popup:Popup = $PopupInfo
onready var info_label:Label = $PopupInfo/InfoLabel
onready var error_popup:Popup = $PopupError
onready var vbox:VBoxContainer = $VBoxContainer
onready var exit_popup:Popup = $PopupExit
onready var tab_container:TabContainer = $VBoxContainer/TabContainer
onready var new_page_popup:Popup = $PopupNewPage
onready var new_page_name:LineEdit = $PopupNewPage/VBoxContainer/PageNameEdit
onready var vote_name_button:Button = $VBoxContainer/HBoxEdit/BtVoteName
onready var vote_name_edit:LineEdit = $VBoxContainer/HBoxEdit/VoteNameEdit
onready var new_vote_popup:Popup = $PopupNewVote
onready var save_confirm_popup:Popup = $PopupSave
onready var new_vote_id:LineEdit = $PopupNewVote/VBoxContainer/NewVoteId
onready var load_vote_confirm_popup:Popup = $PopupLoad
onready var load_vote_popup:Popup = $PopupLoadVote
onready var load_vote_id_edit:LineEdit = $PopupLoadVote/HBoxContainer/LoadVoteIdEdit

func _ready() -> void:
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()


func _error(error_text:String) -> void:
	error_popup.dialog_text = error_text
	error_popup.popup_centered()

func _return_vote_data() -> Dictionary:
	var vote_data:Dictionary = Dictionary()
	vote_data["vote_name"] = vote_name_button.text
	vote_data["vote_pages"] = Dictionary()
	for index in range(tab_container.get_child_count()):
		vote_data["vote_pages"][index] = tab_container.get_child(index).return_vote_page()
	return vote_data

func _upload_vote_images(vote_id:String) -> bool:
	for page_index in range(tab_container.get_child_count()):
		if tab_container.get_child(page_index).upload_images(vote_id, page_index) == false:
			return false
	return true

func _create_vote_from_data(vote_data:Dictionary) -> void:
	vote_name_edit.text = vote_data["vote_name"]
	vote_name_button.text = vote_data["vote_name"]
	var vote_pages:Dictionary = vote_data["vote_pages"]
	for page_index in range(len(vote_pages)):
		var vote_page:Dictionary = vote_pages[String(page_index)]
		var vote_page_instance:VotePageEdit = vote_page_scene.instance()
		tab_container.add_child(vote_page_instance)
		vote_page_instance.set_page_name(vote_page["page_name"])
		vote_page_instance.set_page_columns(vote_page["page_columns"])
		for item_index in range(len(vote_page["page_items"])):
			vote_page_instance.add_vote_item(
				vote_page["page_items"][String(item_index)]["item_name"],
				page_index,
				item_index
				)

func _clean_vote_editor() -> void:
	vote_name_edit.text = ""
	vote_name_button.text = "Vote Name"
	for child in tab_container.get_children():
		child.queue_free()


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
	save_confirm_popup.popup_centered()

func _on_PopupSave_confirmed() -> void:
	info_label.text = "Uploading vote data"
	info_popup.popup_centered()
	var query:String = JSON.print(_return_vote_data())
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
			var vote_id:String = response["message"]
			new_vote_id.text = vote_id
			if _upload_vote_images(vote_id) == false:
				info_popup.visible = false
				_error("Image upload failed")
				return
			info_popup.visible = false
			new_vote_popup.popup_centered()
		else:
			info_popup.visible = false
			_error(response["message"])
	else:
		info_popup.visible = false
		_error("Server not responding")


func _on_BtLoadVote_pressed() -> void:
	load_vote_confirm_popup.popup_centered()

func _on_PopupLoad_confirmed():
	_clean_vote_editor()
	load_vote_id_edit.text = ""
	load_vote_popup.popup_centered()

func _on_LoadVoteIdEdit_text_entered(_new_text:String) -> void:
	load_vote_popup.visible = false
	var vote_id:String = load_vote_id_edit.text
	Global.active_vote_id = vote_id
	var endpoint:String = "/vote-data/" + vote_id
	var request_url:String = Global.server_url + ":" + String(Global.server_port) + endpoint
	var http:HTTPRequest = HTTPRequest.new()
	self.add_child(http)
	http.connect("request_completed", self, "_on_vote_data_request_completed")
	http.request(request_url)

func _on_vote_data_request_completed(result:int, _response_code:int, _headers:PoolStringArray, body:PoolByteArray) -> void:
	var json:JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if result == HTTPRequest.RESULT_SUCCESS:
		if json.result:
			var vote_data:Dictionary = json.result
			_create_vote_from_data(vote_data)
		else:
			_error("Vote not found")
	else:
		_error("Server not responding")

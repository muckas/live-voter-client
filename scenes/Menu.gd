extends Control

export(String) var _server_url = "http://localhost"
export(int) var _server_port = 8080

onready var hflow:HFlowContainer = $HFlowContainer
onready var version_label:Label = $HFlowContainer/VersionLabel
onready var server_label:Label = $HFlowContainer/ServerLabel
onready var server_addres_edit:LineEdit = $HFlowContainer/ServerAddress
onready var server_port_edit:SpinBox = $HFlowContainer/PortContainer/ServerPort

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
		server_label.text = "Server Error"
		Global.server_ok = false

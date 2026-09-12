extends Node



signal player_added(id: int)
signal player_removed(id: int)

const DEFAULT_PORT: = 9999

const NET_VERSION: = "1.1.1"

const DEFAULT_SPAWN: = Vector2(-11602, 34497)
const PLAYER_SPAWN_OFFSET: = Vector2(300, 0)

var player_scene: PackedScene = preload("res://player.tscn")
var berry_drop_scene: PackedScene = preload("res://berry_drop.tscn")


var _next_berry_id: int = 1

var _bush_berries: Dictionary = {}

var _live_berry_pos: Dictionary = {}

var is_host: = false
var players: Dictionary = {}
var player_names: Dictionary = {}
var my_name: String = ""
var _signals_registered: = false
var _auto_chat_pending: = ""
var _auto_die: = false
var _auto_harvest: = false
var _auto_selftest: = false
var _auto_hostdrop: = false
var _auto_restart_test: = false
var _override_version: = ""
var _join_announced: Dictionary = {}
var _rejected_peers: Dictionary = {}


var ui_layer: CanvasLayer
var panel: PanelContainer
var ip_edit: LineEdit
var port_edit: LineEdit
var name_edit: LineEdit
var status_label: Label
var title_label: Label


var chat_panel: PanelContainer
var chat_history: RichTextLabel
var chat_input: LineEdit
var chat_toggle_btn: Button


func _ready() -> void :
	print("[Network] _ready()，multiplayer_peer=", multiplayer.multiplayer_peer)

	my_name = "玩家%d" % (randi() % 900 + 100)
	_build_ui()
	_build_chat_ui()






	var auto_chat: = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--net-name="):
			my_name = a.trim_prefix("--net-name=")
			if name_edit:
				name_edit.text = my_name
		elif a.begins_with("--net-chat="):
			auto_chat = a.trim_prefix("--net-chat=")
		elif a == "--net-die":
			_auto_die = true
		elif a == "--net-harvest":
			_auto_harvest = true
		elif a == "--net-selftest":
			_auto_selftest = true
		elif a == "--net-hostdrop":
			_auto_hostdrop = true
		elif a == "--net-restart":
			_auto_restart_test = true
		elif a.begins_with("--net-version="):
			_override_version = a.trim_prefix("--net-version=")

	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		print("[Network] 命令行参数: [", a, "]")
		if a.begins_with("--net-host="):
			var port: = int(a.trim_prefix("--net-host="))
			print("[Network] 命令行自动建房 ", port)
			host(port)
			if not auto_chat.is_empty():
				send_chat_message(auto_chat)
		elif a.begins_with("--net-join="):
			var parts: = a.trim_prefix("--net-join=").split(":")
			var addr: = parts[0]
			var port: = int(parts[1]) if parts.size() > 1 else DEFAULT_PORT
			print("[Network] 命令行自动加入 ", addr, ":", port)
			join(addr, port)
			if not auto_chat.is_empty():

				_auto_chat_pending = auto_chat






func host(port: int = DEFAULT_PORT) -> void :
	print("[Network] host() 被调用，端口=", port)

	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		print("[Network] host() 已存在网络 peer=", multiplayer.multiplayer_peer.get_class(), " is_server=", multiplayer.is_server())
		return
	var peer: = ENetMultiplayerPeer.new()
	var err: = peer.create_server(port)
	print("[Network] create_server err=", err)
	if err != OK:
		status_label.text = "创建房间失败（错误码 %d）" % err
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	_register_signals()
	_hide_panel()
	status_label.text = "已创建房间，端口 %d，等待玩家加入…" % port

	_spawn_player(multiplayer.get_unique_id())
	_report_my_name()

	if _auto_harvest or _auto_selftest or _auto_hostdrop:
		_schedule_selftest()
	if _auto_restart_test:
		await get_tree().create_timer(5.0).timeout
		if is_instance_valid(self):
			print("[Network] selftest: 延迟执行 /restart（模拟房主指令）")
			_restart_level()


func join(address: String, port: int = DEFAULT_PORT) -> void :
	print("[Network] join() 被调用，IP=", address, " 端口=", port)
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		print("[Network] join() 已存在网络 peer，直接返回")
		return
	var peer: = ENetMultiplayerPeer.new()
	var err: = peer.create_client(address, port)
	print("[Network] create_client err=", err)
	if err != OK:
		status_label.text = "连接失败（错误码 %d）" % err
		return
	multiplayer.multiplayer_peer = peer
	is_host = false
	_register_signals()
	status_label.text = "正在连接 %s:%d …" % [address, port]


func get_spawn_point(id: int) -> Vector2:

	var idx: = clampi(id - 1, 0, 7)
	var scene: = get_tree().current_scene
	if scene:
		var marker: = scene.get_node_or_null("SpawnPoint")
		if marker:
			return (marker as Node2D).global_position + PLAYER_SPAWN_OFFSET * float(idx)
	return DEFAULT_SPAWN + PLAYER_SPAWN_OFFSET * float(idx)






func _register_signals() -> void :
	if _signals_registered:
		return
	_signals_registered = true
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_connected_to_server() -> void :
	_hide_panel()
	status_label.text = "已连接到房间"

	_report_version()
	_report_my_name()

	_request_world_state.rpc_id(1)

	if not _auto_chat_pending.is_empty():
		send_chat_message(_auto_chat_pending)
		_auto_chat_pending = ""

	if _auto_die:
		await get_tree().create_timer(1.5).timeout
		var my_id: = multiplayer.get_unique_id()
		var p: Node = players.get(my_id)
		if p and is_instance_valid(p) and p.has_method("_die"):
			p._die()

	if _auto_harvest or _auto_selftest or _auto_hostdrop:
		_schedule_selftest()


func _on_connection_failed() -> void :
	status_label.text = "连接失败，请检查 IP 与端口"
	multiplayer.multiplayer_peer = null

	if chat_history:
		chat_history.append_text("[color=#ffd400]连接失败，请检查 IP 与端口[/color]\n")


func _on_server_disconnected() -> void :
	print("[Network] 与服务器断开连接")

	for pid in players.keys():
		var p: Node = players[pid]
		if p and is_instance_valid(p):
			p.queue_free()
	players.clear()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	if chat_history:
		chat_history.append_text("[color=#ffd400]与服务器的连接已断开[/color]\n")


func _on_peer_connected(id: int) -> void :
	print("[Network] 新对等端连接：", id, "（is_host=", is_host, "）")
	if not is_host:
		return

	_spawn_player.rpc(id)

	for pid in players.keys():
		if pid != id:
			_spawn_player.rpc_id(id, pid)

	for pid in player_names.keys():
		if pid != id:
			_set_name.rpc_id(id, pid, player_names[pid])


func _on_peer_disconnected(id: int) -> void :
	print("[Network] 对等端断开：", id)
	if is_host:

		if _rejected_peers.has(id):
			_rejected_peers.erase(id)
			_remove_player.rpc(id)
			return

		var name: String = player_names.get(id, "玩家%d" % id)
		_system_message.rpc("%s 退出了游戏" % name)
	_remove_player.rpc(id)






@rpc("any_peer", "call_local", "reliable")
func _spawn_player(id: int) -> void :
	if players.has(id):
		return
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var p: CharacterBody2D = player_scene.instantiate()
	p.name = "Player_%d" % id
	p.set_multiplayer_authority(id)
	p.global_position = get_spawn_point(id)
	scene.add_child(p)
	players[id] = p
	print("[Network] 已生成玩家 Player_", id, " @ ", p.global_position, " 权威端=", id, " 当前端=", multiplayer.get_unique_id())
	player_added.emit(id)

	if player_names.has(id):
		_apply_name_to_player(p, player_names[id])

	if id == multiplayer.get_unique_id():
		var cam: = scene.find_child("Camera2D", true, false)
		if cam and cam.has_method("set_follow_player"):
			cam.set_follow_player(p)



func _apply_name_to_player(p: Node, display_name: String) -> void :
	var node: = p.get_node_or_null("NameLabel")
	if node:
		node.set("text", display_name)
	elif p:
		var lbl: = Label.new()
		lbl.name = "NameLabel"
		lbl.position = Vector2(-200, -140)
		lbl.size = Vector2(400, 60)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		lbl.add_theme_constant_override("outline_size", 8)
		lbl.text = display_name
		p.add_child(lbl)



func _report_my_name() -> void :
	_set_name.rpc(multiplayer.get_unique_id(), my_name)


@rpc("any_peer", "call_local", "reliable")
func _set_name(id: int, display_name: String) -> void :
	if display_name.strip_edges().is_empty():
		return

	if is_host and _rejected_peers.has(id):
		return
	print("[Network] 设置名字 id=", id, " name=", display_name)
	var is_new: = not player_names.has(id)
	player_names[id] = display_name
	if id == multiplayer.get_unique_id():
		my_name = display_name

	var p: Node = players.get(id)
	if p:
		_apply_name_to_player(p, display_name)

	if is_host and is_new and not _join_announced.has(id):
		_join_announced[id] = true
		_system_message.rpc("%s 进入了游戏" % display_name)


@rpc("any_peer", "call_local", "reliable")
func _remove_player(id: int) -> void :
	var p: Node = players.get(id)
	if p and is_instance_valid(p):
		p.queue_free()
	players.erase(id)
	player_removed.emit(id)







func _report_version() -> void :
	var v: String = _override_version if not _override_version.is_empty() else NET_VERSION
	_check_version.rpc(multiplayer.get_unique_id(), v)



@rpc("any_peer", "call_local", "reliable")
func _check_version(id: int, version: String) -> void :
	if not is_host:
		return
	if version == NET_VERSION:
		return
	print("[Network] 版本不符，拒绝加入：id=", id, " 客户端版本=", version, " 服务器版本=", NET_VERSION)
	_rejected_peers[id] = true

	_version_rejected.rpc_id(id, NET_VERSION)
	_reject_and_disconnect(id)


func _reject_and_disconnect(id: int) -> void :
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self):
		return

	if not _rejected_peers.has(id):
		return
	var peer: = multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		var enet_peer: = peer as ENetMultiplayerPeer
		if enet_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			enet_peer.disconnect_peer(id)



@rpc("authority", "call_remote", "reliable")
func _version_rejected(server_version: String) -> void :
	var my_ver: String = _override_version if not _override_version.is_empty() else NET_VERSION
	print("[Network] 服务器拒绝：版本不匹配（本机 ", my_ver, "，服务器 ", server_version, "）")
	status_label.text = "版本不匹配，无法进入房间"
	if chat_history:
		chat_history.append_text("[color=#ff5555]版本不匹配：本机 %s，服务器 %s[/color]\n" % [my_ver, server_version])

	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	for pid in players.keys():
		var p: Node = players[pid]
		if p and is_instance_valid(p):
			p.queue_free()
	players.clear()

	panel.visible = true
	chat_panel.visible = false
	chat_toggle_btn.visible = false






func notify_player_died() -> void :
	var my_id: = multiplayer.get_unique_id()
	var peer: = multiplayer.multiplayer_peer
	if peer is OfflineMultiplayerPeer:

		_player_died(my_id)
	else:
		_player_died.rpc(my_id)


@rpc("any_peer", "call_local", "reliable")
func _player_died(id: int) -> void :
	var name: String = player_names.get(id, "玩家%d" % id)
	print("[Network] 死亡提示: ", name)
	if chat_history:
		chat_history.append_text("[color=#ff5555]%s 死亡了[/color]\n" % name)






func send_chat_message(text: String) -> void :
	var clean: = text.strip_edges()
	if clean.is_empty():
		return
	_chat_message.rpc(clean)



@rpc("any_peer", "call_local", "reliable")
func _system_message(text: String) -> void :
	print("[Network] 系统提示: ", text)
	if chat_history:
		chat_history.append_text("[color=#ffd400]%s[/color]\n" % text)


@rpc("any_peer", "call_local", "reliable")
func _chat_message(text: String) -> void :

	var sid: = multiplayer.get_remote_sender_id()
	if sid == 0:
		sid = multiplayer.get_unique_id()
	var sender_name: String = player_names.get(sid, "玩家%d" % sid)
	var clean: = text.strip_edges()

	if clean.to_lower() == "/restart":
		if is_host and sid == multiplayer.get_unique_id():
			print("[Network] 房主触发 /restart，重置场景")
			_restart_level()
		elif is_host:
			_system_message.rpc("只有房主可以使用 /restart")
		return
	print("[Network] 聊天 ", sender_name, ": ", text)
	if chat_history:
		chat_history.append_text("[b]%s[/b]：%s\n" % [sender_name, text])






func _restart_level() -> void :

	var ids: Array[int] = [multiplayer.get_unique_id()]
	for pid in multiplayer.get_peers():
		if not ids.has(pid):
			ids.append(pid)

	_bush_berries.clear()
	_live_berry_pos.clear()
	_system_message.rpc("房主重置了场景")

	_restart_scene_all.rpc()

	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self):
		return
	for pid in ids:
		_spawn_player.rpc(pid)
		if player_names.has(pid):
			_set_name.rpc(pid, player_names[pid])


@rpc("authority", "call_local", "reliable")
func _restart_scene_all() -> void :
	print("[Network] 重置场景：reload_current_scene")

	players.clear()
	get_tree().reload_current_scene()






func _build_ui() -> void :
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)

	panel.offset_left = 40
	panel.offset_top = -40
	panel.offset_right = 40
	panel.offset_bottom = -40
	panel.custom_minimum_size = Vector2(360, 0)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	title_label = Label.new()
	title_label.text = "狐处有微光 · 联机"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	box.add_child(title_label)


	var ver_label: = Label.new()
	ver_label.text = "v" + NET_VERSION
	ver_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver_label.add_theme_font_size_override("font_size", 14)
	ver_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	box.add_child(ver_label)

	var ip_row: = HBoxContainer.new()
	box.add_child(ip_row)
	var ip_label: = Label.new()
	ip_label.text = "IP 地址"
	ip_label.custom_minimum_size = Vector2(70, 0)
	ip_row.add_child(ip_label)
	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "127.0.0.1"
	ip_edit.text = "127.0.0.1"
	ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_row.add_child(ip_edit)

	var port_row: = HBoxContainer.new()
	box.add_child(port_row)
	var port_label: = Label.new()
	port_label.text = "端口"
	port_label.custom_minimum_size = Vector2(70, 0)
	port_row.add_child(port_label)
	port_edit = LineEdit.new()
	port_edit.placeholder_text = "9999"
	port_edit.text = str(DEFAULT_PORT)
	port_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	port_row.add_child(port_edit)

	var name_row: = HBoxContainer.new()
	box.add_child(name_row)
	var name_label: = Label.new()
	name_label.text = "名字"
	name_label.custom_minimum_size = Vector2(70, 0)
	name_row.add_child(name_label)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "输入你的名字"
	name_edit.text = my_name
	name_edit.max_length = 16
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect( func(new_text: String) -> void :
		my_name = new_text.strip_edges()
		if my_name.is_empty():
			my_name = "玩家%d" % (randi() % 900 + 100)
	)
	name_row.add_child(name_edit)

	var host_btn: = Button.new()
	host_btn.text = "创建房间（主机）"
	host_btn.pressed.connect( func() -> void :
		print("[Network] 创建房间按钮被点击，端口=", port_edit.text)
		host(int(port_edit.text))
	)
	box.add_child(host_btn)

	var join_btn: = Button.new()
	join_btn.text = "加入房间"
	join_btn.pressed.connect( func() -> void :
		print("[Network] 加入房间按钮被点击，IP=", ip_edit.text, " 端口=", port_edit.text)
		join(ip_edit.text, int(port_edit.text))
	)
	box.add_child(join_btn)

	status_label = Label.new()
	status_label.text = "请选择创建房间或加入房间"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)


	ui_layer.add_child(panel)
	panel.reset_size()


func _build_chat_ui() -> void :
	chat_panel = PanelContainer.new()
	chat_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)

	chat_panel.offset_left = -400
	chat_panel.offset_top = -240
	chat_panel.offset_right = -16
	chat_panel.offset_bottom = -16
	chat_panel.visible = false

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	chat_panel.add_child(margin)

	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)


	var header_row: = HBoxContainer.new()
	box.add_child(header_row)
	var header_label: = Label.new()
	header_label.text = "聊天"
	header_label.add_theme_font_size_override("font_size", 18)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)
	var fold_btn: = Button.new()
	fold_btn.text = "— 折叠"
	fold_btn.pressed.connect( func() -> void :
		chat_panel.visible = false
		chat_toggle_btn.visible = true
	)
	header_row.add_child(fold_btn)

	chat_history = RichTextLabel.new()
	chat_history.bbcode_enabled = true
	chat_history.scroll_following = true
	chat_history.custom_minimum_size = Vector2(0, 150)
	chat_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_history.add_theme_font_size_override("normal_font_size", 18)
	chat_history.add_theme_color_override("default_color", Color(1, 1, 1))
	box.add_child(chat_history)

	var input_row: = HBoxContainer.new()
	box.add_child(input_row)
	chat_input = LineEdit.new()
	chat_input.placeholder_text = "按 Enter 发送消息…"
	chat_input.max_length = 80
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect( func(_t: String) -> void :
		send_chat_message(chat_input.text)
		chat_input.clear()
	)
	input_row.add_child(chat_input)

	var send_btn: = Button.new()
	send_btn.text = "发送"
	send_btn.pressed.connect( func() -> void :
		send_chat_message(chat_input.text)
		chat_input.clear()
	)
	input_row.add_child(send_btn)

	ui_layer.add_child(chat_panel)


	chat_toggle_btn = Button.new()
	chat_toggle_btn.text = "聊天"
	chat_toggle_btn.visible = false
	chat_toggle_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	chat_toggle_btn.offset_left = -110
	chat_toggle_btn.offset_top = -54
	chat_toggle_btn.offset_right = -16
	chat_toggle_btn.offset_bottom = -16
	chat_toggle_btn.pressed.connect( func() -> void :
		chat_toggle_btn.visible = false
		chat_panel.visible = true
	)
	ui_layer.add_child(chat_toggle_btn)


func _hide_panel() -> void :
	panel.visible = false

	chat_panel.visible = true
	chat_toggle_btn.visible = false






func _schedule_selftest() -> void :
	if _auto_harvest:
		await get_tree().create_timer(2.0).timeout
		if not is_instance_valid(self):
			return
		print("[Network] selftest: 请求采集浆果丛 bush_id=1")
		request_harvest(1)
	if _auto_hostdrop:
		await get_tree().create_timer(2.5).timeout
		if not is_instance_valid(self):
			return
		var my_id: = multiplayer.get_unique_id()
		var pos: = Vector2(0, 0)
		var p: Node = players.get(my_id)
		if p:
			pos = p.global_position + Vector2(200, -60)
		print("[Network] selftest: 房主丢出浆果 @ ", pos)
		request_drop(pos, Vector2(700, -500))
	if _auto_selftest:
		await get_tree().create_timer(3.0).timeout
		if not is_instance_valid(self):
			return
		_run_selftest()


func _run_selftest() -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		print("[Network] selftest: 场景为空")
		return
	var drop: = scene.get_node_or_null("BerryDrop_1")
	print("[Network] selftest: BerryDrop_1 存在=", drop != null)
	var my_id: = multiplayer.get_unique_id()
	var p: Node = players.get(my_id)
	if drop and p:
		if drop.has_method("_on_body_entered"):
			drop._on_body_entered(p)
		await get_tree().create_timer(0.5).timeout
		if not is_instance_valid(self):
			return
		var drop2: = scene.get_node_or_null("BerryDrop_1")
		print("[Network] selftest: 拾取后 BerryDrop_1 存在=", drop2 != null)
		if p.has_method("_print_inventory"):
			p._print_inventory()

		p.set("selected_slot", 0)
		if p.has_method("_drop_selected_item"):
			p._drop_selected_item()
			await get_tree().create_timer(0.5).timeout
			if not is_instance_valid(self):
				return
			var drop3: = get_tree().current_scene.get_node_or_null("BerryDrop_2") if get_tree().current_scene else null
			print("[Network] selftest: 丢弃后 BerryDrop_2 存在=", drop3 != null)
			if p.has_method("_print_inventory"):
				p._print_inventory()

	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self):
		return
	var p2: Node = players.get(my_id)
	if p2 and p2.has_method("_print_inventory"):
		p2._print_inventory()







func request_harvest(bush_id: int) -> void :
	if _am_local_handler():

		_handle_harvest_request(bush_id)
	else:
		_request_harvest.rpc_id(1, bush_id)



func _am_local_handler() -> bool:
	var peer: = multiplayer.multiplayer_peer
	return peer is OfflineMultiplayerPeer or is_host



@rpc("any_peer", "call_remote", "reliable")
func _request_harvest(bush_id: int) -> void :
	if not is_host:
		return
	_handle_harvest_request(bush_id)


func _handle_harvest_request(bush_id: int) -> void :
	var bush: = _find_bush(bush_id)
	if bush == null:
		return
	if bush.has_method("is_harvested") and bush.is_harvested():
		return
	var berry_id: = _next_berry_id
	_next_berry_id += 1

	_bush_berries[bush_id] = berry_id
	_bush_harvested.rpc(bush_id, berry_id)



@rpc("authority", "call_local", "reliable")
func _bush_harvested(bush_id: int, berry_id: int) -> void :
	_apply_bush_harvested(bush_id, berry_id)


func _apply_bush_harvested(bush_id: int, berry_id: int) -> void :
	var bush: = _find_bush(bush_id)
	var pos: = DEFAULT_SPAWN
	if bush:
		pos = bush.global_position
		if bush.has_method("on_harvested"):
			bush.on_harvested()
	_spawn_berry_drop(berry_id, pos)



func request_pickup(berry_id: int) -> void :
	if _am_local_handler():
		if is_host:

			_berry_picked.rpc(berry_id)
		else:

			_apply_berry_picked(berry_id)
	else:
		_request_pickup.rpc_id(1, berry_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_pickup(berry_id: int) -> void :
	if not is_host:
		return
	_berry_picked.rpc(berry_id)



@rpc("authority", "call_local", "reliable")
func _berry_picked(berry_id: int) -> void :
	_apply_berry_picked(berry_id)


func _apply_berry_picked(berry_id: int) -> void :

	if is_host:
		_live_berry_pos.erase(berry_id)
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var drop: = scene.get_node_or_null("BerryDrop_%d" % berry_id)
	if drop:
		drop.queue_free()
		print("[Network] 移除掉落物 BerryDrop_", berry_id)



func request_drop(world_pos: Vector2, throw_vel: Vector2 = Vector2.ZERO) -> void :
	if _am_local_handler():
		var berry_id: = _next_berry_id
		_next_berry_id += 1
		if is_host:

			_berry_dropped.rpc(berry_id, world_pos, throw_vel)
		else:

			_spawn_berry_drop(berry_id, world_pos, throw_vel)
	else:
		_request_drop.rpc_id(1, world_pos, throw_vel)


@rpc("any_peer", "call_remote", "reliable")
func _request_drop(world_pos: Vector2, throw_vel: Vector2) -> void :
	if not is_host:
		return
	var berry_id: = _next_berry_id
	_next_berry_id += 1
	_berry_dropped.rpc(berry_id, world_pos, throw_vel)



@rpc("authority", "call_local", "reliable")
func _berry_dropped(berry_id: int, world_pos: Vector2, throw_vel: Vector2) -> void :
	_spawn_berry_drop(berry_id, world_pos, throw_vel)


func _spawn_berry_drop(berry_id: int, world_pos: Vector2, throw_vel: Vector2 = Vector2.ZERO) -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		return

	if scene.get_node_or_null("BerryDrop_%d" % berry_id):
		return

	if is_host:
		_live_berry_pos[berry_id] = world_pos
	var drop: Node2D = berry_drop_scene.instantiate()
	drop.name = "BerryDrop_%d" % berry_id
	drop.berry_id = berry_id
	drop.global_position = world_pos

	scene.add_child(drop)
	if drop.has_method("setup"):
		drop.setup(throw_vel)
	print("[Network] 生成掉落物 BerryDrop_", berry_id, " @ ", world_pos, " vel=", throw_vel)



func _find_bush(bush_id: int) -> Node:
	var scene: = get_tree().current_scene
	if scene == null:
		return null
	for child in scene.find_children("*", "", true, false):
		if child.has_method("is_berry_bush") and int(child.get("bush_id")) == bush_id:
			return child
	return null







@rpc("any_peer", "call_remote", "reliable")
func _request_world_state() -> void :
	if not is_host:
		return
	var sid: = multiplayer.get_remote_sender_id()
	if sid == 0:
		return

	_sync_world_state.rpc_id(sid, _bush_berries, _live_berry_pos)



@rpc("authority", "call_remote", "reliable")
func _sync_world_state(bush_berries: Dictionary, live_berries: Dictionary) -> void :
	for bush_id in bush_berries.keys():
		_apply_bush_harvested(int(bush_id), int(bush_berries[bush_id]))
	for berry_id in live_berries.keys():
		_spawn_berry_drop(int(berry_id), live_berries[berry_id])

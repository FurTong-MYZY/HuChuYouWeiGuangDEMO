@tool
extends EditorPlugin





const SINGLE_SCENE: = "res://addons/neon_block_placer/neon_block.tscn"
const GROUP_SCENE: = "res://addons/neon_block_placer/neon_block_group.tscn"

const SINGLE_ITEMS: = {
	1: {"label": "冲刺块", "name": "Neon_Dash", "mode": 0, "hold": true, "start": true, "reverse": false}, 
	2: {"label": "跳跃块", "name": "Neon_Jump", "mode": 1, "hold": true, "start": true, "reverse": false}, 
	3: {"label": "交互块", "name": "Neon_Interact", "mode": 4, "hold": true, "start": false, "reverse": false}, 
	4: {"label": "左块", "name": "Neon_Left", "mode": 2, "hold": true, "start": false, "reverse": false}, 
	5: {"label": "右块", "name": "Neon_Right", "mode": 3, "hold": true, "start": false, "reverse": false}, 
	6: {"label": "反向左块", "name": "Neon_Left_Rev", "mode": 2, "hold": false, "start": true, "reverse": true}, 
	7: {"label": "反向右块", "name": "Neon_Right_Rev", "mode": 3, "hold": false, "start": true, "reverse": true}, 
	8: {"label": "反向交互块", "name": "Neon_Interact_Rev", "mode": 4, "hold": false, "start": true, "reverse": true}, 
}

var _menu_button: MenuButton

func _enter_tree() -> void :
	_menu_button = MenuButton.new()
	_menu_button.text = "霓虹方块"
	_menu_button.tooltip_text = "快速放置 8 种霓虹方块：选中方块时放到它右边，否则放到视图中心（支持撤销）"
	_menu_button.flat = true
	var popup: = _menu_button.get_popup()
	popup.add_item("放置整组（8 个）", 0)
	popup.add_separator()
	for id in SINGLE_ITEMS:
		popup.add_item(SINGLE_ITEMS[id]["label"], id)
	popup.id_pressed.connect(_on_menu_id_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _menu_button)

func _exit_tree() -> void :
	if is_instance_valid(_menu_button):
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _menu_button)
		_menu_button.queue_free()
		_menu_button = null

func _on_menu_id_pressed(id: int) -> void :
	if id == 0:
		_place_group()
	elif SINGLE_ITEMS.has(id):
		_place_single(id)

func _place_group() -> void :
	var root: = get_editor_interface().get_edited_scene_root()
	if root == null:
		OS.alert("请先打开一个场景。", "霓虹方块")
		return
	var group: = load(GROUP_SCENE).instantiate() as Node2D
	if group == null:
		return
	group.name = "NeonBlocks"
	_place_node(group, _get_parent(root), root, true)

func _place_single(id: int) -> void :
	var root: = get_editor_interface().get_edited_scene_root()
	if root == null:
		OS.alert("请先打开一个场景。", "霓虹方块")
		return
	var cfg: Dictionary = SINGLE_ITEMS[id]
	var block: Node = load(SINGLE_SCENE).instantiate()
	if block == null:
		return
	block.name = cfg["name"]
	block.set("mode", cfg["mode"])
	block.set("hold_solid", cfg["hold"])
	block.set("start_solid", cfg["start"])
	block.set("reverse_style", cfg["reverse"])
	_place_node(block, _get_parent(root), root, false)


func _get_parent(root: Node) -> Node:
	var selected: = get_editor_interface().get_selection().get_selected_nodes()
	if selected.size() > 0:
		var n: Node = selected[0]
		if n is NeonBlock:
			n = n.get_parent()
		if n != null and n != root and n is Node2D and n.owner == root:
			return n
	return root





func _get_placement_position(is_group: bool) -> Vector2:
	var selected: = get_editor_interface().get_selection().get_selected_nodes()
	if selected.size() > 0 and selected[0] is NeonBlock:
		var base: Vector2 = (selected[0] as Node2D).global_position
		return base + Vector2(2000.0 if is_group else 600.0, 0.0)

	var vp: = get_editor_interface().get_editor_viewport_2d()
	if vp:
		return vp.get_canvas_transform().affine_inverse() * (Vector2(vp.size) * 0.5)

	if selected.size() > 0 and selected[0] is Node2D:
		return selected[0].global_position
	return Vector2.ZERO

func _place_node(node: Node, parent: Node, root: Node, is_group: bool) -> void :
	if parent == null or root == null:
		OS.alert("找不到可放置的父节点。", "霓虹方块")
		return
	var pos: = _get_placement_position(is_group)
	var ur: = get_undo_redo()
	ur.create_action("放置霓虹方块")
	ur.add_do_method(parent, "add_child", node, true)
	ur.add_do_method(self, "_set_owner_recursive", node, root)
	if node is Node2D:
		ur.add_do_method(node, "set_global_position", pos)
	ur.add_undo_method(parent, "remove_child", node)
	ur.commit_action()

	var ei: = get_editor_interface()
	ei.get_selection().clear()
	ei.get_selection().add_node(node)
	if ei.has_method("mark_scene_as_unsaved"):
		ei.call("mark_scene_as_unsaved")

func _set_owner_recursive(node: Node, root: Node) -> void :
	node.owner = root
	for child in node.get_children():
		_set_owner_recursive(child, root)

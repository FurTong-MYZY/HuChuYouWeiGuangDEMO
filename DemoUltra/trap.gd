extends TileMapLayer

var player: CharacterBody2D = null
var timer: float = 0.0
var is_trap: bool = false
var is_contamination: bool = false
var player_found: bool = false

@export var detection_expand: Vector2 = Vector2(20, 20)

const CHECK_FACTORS: = [
	Vector2.ZERO, 
	Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0), 
	Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), 
]

func _ready() -> void :
	var name_lower = name.to_lower()
	is_trap = "trap" in name_lower
	is_contamination = "contamination" in name_lower

	if is_trap or is_contamination:
		collision_enabled = false

	rendering_quadrant_size = 16
	call_deferred("_find_player")
	if is_trap:
		call_deferred("_refresh_trap_visuals")



func _refresh_trap_visuals() -> void :
	if not is_trap or tile_set == null:
		return
	var cells: = get_used_cells()
	if cells.is_empty():
		return
	var sid: = get_cell_source_id(cells[0])
	var src: = tile_set.get_source(sid) as TileSetAtlasSource
	if src == null:
		return
	_apply_theme_texture(src)

	for style in range(4):
		for mask in range(16):
			var coord: = Vector2i(style, mask)
			if not src.has_tile(coord):
				src.create_tile(coord)

	var style_index: = _chapter_trap_style(src)
	for cell in cells:
		var mask: = 0
		if get_cell_source_id(cell + Vector2i(-1, 0)) != -1: mask |= 1
		if get_cell_source_id(cell + Vector2i(1, 0)) != -1: mask |= 2
		if get_cell_source_id(cell + Vector2i(0, -1)) != -1: mask |= 4
		if get_cell_source_id(cell + Vector2i(0, 1)) != -1: mask |= 8

		var style: = style_index
		set_cell(cell, sid, Vector2i(style, mask), 0)

func _chapter_trap_style(src: TileSetAtlasSource) -> int:


	var tex_path: = ""
	if src and src.texture:
		tex_path = src.texture.resource_path.get_file()
	match tex_path:
		"lab_trap.png":
			return 0
		"city_trap.png":
			return 1
		"cyber_trap.png":
			return 2
		"warn_trap.png":
			return 3

	var scene_name: = _scene_path().get_file()
	match scene_name:
		"lab.tscn", "lab_B.tscn":
			return 0
		"city.tscn", "city_B.tscn":
			return 1
		"scene.tscn":
			return 2
		"Warning.tscn":
			return 3
	return 0

func _scene_path() -> String:

	var root: Node = owner
	if root == null:
		root = get_tree().current_scene
	if root == null:
		return ""
	return root.scene_file_path

func _apply_theme_texture(src: TileSetAtlasSource) -> void :

	var scene_name: = _scene_path().get_file()
	var path: = ""
	match scene_name:
		"scene.tscn":
			path = "res://spr/场景/主题/cyber_trap.png"
		"Warning.tscn":
			path = "res://spr/场景/主题/warn_trap.png"
		"lab.tscn", "lab_B.tscn":
			path = "res://spr/场景/主题/lab_trap.png"
		"city.tscn", "city_B.tscn":
			path = "res://spr/场景/主题/city_trap.png"
	if path.is_empty():
		return
	var tex: = load(path) as Texture2D
	if tex and src.texture != tex:
		src.texture = tex

func _find_player() -> void :
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		player_found = true
	else:
		await get_tree().create_timer(0.5).timeout
		_find_player()

func _physics_process(delta: float) -> void :
	if not player_found:
		return

	if not is_instance_valid(player):
		player = null
		player_found = false
		return

	timer -= delta
	if timer > 0:
		return
	timer = 0.1


	var found_tile = false
	for factor in CHECK_FACTORS:
		var point: Vector2 = player.global_position + factor * detection_expand
		var local_pos = to_local(point)
		var cell = local_to_map(local_pos)
		var tile_data = get_cell_tile_data(cell)
		if tile_data != null:
			found_tile = true
			break

	if not found_tile:
		if is_contamination and player.has_method("remove_contamination_source"):
			player.remove_contamination_source(self)
		return
	if is_trap:
		if player.has_method("take_trap_damage"):
			player.take_trap_damage()
	elif is_contamination:
		if player.has_method("add_contamination_source"):
			player.add_contamination_source(self)

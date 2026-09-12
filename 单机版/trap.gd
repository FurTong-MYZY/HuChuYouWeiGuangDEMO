extends TileMapLayer

var player: CharacterBody2D = null
var timer: float = 0.0
var is_trap: bool = false
var is_contamination: bool = false
var player_found: bool = false

@export var detection_expand: Vector2 = Vector2(20, 20)

func _ready() -> void :
	var name_lower = name.to_lower()
	is_trap = "trap" in name_lower
	is_contamination = "contamination" in name_lower

	call_deferred("_find_player")

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


	var check_points = [
		player.global_position, 
		player.global_position + Vector2(0, - detection_expand.y), 
		player.global_position + Vector2(0, detection_expand.y), 
		player.global_position + Vector2( - detection_expand.x, 0), 
		player.global_position + Vector2(detection_expand.x, 0), 
		player.global_position + Vector2( - detection_expand.x, - detection_expand.y), 
		player.global_position + Vector2(detection_expand.x, - detection_expand.y), 
		player.global_position + Vector2( - detection_expand.x, detection_expand.y), 
		player.global_position + Vector2(detection_expand.x, detection_expand.y), 
	]

	var found_tile = false

	for point in check_points:
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

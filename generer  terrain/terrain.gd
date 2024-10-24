extends Node2D

@export var herbeTerrain: PackedScene
@export var meteoriteSprite: Sprite2D
@export var diploSprite: Sprite2D
@export var missileSprite: Sprite2D
@export var terrain_textures: Array[CompressedTexture2D]

var tile_size = 100
var tile_spacing = 3
var player_position = Vector2(0, 0)
var ennemi_position = Vector2(10, 5)
var width_terrain = 11
var height_terrain = 6
var wait_time: float = 0.0
var terrain_grid: Array
var wait_time_label: Label
var missile_wait_time_label: Label

var missile_path: Array = []
var current_missile_target_index: int = 0
var missile_wait_time: float = 0.0
var missile_move_time: float = 0.5

func _ready():
	terrain_grid = []
	var random_diplo_x = randi_range(1, width_terrain - 2)
	var random_diplo_y = randi_range(1, height_terrain - 2)
	var random_scooter_x = randi_range(1, width_terrain - 2)
	var random_scooter_y = randi_range(1, height_terrain - 2)
	
	for x in range(width_terrain):
		terrain_grid.append([])
		for y in range(height_terrain):
			var instance = herbeTerrain.instantiate()
			var selected_texture_index = 0
			
			if (x == 0 and y == 0) or (x == width_terrain - 1 and y == height_terrain - 1):
				instance.texture = terrain_textures[0]
			elif x == random_diplo_x and y == random_diplo_y:
				instance.texture = terrain_textures[0]
				diploSprite.position = Vector2(x * (tile_size + tile_spacing) + 60, y * (tile_size + tile_spacing) + 60)
				add_child(diploSprite)
			elif x == random_scooter_x and y == random_scooter_y:
				selected_texture_index = 4
				instance.texture = terrain_textures[4]
			else:
				if terrain_textures.size() > 0:
					selected_texture_index = randi_range(0, terrain_textures.size() - 2)
					var random_texture = terrain_textures[selected_texture_index]
					instance.texture = random_texture
			
			instance.position = Vector2(x * (tile_size + tile_spacing) + 60, y * (tile_size + tile_spacing) + 60)
			add_child(instance)
			
			terrain_grid[x].append(selected_texture_index)

	meteoriteSprite.position = get_tile_position(player_position)
	add_child(meteoriteSprite)
	missileSprite.position = get_tile_position(ennemi_position)
	add_child(missileSprite)
	
	wait_time_label = Label.new()
	wait_time_label.text = "Wait Time: 0.0"
	wait_time_label.position = Vector2(width_terrain * (tile_size + tile_spacing) + 80, 50)
	add_child(wait_time_label)

	missile_wait_time_label = Label.new()
	missile_wait_time_label.text = "Missile Wait Time: 0.0"
	missile_wait_time_label.position = Vector2(width_terrain * (tile_size + tile_spacing) + 80, 80)
	add_child(missile_wait_time_label)

	calculate_missile_path()

func _process(delta):
	wait_time -= delta
	missile_wait_time -= delta

	if wait_time <= 0.0:
		if Input.is_action_pressed("ui_right"):
			move_player(Vector2(1, 0))
		elif Input.is_action_pressed("ui_left"):
			move_player(Vector2(-1, 0))
		elif Input.is_action_pressed("ui_down"):
			move_player(Vector2(0, 1))
		elif Input.is_action_pressed("ui_up"):
			move_player(Vector2(0, -1))
	
	var varWaitTime = round(max(wait_time, 0.0) * 10) / 10.0
	if (varWaitTime <= 0.2):
		varWaitTime = 0.0
	wait_time_label.text = "Wait Time: " + str(varWaitTime)

	var varMissileWaitTime = round(max(missile_wait_time, 0.0) * 10) / 10.0
	if (varMissileWaitTime <= 0.2):
		varMissileWaitTime = 0.0
	missile_wait_time_label.text = "Missile Wait Time: " + str(varMissileWaitTime)

	if missile_path.size() > 0 and missile_wait_time <= 0:
		move_missile()
	
	check_victory_condition()

func move_player(direction: Vector2):
	var new_position = player_position + direction

	if new_position.x >= 0 and new_position.x < width_terrain and new_position.y >= 0 and new_position.y < height_terrain:
		player_position = new_position
		meteoriteSprite.position = get_tile_position(player_position)

		var texture_index = terrain_grid[int(new_position.x)][int(new_position.y)]
		if texture_index == 0:
			wait_time = 0.2
		else:
			wait_time = float(texture_index)

		calculate_missile_path()

func calculate_missile_path():
	missile_path.clear()
	var start = missileSprite.position
	var end = player_position

	var start_x = int(start.x / (tile_size + tile_spacing + 1))
	var start_y = int(start.y / (tile_size + tile_spacing + 1))
	var end_x = int(end.x)
	var end_y = int(end.y)

	var open_set = []
	var came_from = {}
	var g_score = {}
	var f_score = {}
	
	for x in range(width_terrain):
		for y in range(height_terrain):
			g_score[Vector2(x, y)] = INF
			f_score[Vector2(x, y)] = INF
	g_score[Vector2(start_x, start_y)] = 0
	f_score[Vector2(start_x, start_y)] = heuristic(Vector2(start_x, start_y), Vector2(end_x, end_y))

	open_set.append(Vector2(start_x, start_y))

	while open_set.size() > 0:
		var current = lowest_f_score(open_set, f_score)
		if current == Vector2(end_x, end_y):
			reconstruct_path(came_from, current)
			return
		
		open_set.erase(current)

		for neighbor in get_neighbors(current):
			var tentative_g_score = g_score[current] + terrain_grid[int(neighbor.x)][int(neighbor.y)]
			if tentative_g_score < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = g_score[neighbor] + heuristic(neighbor, Vector2(end_x, end_y))
				if not open_set.has(neighbor):
					open_set.append(neighbor)

func move_missile():
	if current_missile_target_index < missile_path.size():
		var target = missile_path[current_missile_target_index]
		var target_position = get_tile_position(target)

		if missileSprite.position.distance_to(target_position) > 1:
			missileSprite.position = missileSprite.position.move_toward(target_position, 100 * get_process_delta_time())
		else:
			if target == player_position:
				game_over()
				return

			var texture_index = terrain_grid[int(target.x)][int(target.y)]
			if texture_index == 0:
				missile_wait_time = 0.2
			else:
				missile_wait_time = float(texture_index)
			current_missile_target_index += 1
	else:
		calculate_missile_path()

func get_neighbors(position: Vector2) -> Array:
	var neighbors = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx == 0 and dy == 0) or abs(dx) + abs(dy) > 1:
				continue
			var neighbor = position + Vector2(dx, dy)
			if neighbor.x >= 0 and neighbor.x < width_terrain and neighbor.y >= 0 and neighbor.y < height_terrain:
				neighbors.append(neighbor)
	return neighbors

func lowest_f_score(open_set: Array, f_score: Dictionary) -> Vector2:
	var lowest = open_set[0]
	for node in open_set:
		if f_score[node] < f_score[lowest]:
			lowest = node
	return lowest

func reconstruct_path(came_from: Dictionary, current: Vector2):
	while current in came_from:
		missile_path.insert(0, current)
		current = came_from[current]
	current_missile_target_index = 0

func heuristic(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

func get_tile_position(pos: Vector2) -> Vector2:
	return Vector2(
		pos.x * (tile_size + tile_spacing + 1) + tile_size / 2,
		pos.y * (tile_size + tile_spacing + 1) + tile_size / 2
	)

func check_victory_condition():
	if meteoriteSprite.position.distance_to(diploSprite.position) < 15:
		win_game()

func win_game():
	var win_label = Label.new()
	win_label.text = "You Win"
	win_label.modulate = Color(0, 1, 0)
	win_label.position = Vector2(
		1152 / 2 - win_label.get_minimum_size().x / 2,
		648 / 2 - win_label.get_minimum_size().y / 2
	)
	
	add_child(win_label)
	get_tree().paused = true

func game_over():
	var game_over_label = Label.new()
	game_over_label.text = "Game Over"
	game_over_label.modulate = Color(1, 0, 0)
	game_over_label.position = Vector2(
		1152 / 2 - game_over_label.get_minimum_size().x / 2,
		648 / 2 - game_over_label.get_minimum_size().y / 2
	)
	
	add_child(game_over_label)
	get_tree().paused = true

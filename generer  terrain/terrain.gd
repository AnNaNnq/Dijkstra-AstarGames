extends Node2D

###################################################################### Variable initialization ######################################################################
# Game elements
@export var meteoriteSprite: Sprite2D
@export var diploSprite: Sprite2D
@export var missileSprite: Sprite2D
@export var herbeTerrain: PackedScene
@export var terrain_textures: Array[CompressedTexture2D]
var wait_time: float = 0.0

# Playground variables
var tile_size = 100
var tile_spacing = 3
var width_playground = 11
var height_playground = 6
var playground_grid: Array

# Positions variables
var player_position = Vector2(0, 0)
var ennemi_position = Vector2(10, 5)
var random_diplo_x = 0
var random_diplo_y = 0
var random_scooter_x = 0
var random_scooter_y = 0

# Labels variables
var wait_time_label: Label
var missile_wait_time_label: Label
var diplo_wait_time_label: Label
var rules_label: Label

# Missile variables
var missile_path: Array = []
var current_missile_target_index: int = 0
var missile_wait_time: float = 0.0
var missile_move_time: float = 0.5

# Diplodocus variables
var diplo_path: Array = []
var current_diplo_target_index: int = 0
var diplo_wait_time: float = 0.0
var diplo_move_time: float = 0.5
#####################################################################################################################################################################



########################################################################## Main Functions ###########################################################################
# Function called at program launch
func _ready():
	playground_grid = []
	random_diplo_x = randi_range(1, width_playground - 2)
	random_diplo_y = randi_range(1, height_playground - 2)
	random_scooter_x = randi_range(1, width_playground - 2)
	random_scooter_y = randi_range(1, height_playground - 2)
	
	for x in range(width_playground):
		playground_grid.append([])
		for y in range(height_playground):
			var instance = herbeTerrain.instantiate()
			var selected_texture_index = 0
			
			if (x == 0 and y == 0) or (x == width_playground - 1 and y == height_playground - 1):
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
			
			playground_grid[x].append(selected_texture_index)

	meteoriteSprite.position = get_tile_position(player_position)
	add_child(meteoriteSprite)
	missileSprite.position = get_tile_position(ennemi_position)
	add_child(missileSprite)

	wait_time_label = Label.new()
	wait_time_label.text = "Wait Time: 0.0"
	wait_time_label.position = Vector2(width_playground * (tile_size + tile_spacing) + 20, 50)
	add_child(wait_time_label)

	missile_wait_time_label = Label.new()
	missile_wait_time_label.text = "Missile Wait Time: 0.0"
	missile_wait_time_label.position = Vector2(width_playground * (tile_size + tile_spacing) + 20, 80)
	add_child(missile_wait_time_label)
	
	diplo_wait_time_label = Label.new()
	diplo_wait_time_label.text = "Diplodocus Wait Time: 0.0"
	diplo_wait_time_label.position = Vector2(width_playground * (tile_size + tile_spacing) + 20, 110)
	add_child(diplo_wait_time_label)
	
	rules_label = Label.new()
	rules_label.text = "Règles :\nTu es la météorite et tu dois\nattraper le diplodocus avant \nqu'il ne s'enfuit en scooter!\n
	Fais attention au missile\nqu'il a lancé avant de s'enfuir!"
	rules_label.position = Vector2(width_playground * (tile_size + tile_spacing) + 20, 220)
	add_child(rules_label)

	calculate_missile_path()
	calculate_diplo_path()


# Function called each frame
func _process(delta):
	wait_time -= delta
	missile_wait_time -= delta
	diplo_wait_time -= delta

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
	
	var varDiploWaitTime = round(max(diplo_wait_time, 0.0) * 10) / 10.0
	if (varDiploWaitTime <= 0.2):
		varDiploWaitTime = 0.0
	diplo_wait_time_label.text = "Diplodocus Wait Time: " + str(varDiploWaitTime)

	if missile_path.size() > 0 and missile_wait_time <= 0:
		move_missile()
	
	if diplo_path.size() > 0 and diplo_wait_time <= 0:
		move_diplo()

	check_victory_condition()
#####################################################################################################################################################################



########################################################################## Move the player ##########################################################################
# Function to move the player (meteorite)
func move_player(direction: Vector2):
	var new_position = player_position + direction

	if new_position.x >= 0 and new_position.x < width_playground and new_position.y >= 0 and new_position.y < height_playground:
		player_position = new_position
		meteoriteSprite.position = get_tile_position(player_position)

		var texture_index = playground_grid[int(new_position.x)][int(new_position.y)]
		if texture_index == 0:
			wait_time = 0.2
		else:
			wait_time = float(texture_index)

		calculate_missile_path()
#####################################################################################################################################################################



########################################################################## Move the missile ##########################################################################
# Function that calculates the path the missile must take to reach the player's position (Dijkstra)
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

	for x in range(width_playground):
		for y in range(height_playground):
			g_score[Vector2(x, y)] = INF
	g_score[Vector2(start_x, start_y)] = 0

	open_set.append(Vector2(start_x, start_y))

	while open_set.size() > 0:
		var current = lowest_g_score(open_set, g_score)
		if current == Vector2(end_x, end_y):
			reconstruct_path_missile(came_from, current)
			return

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			var tentative_g_score = g_score[current] + playground_grid[int(neighbor.x)][int(neighbor.y)]
			if tentative_g_score < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				if not open_set.has(neighbor):
					open_set.append(neighbor)

# Function to move the missile (enemy)
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

			var texture_index = playground_grid[int(target.x)][int(target.y)]
			if texture_index == 0:
				missile_wait_time = 0.2
			else:
				missile_wait_time = float(texture_index)
			current_missile_target_index += 1
	else:
		calculate_missile_path()

# Function that creates a list of positions that the missile will follow
func reconstruct_path_missile(came_from: Dictionary, current: Vector2):
	while current in came_from:
		missile_path.insert(0, current)
		current = came_from[current]
	current_missile_target_index = 0
#####################################################################################################################################################################



######################################################################## Move the diplodocus ########################################################################
# Function that calculates the path the diplodocus must take to reach the scooter's position (A*)
func calculate_diplo_path():
	diplo_path.clear()
	var start = Vector2(random_diplo_x, random_diplo_y)
	var end = Vector2(random_scooter_x, random_scooter_y)

	var open_set = []
	var came_from = {}
	var g_score = {}
	var f_score = {}

	for x in range(width_playground):
		for y in range(height_playground):
			g_score[Vector2(x, y)] = INF
			f_score[Vector2(x, y)] = INF
	g_score[start] = 0
	f_score[start] = heuristic(start, end)

	open_set.append(start)

	while open_set.size() > 0:
		var current = lowest_g_score(open_set, f_score)
		if current == end:
			reconstruct_path_diplo(came_from, current)
			return

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			var tentative_g_score = g_score[current] + playground_grid[int(neighbor.x)][int(neighbor.y)]
			if tentative_g_score < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + heuristic(neighbor, end)
				if not open_set.has(neighbor):
					open_set.append(neighbor)

# Function to move the diplodocus (objectif)
func move_diplo():
	if current_diplo_target_index < diplo_path.size():
		var target = diplo_path[current_diplo_target_index]
		var target_position = get_tile_position(target)

		if diploSprite.position.distance_to(target_position) > 1:
			diploSprite.position = diploSprite.position.move_toward(target_position, 100 * get_process_delta_time())
		else:
			var texture_index = playground_grid[int(target.x)][int(target.y)]
			if texture_index == 0:
				diplo_wait_time = 0.2
			else:
				diplo_wait_time = float(texture_index)
			current_diplo_target_index += 1
	else:
		calculate_diplo_path()

# Function that creates a list of positions that the Diplodocus will follow
func reconstruct_path_diplo(came_from: Dictionary, current: Vector2):
	while current in came_from:
		diplo_path.insert(0, current)
		current = came_from[current]
	current_diplo_target_index = 0
#####################################################################################################################################################################



######################################################################### Utility functions #########################################################################
# Function to calculate the actual cost of moving from the starting point to a position on the grid
# @param	open_set	open_set is a list containing positions still to be explored
# @param	g_score		dictionary that maps each position to a cost
# @return				position of the open_set with the lowest g_score cost
func lowest_g_score(open_set: Array, g_score: Dictionary) -> Vector2:
	var lowest = open_set[0]
	for node in open_set:
		if g_score[node] < g_score[lowest]:
			lowest = node
	return lowest

# Function to retrieve the valid neighboring positions around a given position on the grid
# @param	position	position is the current grid position from which neighbors are being evaluated
# @return				an array of valid neighboring positions that are within grid bounds and not diagonally adjacent to the original position
func get_neighbors(position: Vector2) -> Array:
	var neighbors = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx == 0 and dy == 0) or abs(dx) + abs(dy) > 1:
				continue
			var neighbor = position + Vector2(dx, dy)
			if neighbor.x >= 0 and neighbor.x < width_playground and neighbor.y >= 0 and neighbor.y < height_playground:
				neighbors.append(neighbor)
	return neighbors

# Function to calculate the heuristic distance between two positions on the grid
# @param	a		the first position as a Vector2
# @param	b		the second position as a Vector2
# @return			the Euclidean distance between the two positions
func heuristic(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

# Function to calculate the pixel position of a tile based on its grid coordinates
# @param	pos		the grid position as a Vector2, representing the tile's coordinates
# @return			a Vector2 representing the pixel position of the tile, calculated by considering the tile size and spacing, placing it at the center of the tile
func get_tile_position(pos: Vector2) -> Vector2:
	return Vector2(
		pos.x * (tile_size + tile_spacing + 1) + tile_size / 2,
		pos.y * (tile_size + tile_spacing + 1) + tile_size / 2
	)

# Function to check the conditions for winning or losing the game
# 1. If the meteorite sprite is within a certain distance from the diplodocus sprite, the player wins the game.
# 2. If the diplodocus sprite is within a certain distance from the scooter's position, the player loses the game.
func check_victory_condition():
	if meteoriteSprite.position.distance_to(diploSprite.position) < 15:
		win_game()
		
	var scooter_position = get_tile_position(Vector2(random_scooter_x, random_scooter_y))
	if diploSprite.position.distance_to(scooter_position) < 15:
		game_over()

# Function to display "You Win" when the player wins
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

# Function to display "Game Over" when the player loses
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
#####################################################################################################################################################################

class_name SimGrid
extends RefCounted
## Сетка механизма 5×4 (core-rules §3). y = 3 — нижний ряд, Сердце в (2, 3).
## Шестерни хранятся в порядке возрастания id — это стабильный порядок перебора.

const WIDTH: int = 5
const HEIGHT: int = 4
const HEART_X: int = 2
const HEART_Y: int = 3
const EMPTY: int = -1
const BLOCKED: int = -2
const HEART: int = -3

var gears: Array[SimGear] = []

var _cells: Array[int] = []


func _init() -> void:
	_cells.resize(WIDTH * HEIGHT)
	_cells.fill(EMPTY)
	_cells[_index(HEART_X, HEART_Y)] = HEART


static func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT


static func is_heart(x: int, y: int) -> bool:
	return x == HEART_X and y == HEART_Y


## Содержимое клетки: id шестерни (>= 0), EMPTY, BLOCKED или HEART. Вне сетки — BLOCKED.
func cell(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return BLOCKED
	return _cells[_index(x, y)]


func is_free(x: int, y: int) -> bool:
	return cell(x, y) == EMPTY


func gear_at(x: int, y: int) -> SimGear:
	var c: int = cell(x, y)
	if c < 0:
		return null
	return get_gear(c)


func get_gear(gear_id: int) -> SimGear:
	for g: SimGear in gears:
		if g.id == gear_id:
			return g
	return null


## Ставит шестерню в свободную клетку. Возвращает false, если клетка занята или вне сетки.
func place(gear: SimGear) -> bool:
	if not is_free(gear.x, gear.y):
		return false
	_cells[_index(gear.x, gear.y)] = gear.id
	var i: int = 0
	while i < gears.size() and gears[i].id < gear.id:
		i += 1
	gears.insert(i, gear)
	return true


func remove(gear_id: int) -> void:
	var g: SimGear = get_gear(gear_id)
	if g == null:
		return
	_cells[_index(g.x, g.y)] = EMPTY
	gears.erase(g)


## Переносит шестерню в свободную клетку.
func move(gear_id: int, x: int, y: int) -> bool:
	var g: SimGear = get_gear(gear_id)
	if g == null or not is_free(x, y):
		return false
	_cells[_index(g.x, g.y)] = EMPTY
	g.x = x
	g.y = y
	_cells[_index(x, y)] = gear_id
	return true


## Занимает пустую клетку препятствием (глыба, труба).
func block(x: int, y: int) -> bool:
	if not is_free(x, y):
		return false
	_cells[_index(x, y)] = BLOCKED
	return true


func unblock(x: int, y: int) -> void:
	if cell(x, y) == BLOCKED and in_bounds(x, y):
		_cells[_index(x, y)] = EMPTY


static func _index(x: int, y: int) -> int:
	return y * WIDTH + x

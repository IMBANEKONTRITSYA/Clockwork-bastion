class_name BattleLayout
extends RefCounted
## Раскладка экрана боя. Ширина всегда 1080 (stretch keep_width), высота — как у телефона.
## Снизу вверх: панель запаса и кнопок прижата к низу, над ней сетка 5×4, Стена,
## а поле боя занимает всё оставшееся место — пустых полос не остаётся.

const WIDTH: float = 1080.0
const MIN_HEIGHT: float = 1600.0
const HUD_HEIGHT: float = 110.0
const CELL: float = 180.0
const BOTTOM_MARGIN: float = 30.0
const PANEL_GAP: float = 30.0
const WALL_HEIGHT: float = 60.0
const WALL_GAP: float = 20.0
const SLOT_SIZE: float = 160.0
const SLOT_GAP: float = 20.0
const SLOTS_SHOWN: int = 4
const SIDE_MARGIN: float = 20.0
const BUY_WIDTH: float = 180.0
const SPEED_WIDTH: float = 120.0

var height: float = 1920.0
var grid_origin: Vector2 = Vector2.ZERO
var slot_y: float = 0.0
var wall_top: float = 0.0
var wall_bottom: float = 0.0
var field_top: float = HUD_HEIGHT + 20.0


func _init(screen_height: float = 1920.0) -> void:
	height = maxf(screen_height, MIN_HEIGHT)
	slot_y = height - BOTTOM_MARGIN - SLOT_SIZE
	var grid_size: Vector2 = Vector2(CELL * SimGrid.WIDTH, CELL * SimGrid.HEIGHT)
	grid_origin = Vector2((WIDTH - grid_size.x) * 0.5, slot_y - PANEL_GAP - grid_size.y)
	wall_bottom = grid_origin.y - WALL_GAP
	wall_top = wall_bottom - WALL_HEIGHT


func screen_size() -> Vector2:
	return Vector2(WIDTH, height)


## Экранный x для координаты поля ×1000 (совпадает с центрами колонок сетки).
func lane_x(x_x1000: int) -> float:
	return grid_origin.x + CELL * 0.5 + CELL * x_x1000 / 1000.0


## Экранный y для расстояния до Стены ×1000.
func field_y(y_x1000: int, field_length_x1000: int) -> float:
	var t: float = clampf(float(y_x1000) / maxf(1.0, float(field_length_x1000)), 0.0, 1.0)
	return wall_top - (wall_top - field_top) * t


func field_pos(x_x1000: int, y_x1000: int, field_length_x1000: int) -> Vector2:
	return Vector2(lane_x(x_x1000), field_y(y_x1000, field_length_x1000))


func cell_rect(x: int, y: int) -> Rect2:
	return Rect2(grid_origin + Vector2(x * CELL, y * CELL), Vector2(CELL, CELL))


func cell_center(x: int, y: int) -> Vector2:
	return cell_rect(x, y).get_center()


## Клетка сетки под точкой экрана; (-1, -1), если мимо.
func cell_at(pos: Vector2) -> Vector2i:
	var local: Vector2 = pos - grid_origin
	if local.x < 0.0 or local.y < 0.0:
		return Vector2i(-1, -1)
	var x: int = int(local.x / CELL)
	var y: int = int(local.y / CELL)
	if not SimGrid.in_bounds(x, y):
		return Vector2i(-1, -1)
	return Vector2i(x, y)


func slot_rect(index: int) -> Rect2:
	var x: float = SIDE_MARGIN + index * (SLOT_SIZE + SLOT_GAP)
	return Rect2(Vector2(x, slot_y), Vector2(SLOT_SIZE, SLOT_SIZE))


## Слот запаса под точкой экрана; -1, если мимо.
func slot_at(pos: Vector2) -> int:
	for i: int in SLOTS_SHOWN:
		if slot_rect(i).has_point(pos):
			return i
	return -1


func buy_rect() -> Rect2:
	var left: float = slot_rect(SLOTS_SHOWN - 1).end.x + SLOT_GAP
	return Rect2(Vector2(left, slot_y), Vector2(BUY_WIDTH, SLOT_SIZE))


func speed_rect() -> Rect2:
	return Rect2(
		Vector2(WIDTH - SIDE_MARGIN - SPEED_WIDTH, slot_y), Vector2(SPEED_WIDTH, SLOT_SIZE)
	)


## Центр поля боя — туда ставим окно паузы и итога.
func field_center() -> Vector2:
	return Vector2(WIDTH * 0.5, (field_top + wall_top) * 0.5)

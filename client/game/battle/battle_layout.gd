class_name BattleLayout
extends RefCounted
## Раскладка экрана боя. Ширина всегда 1080 (stretch keep_width), высота — как у телефона.
## Сверху: панель (волна, гайки, Стена, убийства) и колонка круглых кнопок слева.
## Снизу вверх: широкая кнопка «Купить», слоты запаса, сетка 5×4, латунные ворота-Стена;
## поле боя занимает всё оставшееся место — пустых полос не остаётся.

const WIDTH: float = 1080.0
const MIN_HEIGHT: float = 1600.0
const TOP_BAR_HEIGHT: float = 140.0
const CELL: float = 180.0
const BOTTOM_MARGIN: float = 30.0
const BUY_SIZE: Vector2 = Vector2(620.0, 130.0)
const BUY_GAP: float = 20.0
const SLOT_SIZE: float = 150.0
const SLOT_GAP: float = 20.0
const SLOTS_SHOWN: int = 4
const GRID_GAP: float = 25.0
const WALL_HEIGHT: float = 70.0
const WALL_GAP: float = 15.0
const SIDE_BUTTON: float = 110.0
const SIDE_MARGIN: float = 20.0
const SIDE_GAP: float = 24.0
const FIGHT_SIZE: Vector2 = Vector2(520.0, 150.0)
const BOSS_BAR_HEIGHT: float = 34.0

var height: float = 1920.0
var grid_origin: Vector2 = Vector2.ZERO
var slot_y: float = 0.0
var wall_top: float = 0.0
var wall_bottom: float = 0.0
var field_top: float = TOP_BAR_HEIGHT + 20.0


func _init(screen_height: float = 1920.0) -> void:
	height = maxf(screen_height, MIN_HEIGHT)
	var buy_top: float = height - BOTTOM_MARGIN - BUY_SIZE.y
	slot_y = buy_top - BUY_GAP - SLOT_SIZE
	var grid_size: Vector2 = Vector2(CELL * SimGrid.WIDTH, CELL * SimGrid.HEIGHT)
	grid_origin = Vector2((WIDTH - grid_size.x) * 0.5, slot_y - GRID_GAP - grid_size.y)
	wall_bottom = grid_origin.y - WALL_GAP
	wall_top = wall_bottom - WALL_HEIGHT


func screen_size() -> Vector2:
	return Vector2(WIDTH, height)


func top_bar_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(WIDTH, TOP_BAR_HEIGHT))


## Полоса прочности Стены в верхней панели.
func wall_bar_rect() -> Rect2:
	return Rect2(Vector2(300.0, 96.0), Vector2(WIDTH - 324.0, 26.0))


## Экранный x для координаты поля ×1000 (совпадает с центрами колонок сетки).
func lane_x(x_x1000: int) -> float:
	return grid_origin.x + CELL * 0.5 + CELL * x_x1000 / 1000.0


## Экранный y для расстояния до Стены ×1000.
func field_y(y_x1000: int, field_length_x1000: int) -> float:
	var t: float = clampf(float(y_x1000) / maxf(1.0, float(field_length_x1000)), 0.0, 1.0)
	return wall_top - (wall_top - field_top) * t


func field_pos(x_x1000: int, y_x1000: int, field_length_x1000: int) -> Vector2:
	return Vector2(lane_x(x_x1000), field_y(y_x1000, field_length_x1000))


func field_rect() -> Rect2:
	return Rect2(Vector2(0.0, field_top), Vector2(WIDTH, wall_top - field_top))


## Центр поля боя — туда ставим кнопку «В бой!» и окна итога.
func field_center() -> Vector2:
	return field_rect().get_center()


## Полоса здоровья босса — над воротами, по ширине сетки.
func boss_bar_rect() -> Rect2:
	var w: float = CELL * SimGrid.WIDTH
	return Rect2(
		Vector2(grid_origin.x, wall_top - 16.0 - BOSS_BAR_HEIGHT), Vector2(w, BOSS_BAR_HEIGHT)
	)


func fight_rect() -> Rect2:
	return Rect2(field_center() - FIGHT_SIZE * 0.5, FIGHT_SIZE)


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
	var total: float = SLOTS_SHOWN * SLOT_SIZE + (SLOTS_SHOWN - 1) * SLOT_GAP
	var left: float = (WIDTH - total) * 0.5
	return Rect2(
		Vector2(left + index * (SLOT_SIZE + SLOT_GAP), slot_y), Vector2(SLOT_SIZE, SLOT_SIZE)
	)


## Слот запаса под точкой экрана; -1, если мимо.
func slot_at(pos: Vector2) -> int:
	for i: int in SLOTS_SHOWN:
		if slot_rect(i).has_point(pos):
			return i
	return -1


func buy_rect() -> Rect2:
	var pos: Vector2 = Vector2((WIDTH - BUY_SIZE.x) * 0.5, height - BOTTOM_MARGIN - BUY_SIZE.y)
	return Rect2(pos, BUY_SIZE)


## Круглые кнопки слева под верхней панелью: 0 — пауза, 1 — скорость ×2.
func side_button_rect(index: int) -> Rect2:
	var y: float = field_top + 10.0 + index * (SIDE_BUTTON + SIDE_GAP)
	return Rect2(Vector2(SIDE_MARGIN, y), Vector2(SIDE_BUTTON, SIDE_BUTTON))

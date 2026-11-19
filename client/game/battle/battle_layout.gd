class_name BattleLayout
extends RefCounted
## Раскладка экрана боя 1080×1920: поле сверху, Стена, сетка 7×5, конвейер внизу.
## Переводит координаты симуляции в экранные и обратно.

const SCREEN: Vector2 = Vector2(1080, 1920)
const HUD_HEIGHT: float = 110.0
const FIELD_TOP: float = 130.0
const WALL_TOP: float = 980.0
const WALL_BOTTOM: float = 1040.0
const CELL: float = 130.0
const GRID_ORIGIN: Vector2 = Vector2(85, 1070)
const SLOT_SIZE: float = 150.0
const SLOT_GAP: float = 30.0
const SLOT_Y: float = 1745.0
const SLOTS_SHOWN: int = 4


## Экранный x для координаты поля ×1000 (совпадает с центрами колонок сетки).
static func lane_x(x_x1000: int) -> float:
	return GRID_ORIGIN.x + CELL * 0.5 + CELL * x_x1000 / 1000.0


## Экранный y для расстояния до Стены ×1000.
static func field_y(y_x1000: int, field_length_x1000: int) -> float:
	var t: float = clampf(float(y_x1000) / maxf(1.0, float(field_length_x1000)), 0.0, 1.0)
	return WALL_TOP - (WALL_TOP - FIELD_TOP) * t


static func field_pos(x_x1000: int, y_x1000: int, field_length_x1000: int) -> Vector2:
	return Vector2(lane_x(x_x1000), field_y(y_x1000, field_length_x1000))


static func cell_rect(x: int, y: int) -> Rect2:
	return Rect2(GRID_ORIGIN + Vector2(x * CELL, y * CELL), Vector2(CELL, CELL))


static func cell_center(x: int, y: int) -> Vector2:
	return cell_rect(x, y).get_center()


## Клетка сетки под точкой экрана; (-1, -1), если мимо.
static func cell_at(pos: Vector2) -> Vector2i:
	var local: Vector2 = pos - GRID_ORIGIN
	if local.x < 0.0 or local.y < 0.0:
		return Vector2i(-1, -1)
	var x: int = int(local.x / CELL)
	var y: int = int(local.y / CELL)
	if not SimGrid.in_bounds(x, y):
		return Vector2i(-1, -1)
	return Vector2i(x, y)


static func slot_rect(index: int) -> Rect2:
	var total: float = SLOTS_SHOWN * SLOT_SIZE + (SLOTS_SHOWN - 1) * SLOT_GAP
	var left: float = (SCREEN.x - total) * 0.5
	return Rect2(
		Vector2(left + index * (SLOT_SIZE + SLOT_GAP), SLOT_Y), Vector2(SLOT_SIZE, SLOT_SIZE)
	)


## Слот конвейера под точкой экрана; -1, если мимо.
static func slot_at(pos: Vector2) -> int:
	for i: int in SLOTS_SHOWN:
		if slot_rect(i).has_point(pos):
			return i
	return -1

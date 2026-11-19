class_name PowerSystem
extends RefCounted
## Привод (core-rules §3): обход в ширину от Сердца, направление по шахматке,
## нагрузка L, коэффициент k = min(1000, P*1000/L), rpm = heart_rpm * k * size * (1000 + bonus).
## Вызывается только когда сетка или Реверс изменились.

## Единиц фазы в одном обороте: при rpm_x1000 единиц за тик ровно rpm оборотов за минуту
## (60 с × 30 тиков × 1000).
const REV_UNITS: int = 1_800_000
## Порядок соседей фиксирован: вверх, влево, вправо, вниз.
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)
]


## Направление клетки: ↻, если чётность (x + y) совпадает с чётностью Сердца; Реверс меняет всё.
static func is_clockwise_cell(x: int, y: int, reversed: bool) -> bool:
	var same_parity: bool = (x + y) % 2 == (SimGrid.HEART_X + SimGrid.HEART_Y) % 2
	return same_parity != reversed


## Коэффициент мощности k ×1000.
static func power_factor(power: int, load: int) -> int:
	if load <= 0:
		return Fixed.ONE
	return mini(Fixed.ONE, power * Fixed.ONE / load)


## Пересчитывает подключение, направление и rpm всех шестерней. Возвращает нагрузку L.
static func recompute(
	grid: SimGrid, data: SimData, power: int, reversed: bool, bonus_x1000: int = 0
) -> int:
	for g: SimGear in grid.gears:
		g.connected = false
		g.clockwise = is_clockwise_cell(g.x, g.y, reversed)
		g.rpm_x1000 = 0
	var load: int = _mark_connected(grid)
	var k: int = power_factor(power, load)
	var heart_rpm: int = data.run_value("heart_rpm")
	for g: SimGear in grid.gears:
		if not g.connected:
			continue
		var rpm: int = heart_rpm * k
		rpm = rpm * data.level_size(g.level) / Fixed.ONE
		rpm = rpm * (Fixed.ONE + bonus_x1000) / Fixed.ONE
		g.rpm_x1000 = rpm
	return load


static func _mark_connected(grid: SimGrid) -> int:
	var queue: Array[Vector2i] = [Vector2i(SimGrid.HEART_X, SimGrid.HEART_Y)]
	var head: int = 0
	var count: int = 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		for d: Vector2i in NEIGHBORS:
			var g: SimGear = grid.gear_at(cur.x + d.x, cur.y + d.y)
			if g == null or g.connected:
				continue
			g.connected = true
			count += 1
			queue.append(Vector2i(g.x, g.y))
	return count

class_name SimBot
extends RefCounted
## Простой бот-игрок для симулятора баланса и тестов: покупает шестерни, когда хватает гаек,
## ставит их из запаса, сливает одинаковые, запускает волну, когда запас пуст, и жмёт Реверс,
## когда у Стены толпа. Действует только через входы журнала — как настоящий игрок.

const THINK_EVERY_TICKS: int = 10
const CROWD_RANGE_X1000: int = 2500
const CROWD_SIZE: int = 3

var use_reverse: bool = true


## Играет забег до конца и возвращает журнал с client_result.
func play(data: SimData, seed_value: int, max_ticks: int = RunLog.MAX_TICKS) -> RunLog:
	var run_log: RunLog = RunLog.new()
	run_log.seed_value = seed_value
	run_log.run_id = "bot-%d" % seed_value
	var sim: BattleSim = BattleSim.new(data, seed_value)
	while not sim.is_over() and sim.tick < max_ticks:
		if sim.tick % THINK_EVERY_TICKS == 0:
			for action: Array in decide(sim):
				var name: String = action[0]
				var args: Dictionary = action[1]
				if sim.apply_input(name, args):
					run_log.record(sim.tick, name, args)
		sim.advance()
	run_log.client_result = sim.result()
	return run_log


## Решения на текущий тик: список [action, args]. Состояние не меняет.
func decide(sim: BattleSim) -> Array[Array]:
	var actions: Array[Array] = []
	var planned: Dictionary = {}
	for slot: int in range(sim.stock.size() - 1, -1, -1):
		var item: BattleSim.StockItem = sim.stock[slot]
		var cell: Vector2i = _merge_target(sim, item, planned)
		if cell.x < 0:
			cell = _free_cell(sim, planned)
		if cell.x < 0:
			continue
		planned[cell] = true
		actions.append(["place", {"slot": slot, "x": cell.x, "y": cell.y}])
	if sim.can_buy():
		actions.append(["buy", {}])
	if use_reverse and sim.phase == BattleSim.Phase.WAVE and sim.reverse_cooldown == 0:
		if _crowd_at_wall(sim) >= CROWD_SIZE:
			actions.append(["reverse", {}])
	if sim.phase == BattleSim.Phase.PAUSE and actions.is_empty():
		actions.append(["next_wave", {}])
	return actions


func _merge_target(sim: BattleSim, item: BattleSim.StockItem, planned: Dictionary) -> Vector2i:
	for g: SimGear in sim.grid.gears:
		var cell: Vector2i = Vector2i(g.x, g.y)
		if planned.has(cell):
			continue
		if g.type == item.type and g.level == item.level and g.level < sim.data.max_level():
			return cell
	return Vector2i(-1, -1)


## Свободная клетка рядом с Сердцем или подключённой шестернёй, ближе к Сердцу.
func _free_cell(sim: BattleSim, planned: Dictionary) -> Vector2i:
	var best: Vector2i = Vector2i(-1, -1)
	var best_dist: int = 1 << 30
	for y: int in SimGrid.HEIGHT:
		for x: int in SimGrid.WIDTH:
			var cell: Vector2i = Vector2i(x, y)
			if not sim.grid.is_free(x, y) or planned.has(cell):
				continue
			if not _touches_powered(sim, x, y):
				continue
			var dist: int = absi(x - SimGrid.HEART_X) + absi(y - SimGrid.HEART_Y)
			if dist < best_dist:
				best_dist = dist
				best = cell
	return best


func _touches_powered(sim: BattleSim, x: int, y: int) -> bool:
	for d: Vector2i in PowerSystem.NEIGHBORS:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if SimGrid.is_heart(nx, ny):
			return true
		var g: SimGear = sim.grid.gear_at(nx, ny)
		if g != null and g.connected:
			return true
	return false


func _crowd_at_wall(sim: BattleSim) -> int:
	var count: int = 0
	for m: SimMonster in sim.monsters:
		if m.y <= CROWD_RANGE_X1000:
			count += 1
	return count

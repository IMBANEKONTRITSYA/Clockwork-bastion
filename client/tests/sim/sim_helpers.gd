class_name SimTestHelpers
extends RefCounted
## Помощники для тестов симуляции: явная сборка состояния.

const SEED: int = 123456789


static func new_sim(seed_value: int = SEED) -> BattleSim:
	return BattleSim.new(SimData.load_default(), seed_value)


## Ставит шестерню напрямую в сетку (минуя конвейер) — для проверки механик.
static func put_gear(sim: BattleSim, type: String, level: int, x: int, y: int) -> SimGear:
	var g: SimGear = SimGear.create(1000 + sim.grid.gears.size(), type, level, x, y)
	sim.grid.place(g)
	sim.mark_grid_changed()
	return g


## Монстр в заданной точке поля (координаты ×1000).
static func put_monster(
	sim: BattleSim, type: String, x: int, y: int, hp: int = 1_000_000
) -> SimMonster:
	var m: SimMonster = SimMonster.new()
	m.id = 5000 + sim.monsters.size()
	m.type = type
	m.hp = hp
	m.max_hp = hp
	m.x = x
	m.base_x = x
	m.y = y
	sim.monsters.append(m)
	return m


static func run_ticks(sim: BattleSim, n: int) -> void:
	for i: int in n:
		sim.advance()

class_name SimData
extends RefCounted
## Данные баланса для симуляции: собираются один раз из BalanceTable (make data).
## Порядок шестерней и монстров — как в CSV: он входит в протокол (выбор через SimRng).

const DATA_DIR: String = "res://data"

var gears: Array[SimSpecs.Gear] = []
var monsters: Array[SimSpecs.Monster] = []

var _run: BalanceTable
var _levels: BalanceTable
var _waves: BalanceTable


static func load_default() -> SimData:
	return (
		SimData
		. from_tables(
			_load_table("run"),
			_load_table("level_scaling"),
			_load_table("wave_scaling"),
			_load_table("gears"),
			_load_table("monsters"),
		)
	)


static func from_tables(
	run: BalanceTable,
	levels: BalanceTable,
	waves: BalanceTable,
	gear_table: BalanceTable,
	monster_table: BalanceTable,
) -> SimData:
	var data: SimData = SimData.new()
	data._run = run
	data._levels = levels
	data._waves = waves
	for id: String in gear_table.get_ids():
		data.gears.append(_gear_from_row(gear_table, id))
	for id: String in monster_table.get_ids():
		data.monsters.append(_monster_from_row(monster_table, id))
	return data


## Параметр забега из run.csv.
func run_value(key: String) -> int:
	return _run.get_int(key, "value")


func max_level() -> int:
	return run_value("max_gear_level")


## Размер (множитель скорости) шестерни уровня 1..5, ×1000.
func level_size(level: int) -> int:
	return _levels.get_int(str(level), "size_x1000")


## Множитель урона шестерни уровня 1..5, ×1000.
func level_dmg_mul(level: int) -> int:
	return _levels.get_int(str(level), "dmg_mul_x1000")


## Множитель здоровья монстров на волне w (после конца таблицы — последнее значение), ×1000.
func wave_hp_mul(wave: int) -> int:
	var last: int = _waves.rows.size()
	var w: int = Fixed.clamp_int(wave, 1, last)
	return _waves.get_int(str(w), "hp_mul_x1000")


func gear(id: String) -> SimSpecs.Gear:
	for g: SimSpecs.Gear in gears:
		if g.id == id:
			return g
	assert(false, "SimData: нет шестерни '%s'" % id)
	return null


func monster(id: String) -> SimSpecs.Monster:
	for m: SimSpecs.Monster in monsters:
		if m.id == id:
			return m
	assert(false, "SimData: нет монстра '%s'" % id)
	return null


static func _load_table(table_name: String) -> BalanceTable:
	var table: BalanceTable = load(DATA_DIR.path_join(table_name + ".tres")) as BalanceTable
	assert(table != null, "SimData: нет %s.tres — запусти make data" % table_name)
	return table


static func _gear_from_row(t: BalanceTable, id: String) -> SimSpecs.Gear:
	var g: SimSpecs.Gear = SimSpecs.Gear.new()
	g.id = id
	g.element = str(t.get_row(id)["element"])
	g.base_damage = t.get_int(id, "base_damage")
	g.hits_per_rev_x1000 = t.get_int(id, "hits_per_rev_x1000")
	g.shop_weight = t.get_int(id, "shop_weight")
	g.cw = _mode_from_row(t, id, "cw_")
	g.ccw = _mode_from_row(t, id, "ccw_")
	return g


static func _mode_from_row(t: BalanceTable, id: String, prefix: String) -> SimSpecs.GearMode:
	var m: SimSpecs.GearMode = SimSpecs.GearMode.new()
	m.range_x1000 = t.get_int(id, prefix + "range_x1000")
	m.reach_x1000 = t.get_int(id, prefix + "reach_x1000")
	m.targets = t.get_int(id, prefix + "targets")
	m.dmg_pct = t.get_int(id, prefix + "dmg_pct")
	m.knockback_x1000 = t.get_int(id, prefix + "knockback_x1000")
	m.slow_pct = t.get_int(id, prefix + "slow_pct")
	m.slow_ticks = t.get_int(id, prefix + "slow_ticks")
	return m


static func _monster_from_row(t: BalanceTable, id: String) -> SimSpecs.Monster:
	var m: SimSpecs.Monster = SimSpecs.Monster.new()
	m.id = id
	m.hp = t.get_int(id, "hp")
	m.speed_x1000 = t.get_int(id, "speed_x1000")
	m.cost = t.get_int(id, "cost")
	m.wall_damage = t.get_int(id, "wall_damage")
	m.nuts = t.get_int(id, "nuts")
	m.first_wave = t.get_int(id, "first_wave")
	m.zigzag_amp_x1000 = t.get_int(id, "zigzag_amp_x1000")
	m.zigzag_period_ticks = t.get_int(id, "zigzag_period_ticks")
	return m

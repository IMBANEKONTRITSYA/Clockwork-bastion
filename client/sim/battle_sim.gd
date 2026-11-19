class_name BattleSim
extends RefCounted
## Детерминированная симуляция одного забега (core-rules §2–6).
## Вход — только действия игрока через apply_input(); время — только тики advance().
## Порядок вызовов SimRng (протокол): старт конвейера → [на старте волны: состав волны]
## → [на спавне: колонка монстра] → [на поставке конвейера: тип шестерни].

enum Phase { PAUSE, WAVE, WON, LOST }

const MAX_ATTACKS_PER_TICK: int = 4
const FIELD_LANES_X1000: int = (SimGrid.WIDTH - 1) * Fixed.ONE


class ConveyorItem:
	extends RefCounted
	var type: String = ""
	var level: int = 1


class Hit:
	extends RefCounted
	var monster_id: int = 0
	var damage: int = 0
	var knockback: int = 0
	var slow_pct: int = 0
	var slow_ticks: int = 0


var data: SimData
var rng: SimRng
var grid: SimGrid = SimGrid.new()
var monsters: Array[SimMonster] = []
var conveyor: Array[ConveyorItem] = []

var tick: int = 0
var phase: Phase = Phase.PAUSE
var wave: int = 0
var waves_cleared: int = 0
var wall: int = 0
var nuts: int = 0
var kills: int = 0
var attacks: int = 0

## Удары последнего тика для отображения: (клетка x, клетка y, x монстра, y монстра).
## В хэш не входит и на ход забега не влияет.
var last_attacks: Array[Vector4i] = []

var power: int = 0
var gear_load: int = 0
var reversed: bool = false
var reverse_stop: int = 0
var reverse_cooldown: int = 0
var spin_ticks: int = 0
var pause_timer: int = 0
var conveyor_timer: int = 0

var _spawn_queue: Array[String] = []
var _spawn_timer: int = 0
var _next_gear_id: int = 1
var _next_monster_id: int = 1
var _power_dirty: bool = true
var _hits: Array[Hit] = []


func _init(sim_data: SimData, seed_value: int) -> void:
	data = sim_data
	rng = SimRng.new(seed_value)
	wall = data.run_value("wall_hp")
	power = data.run_value("heart_power")
	pause_timer = data.run_value("wave_pause_ticks")
	for i: int in data.run_value("conveyor_start_items"):
		conveyor.append(_roll_conveyor_item())


func is_over() -> bool:
	return phase == Phase.WON or phase == Phase.LOST


func outcome() -> String:
	match phase:
		Phase.WON:
			return "won"
		Phase.LOST:
			return "lost"
	return "running"


## Итог забега в формате client_result журнала (core-rules §8).
func result() -> Dictionary:
	return {"waves": waves_cleared, "wall": wall, "kills": kills, "outcome": outcome()}


## Применяет действие игрока. Недопустимое действие ничего не меняет и возвращает false.
func apply_input(action: String, args: Dictionary) -> bool:
	if is_over():
		return false
	match action:
		"place":
			return _input_place(args)
		"move":
			return _input_move(args)
		"reverse":
			return _input_reverse()
		"next_wave":
			return _input_next_wave()
	return false


## Один тик симуляции; входы этого тика уже применены через apply_input().
func advance() -> void:
	if is_over():
		return
	last_attacks.clear()
	if _power_dirty:
		gear_load = PowerSystem.recompute(grid, data, power, reversed)
		_power_dirty = false
	if phase == Phase.WAVE:
		_step_gears()
		_step_monsters()
		_apply_hits()
	_step_director()
	_step_timers()
	tick += 1


## Множитель раскрутки ×1000: 0 во время остановки Реверса, затем линейно до 1000.
func spin_factor() -> int:
	if reverse_stop > 0:
		return 0
	return mini(Fixed.ONE, spin_ticks * Fixed.ONE / data.run_value("spinup_ticks"))


## Только для тестов: волна без монстров в очереди.
func _clear_spawn_queue() -> void:
	_spawn_queue.clear()


## Сетка изменена не через входы (тесты, события): пересчитать привод на следующем тике.
func mark_grid_changed() -> void:
	_power_dirty = true


func monster_by_id(monster_id: int) -> SimMonster:
	for m: SimMonster in monsters:
		if m.id == monster_id:
			return m
	return null


## Хэш всего состояния, влияющего на дальнейший ход забега.
func state_hash() -> String:
	var h: SimHash = SimHash.new()
	h.add_int(SimVersion.SIM_VERSION)
	for v: int in [tick, phase, wave, waves_cleared, wall, nuts, kills, attacks]:
		h.add_int(v)
	for v: int in [power, gear_load, reverse_stop, reverse_cooldown, spin_ticks, pause_timer]:
		h.add_int(v)
	h.add_int(conveyor_timer)
	h.add_bool(reversed)
	h.add_int(rng.get_state())
	for g: SimGear in grid.gears:
		h.add_int(g.id)
		h.add_string(g.type)
		for v: int in [g.level, g.x, g.y, g.phase, g.rpm_x1000]:
			h.add_int(v)
	for m: SimMonster in monsters:
		h.add_int(m.id)
		h.add_string(m.type)
		for v: int in [m.hp, m.x, m.y, m.age, m.slow_pct, m.slow_ticks]:
			h.add_int(v)
		h.add_bool(m.breached)
	for item: ConveyorItem in conveyor:
		h.add_string(item.type)
		h.add_int(item.level)
	for id: String in _spawn_queue:
		h.add_string(id)
	return h.hex()


# --- Входы ---


func _input_place(args: Dictionary) -> bool:
	var slot: int = _arg_int(args, "slot")
	var x: int = _arg_int(args, "x")
	var y: int = _arg_int(args, "y")
	if slot < 0 or slot >= conveyor.size():
		return false
	var item: ConveyorItem = conveyor[slot]
	if grid.is_free(x, y):
		grid.place(SimGear.create(_next_gear_id, item.type, item.level, x, y))
		_next_gear_id += 1
	elif not _merge_into(grid.gear_at(x, y), item.type, item.level):
		return false
	conveyor.remove_at(slot)
	_power_dirty = true
	return true


func _input_move(args: Dictionary) -> bool:
	var from: SimGear = grid.gear_at(_arg_int(args, "from_x"), _arg_int(args, "from_y"))
	var x: int = _arg_int(args, "x")
	var y: int = _arg_int(args, "y")
	if from == null:
		return false
	if grid.is_free(x, y):
		grid.move(from.id, x, y)
	else:
		var target: SimGear = grid.gear_at(x, y)
		if target == null or target.id == from.id:
			return false
		if not _merge_into(target, from.type, from.level):
			return false
		grid.remove(from.id)
	_power_dirty = true
	return true


func _input_reverse() -> bool:
	if reverse_cooldown > 0:
		return false
	reversed = not reversed
	reverse_stop = data.run_value("reverse_stop_ticks")
	reverse_cooldown = data.run_value("reverse_cooldown_ticks")
	spin_ticks = 0
	_power_dirty = true
	return true


func _input_next_wave() -> bool:
	if phase != Phase.PAUSE:
		return false
	_start_wave()
	return true


## Мерж: шестерня того же типа и уровня поднимает уровень цели на 1 (не выше максимума).
func _merge_into(target: SimGear, type: String, level: int) -> bool:
	if target == null or target.type != type or target.level != level:
		return false
	if target.level >= data.max_level():
		return false
	target.level += 1
	return true


# --- Тик ---


func _step_gears() -> void:
	var spin: int = spin_factor()
	if reverse_stop > 0:
		reverse_stop -= 1
	else:
		spin_ticks += 1
	if spin == 0:
		return
	for g: SimGear in grid.gears:
		if not g.connected:
			continue
		var spec: SimSpecs.Gear = data.gear(g.type)
		if spec.hits_per_rev_x1000 <= 0:
			continue
		var interval: int = PowerSystem.REV_UNITS * Fixed.ONE / spec.hits_per_rev_x1000
		g.phase += g.rpm_x1000 * spin / Fixed.ONE
		var done: int = 0
		while g.phase >= interval and done < MAX_ATTACKS_PER_TICK:
			g.phase -= interval
			_attack(g, spec)
			done += 1


func _attack(g: SimGear, spec: SimSpecs.Gear) -> void:
	attacks += 1
	var mode: SimSpecs.GearMode = spec.mode(g.clockwise)
	var damage: int = spec.base_damage * data.level_dmg_mul(g.level)
	damage = damage * mode.dmg_pct / Fixed.ONE
	for m: SimMonster in _pick_targets(g.x * Fixed.ONE, mode):
		var hit: Hit = Hit.new()
		hit.monster_id = m.id
		hit.damage = damage
		hit.knockback = mode.knockback_x1000
		hit.slow_pct = mode.slow_pct
		hit.slow_ticks = mode.slow_ticks
		_hits.append(hit)
		last_attacks.append(Vector4i(g.x, g.y, m.x, m.y))


## Цели: живые монстры в зоне режима, ближайшие к Стене (при равенстве — меньший id).
func _pick_targets(lane_x: int, mode: SimSpecs.GearMode) -> Array[SimMonster]:
	var candidates: Array[SimMonster] = []
	for m: SimMonster in monsters:
		if m.is_alive() and m.y <= mode.range_x1000 and absi(m.x - lane_x) <= mode.reach_x1000:
			candidates.append(m)
	candidates.sort_custom(_closer_to_wall)
	if candidates.size() > mode.targets:
		candidates.resize(mode.targets)
	return candidates


static func _closer_to_wall(a: SimMonster, b: SimMonster) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.id < b.id


func _step_monsters() -> void:
	var tps: int = data.run_value("ticks_per_second")
	for m: SimMonster in monsters:
		if not m.is_alive():
			continue
		var spec: SimSpecs.Monster = data.monster(m.type)
		if m.slow_ticks > 0:
			m.slow_ticks -= 1
			if m.slow_ticks == 0:
				m.slow_pct = 0
		m.age += 1
		var speed: int = spec.speed_x1000 * (Fixed.ONE - m.slow_pct) / Fixed.ONE
		m.y -= speed / tps
		var offset: int = SimMonster.zigzag_offset(
			spec.zigzag_amp_x1000, spec.zigzag_period_ticks, m.age
		)
		m.x = Fixed.clamp_int(m.base_x + offset, 0, FIELD_LANES_X1000)
		if m.y <= 0:
			m.y = 0
			m.breached = true
			wall -= spec.wall_damage
	if wall <= 0:
		wall = 0
		phase = Phase.LOST


func _apply_hits() -> void:
	var field_length: int = data.run_value("field_length_x1000")
	for hit: Hit in _hits:
		var m: SimMonster = monster_by_id(hit.monster_id)
		if m == null or not m.is_alive():
			continue
		m.hp -= hit.damage
		if hit.knockback > 0:
			m.y = mini(field_length, m.y + hit.knockback)
		if hit.slow_pct > m.slow_pct:
			m.slow_pct = hit.slow_pct
		if hit.slow_ticks > m.slow_ticks:
			m.slow_ticks = hit.slow_ticks
	_hits.clear()
	var alive: Array[SimMonster] = []
	for m: SimMonster in monsters:
		if m.is_alive():
			alive.append(m)
		elif not m.breached:
			kills += 1
			nuts += data.monster(m.type).nuts
	monsters = alive


func _step_director() -> void:
	if phase == Phase.PAUSE:
		pause_timer -= 1
		if pause_timer <= 0:
			_start_wave()
		return
	if phase != Phase.WAVE:
		return
	if not _spawn_queue.is_empty():
		_spawn_timer -= 1
		if _spawn_timer <= 0:
			var next_type: String = _spawn_queue.pop_front()
			_spawn(next_type)
			_spawn_timer = data.run_value("wave_spawn_interval_ticks")
	elif monsters.is_empty():
		_finish_wave()


func _step_timers() -> void:
	if reverse_cooldown > 0:
		reverse_cooldown -= 1
	if phase != Phase.WAVE:
		return
	conveyor_timer += 1
	if conveyor_timer >= data.run_value("conveyor_interval_ticks"):
		conveyor_timer = 0
		_deliver_conveyor_item()


func _start_wave() -> void:
	wave += 1
	phase = Phase.WAVE
	_spawn_queue = WaveDirector.compose(data, rng, wave)
	_spawn_timer = 0
	spin_ticks = 0
	conveyor_timer = 0


func _finish_wave() -> void:
	waves_cleared = wave
	if wave >= data.run_value("waves_total"):
		phase = Phase.WON
		return
	phase = Phase.PAUSE
	pause_timer = data.run_value("wave_pause_ticks")


func _spawn(type: String) -> void:
	var spec: SimSpecs.Monster = data.monster(type)
	var m: SimMonster = SimMonster.new()
	m.id = _next_monster_id
	_next_monster_id += 1
	m.type = type
	m.max_hp = WaveDirector.monster_hp(data, spec, wave)
	m.hp = m.max_hp
	m.base_x = rng.next_range(0, SimGrid.WIDTH) * Fixed.ONE
	m.x = m.base_x
	m.y = data.run_value("field_length_x1000")
	monsters.append(m)


func _deliver_conveyor_item() -> void:
	if conveyor.size() >= data.run_value("conveyor_slots"):
		conveyor.remove_at(0)
		nuts += data.run_value("conveyor_overflow_nuts")
	conveyor.append(_roll_conveyor_item())


func _roll_conveyor_item() -> ConveyorItem:
	var total: int = 0
	for g: SimSpecs.Gear in data.gears:
		total += g.conveyor_weight
	var roll: int = rng.next_range(0, total)
	var item: ConveyorItem = ConveyorItem.new()
	for g: SimSpecs.Gear in data.gears:
		if roll < g.conveyor_weight:
			item.type = g.id
			break
		roll -= g.conveyor_weight
	return item


## Целое из аргументов журнала. JSON отдаёт числа дробными — приводим к int; мусор → -1.
static func _arg_int(args: Dictionary, key: String) -> int:
	return Fixed.int_of(args.get(key, -1))

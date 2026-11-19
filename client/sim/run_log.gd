class_name RunLog
extends RefCounted
## Журнал забега (core-rules §8): зерно + входы [tick, action, args].
## Одинаковый журнал даёт одинаковый результат и хэш в клиенте и в валидаторе.

## Предел длины забега: 60 минут игрового времени. Защита от бесконечного пересчёта.
const MAX_TICKS: int = 108_000
const MAX_INPUTS: int = 20_000

var run_id: String = ""
var seed_value: int = 0
var chapter: int = 1
var sim_version: int = SimVersion.SIM_VERSION
var squad: Array[String] = []
var loadout_hash: String = ""
## Каждый элемент — [tick: int, action: String, args: Dictionary].
var inputs: Array = []
var client_result: Dictionary = {}


## Добавляет вход, записанный во время игры.
func record(at_tick: int, action: String, args: Dictionary) -> void:
	inputs.append([at_tick, action, args])


func to_dict() -> Dictionary:
	return {
		"run_id": run_id,
		"seed": seed_value,
		"chapter": chapter,
		"sim_version": sim_version,
		"squad": squad,
		"loadout_hash": loadout_hash,
		"inputs": inputs,
		"client_result": client_result,
	}


## Разбор журнала из JSON-словаря. Неверный формат — null.
static func from_dict(d: Dictionary) -> RunLog:
	var run_log: RunLog = RunLog.new()
	var seed_raw: Variant = d.get("seed")
	if not (seed_raw is int or seed_raw is float):
		return null
	run_log.seed_value = int(seed_raw)
	run_log.run_id = str(d.get("run_id", ""))
	run_log.chapter = int(d.get("chapter", 1))
	run_log.sim_version = int(d.get("sim_version", SimVersion.SIM_VERSION))
	run_log.loadout_hash = str(d.get("loadout_hash", ""))
	var squad_raw: Variant = d.get("squad", [])
	if squad_raw is Array:
		var squad_list: Array = squad_raw
		for s: Variant in squad_list:
			run_log.squad.append(str(s))
	var inputs_raw: Variant = d.get("inputs", [])
	if not inputs_raw is Array:
		return null
	var input_list: Array = inputs_raw
	if input_list.size() > MAX_INPUTS:
		return null
	for entry: Variant in input_list:
		if not entry is Array:
			return null
		var e: Array = entry
		if e.size() != 3 or not (e[0] is int or e[0] is float) or not e[1] is String:
			return null
		var args: Dictionary = e[2] if e[2] is Dictionary else {}
		run_log.inputs.append([int(e[0]), str(e[1]), args])
	var result_raw: Variant = d.get("client_result", {})
	if result_raw is Dictionary:
		run_log.client_result = result_raw
	return run_log


## Пересчитывает забег по журналу до конца (победа, поражение или MAX_TICKS).
## Входы с тиком меньше текущего (нарушен порядок) отбрасываются.
static func replay(run_log: RunLog, data: SimData) -> BattleSim:
	var sim: BattleSim = BattleSim.new(data, run_log.seed_value)
	var i: int = 0
	while not sim.is_over() and sim.tick < MAX_TICKS:
		while i < run_log.inputs.size():
			var e: Array = run_log.inputs[i]
			var at: int = e[0]
			if at > sim.tick:
				break
			if at == sim.tick:
				var action: String = e[1]
				var args: Dictionary = e[2]
				sim.apply_input(action, args)
			i += 1
		sim.advance()
	return sim

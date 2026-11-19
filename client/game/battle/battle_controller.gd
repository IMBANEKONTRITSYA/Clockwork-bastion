class_name BattleController
extends RefCounted
## Ведёт симуляцию в реальном времени: 30 тиков в секунду (×2 при ускорении),
## записывает входы игрока в журнал на тот тик, перед которым они применены.
## Логики боя здесь нет — только время и журнал.

signal finished(result: Dictionary)

const MAX_STEPS_PER_FRAME: int = 8

var sim: BattleSim
var run_log: RunLog = RunLog.new()
var speed: int = 1

var _acc: float = 0.0
var _tps: int = 30
var _finished_sent: bool = false


func _init(data: SimData, seed_value: int) -> void:
	sim = BattleSim.new(data, seed_value)
	run_log.seed_value = seed_value
	_tps = data.run_value("ticks_per_second")


## Действие игрока: применяется к текущему тику и записывается в журнал.
func submit(action: String, args: Dictionary = {}) -> bool:
	if not sim.apply_input(action, args):
		return false
	run_log.record(sim.tick, action, args)
	return true


## Продвигает время на delta секунд. Возвращает число сделанных тиков.
func update(delta: float) -> int:
	if sim.is_over():
		return 0
	_acc += delta * _tps * speed
	var steps: int = 0
	while _acc >= 1.0 and steps < MAX_STEPS_PER_FRAME * speed:
		sim.advance()
		_acc -= 1.0
		steps += 1
		if sim.is_over():
			_finish()
			break
	if _acc > 1.0:
		_acc = 1.0
	return steps


## Доля пути к следующему тику — для плавной отрисовки между тиками.
func alpha() -> float:
	return clampf(_acc, 0.0, 1.0)


func toggle_speed() -> void:
	speed = 2 if speed == 1 else 1


func _finish() -> void:
	if _finished_sent:
		return
	_finished_sent = true
	_acc = 0.0
	run_log.client_result = sim.result()
	finished.emit(run_log.client_result)

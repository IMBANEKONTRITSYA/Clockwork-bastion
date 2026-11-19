class_name BattleHudModel
extends RefCounted
## Что показывает HUD — собрано из состояния симуляции. Тексты — ключи локализации.

enum Overlay { NONE, PAUSE, WON, LOST }

var wave: int = 0
var waves_total: int = 0
var nuts: int = 0
var wall: int = 0
var wall_max: int = 0
var gear_load: int = 0
var power: int = 0
var overloaded: bool = false
## Готовность Реверса ×1000: 1000 — можно жать.
var reverse_ready: int = 0
var reverse_seconds_left: int = 0
var overlay: Overlay = Overlay.NONE
var pause_seconds_left: int = 0


static func from_sim(sim: BattleSim) -> BattleHudModel:
	var m: BattleHudModel = BattleHudModel.new()
	var tps: int = sim.data.run_value("ticks_per_second")
	m.wave = sim.wave
	m.waves_total = sim.data.run_value("waves_total")
	m.nuts = sim.nuts
	m.wall = sim.wall
	m.wall_max = sim.data.run_value("wall_hp")
	m.gear_load = sim.gear_load
	m.power = sim.power
	m.overloaded = sim.gear_load > sim.power
	var cooldown_total: int = sim.data.run_value("reverse_cooldown_ticks")
	m.reverse_ready = 1000 - sim.reverse_cooldown * 1000 / maxi(1, cooldown_total)
	m.reverse_seconds_left = (sim.reverse_cooldown + tps - 1) / tps
	match sim.phase:
		BattleSim.Phase.PAUSE:
			m.overlay = Overlay.PAUSE
			m.pause_seconds_left = (sim.pause_timer + tps - 1) / tps
		BattleSim.Phase.WON:
			m.overlay = Overlay.WON
		BattleSim.Phase.LOST:
			m.overlay = Overlay.LOST
	return m

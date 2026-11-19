extends GutTest
## Модель HUD из состояния симуляции: числа, оверлей, готовность Реверса.


func _sim() -> BattleSim:
	return BattleSim.new(SimData.load_default(), 3)


func test_start_of_run_shows_pause_with_15_seconds() -> void:
	var m: BattleHudModel = BattleHudModel.from_sim(_sim())
	assert_eq(m.overlay, BattleHudModel.Overlay.PAUSE)
	assert_eq(m.pause_seconds_left, 15)
	assert_eq(m.wall, 100)
	assert_eq(m.wall_max, 100)
	assert_eq(m.waves_total, 10)
	assert_eq(m.reverse_ready, 1000)
	assert_eq(m.price, 6)
	assert_true(m.can_buy)


func test_buy_disabled_without_nuts() -> void:
	var sim: BattleSim = _sim()
	sim.nuts = 0
	assert_false(BattleHudModel.from_sim(sim).can_buy)


func test_wave_hides_overlay() -> void:
	var sim: BattleSim = _sim()
	sim.apply_input("next_wave", {})
	var m: BattleHudModel = BattleHudModel.from_sim(sim)
	assert_eq(m.overlay, BattleHudModel.Overlay.NONE)
	assert_eq(m.wave, 1)


func test_reverse_cooldown_shows_seconds_left() -> void:
	var sim: BattleSim = _sim()
	sim.apply_input("reverse", {})
	var m: BattleHudModel = BattleHudModel.from_sim(sim)
	assert_eq(m.reverse_ready, 0)
	assert_eq(m.reverse_seconds_left, 20)


func test_overload_is_flagged() -> void:
	var sim: BattleSim = _sim()
	sim.gear_load = 9
	assert_true(BattleHudModel.from_sim(sim).overloaded)


func test_lost_and_won_overlays() -> void:
	var sim: BattleSim = _sim()
	sim.phase = BattleSim.Phase.LOST
	assert_eq(BattleHudModel.from_sim(sim).overlay, BattleHudModel.Overlay.LOST)
	sim.phase = BattleSim.Phase.WON
	assert_eq(BattleHudModel.from_sim(sim).overlay, BattleHudModel.Overlay.WON)

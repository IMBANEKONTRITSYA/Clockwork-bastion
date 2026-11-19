extends GutTest
## Директор волн: бюджет 10 + 4w, доступность монстров по волне, детерминизм состава.


func _cost(data: SimData, ids: Array[String]) -> int:
	var total: int = 0
	for id: String in ids:
		total += data.monster(id).cost
	return total


func test_wave_1_spends_whole_budget_on_rustlings_only() -> void:
	var data: SimData = SimData.load_default()
	var ids: Array[String] = WaveDirector.compose(data, SimRng.new(1), 1)
	assert_eq(ids.size(), 14)
	for id: String in ids:
		assert_eq(id, "rustling", "Скрипун появляется с 3-й волны")


func test_wave_budget_is_10_plus_4w() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(_cost(data, WaveDirector.compose(data, SimRng.new(7), 5)), 30)


func test_same_seed_gives_same_wave() -> void:
	var data: SimData = SimData.load_default()
	var a: Array[String] = WaveDirector.compose(data, SimRng.new(42), 6)
	var b: Array[String] = WaveDirector.compose(data, SimRng.new(42), 6)
	assert_eq(a, b)
	assert_true(a.has("squeaker") or a.has("rustling"))


func test_monster_hp_scales_with_wave() -> void:
	var data: SimData = SimData.load_default()
	var spec: SimSpecs.Monster = data.monster("rustling")
	assert_eq(WaveDirector.monster_hp(data, spec, 1), 30_000)
	assert_eq(WaveDirector.monster_hp(data, spec, 10), 90_120)


func test_wave_starts_after_pause_and_spawns_every_20_ticks() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	SimTestHelpers.run_ticks(sim, 449)
	assert_eq(sim.phase, BattleSim.Phase.PAUSE)
	sim.advance()
	assert_eq(sim.phase, BattleSim.Phase.WAVE)
	assert_eq(sim.wave, 1)
	sim.advance()
	assert_eq(sim.monsters.size(), 1)
	SimTestHelpers.run_ticks(sim, 20)
	assert_eq(sim.monsters.size(), 2)


func test_cleared_wave_goes_to_pause_and_counts() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.apply_input("next_wave", {})
	sim.call("_clear_spawn_queue")
	sim.advance()
	assert_eq(sim.waves_cleared, 1)
	assert_eq(sim.phase, BattleSim.Phase.PAUSE)
	assert_eq(sim.pause_timer, 450)


func test_last_wave_cleared_wins() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.wave = sim.data.run_value("waves_total") - 1
	sim.apply_input("next_wave", {})
	sim.call("_clear_spawn_queue")
	sim.advance()
	assert_eq(sim.outcome(), "won")
	assert_false(sim.apply_input("reverse", {}), "после конца забега входы не принимаются")

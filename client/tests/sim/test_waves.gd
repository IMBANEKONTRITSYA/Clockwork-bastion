extends GutTest
## Волны по таблице waves.csv: не больше 15 монстров, боссы на 5 и 10 выходят последними,
## состав детерминирован зерном, здоровье растёт по таблице.


func _data() -> SimData:
	return SimData.load_default()


func _bosses_in(data: SimData, ids: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for id: String in ids:
		if data.monster(id).boss:
			out.append(id)
	return out


func test_every_wave_has_at_most_15_monsters_including_boss() -> void:
	var data: SimData = _data()
	for wave: int in range(1, data.run_value("waves_total") + 1):
		var ids: Array[String] = WaveDirector.compose(data, SimRng.new(wave), wave)
		assert_lte(ids.size(), 15, "волна %d" % wave)
		assert_eq(ids.size(), data.wave_count(wave), "волна %d" % wave)


func test_bosses_only_on_waves_5_and_10_and_come_last() -> void:
	var data: SimData = _data()
	for wave: int in range(1, data.run_value("waves_total") + 1):
		var ids: Array[String] = WaveDirector.compose(data, SimRng.new(7), wave)
		var bosses: Array[String] = _bosses_in(data, ids)
		if wave == 5:
			assert_eq(bosses, ["colossus"])
			assert_eq(ids[ids.size() - 1], "colossus")
		elif wave == 10:
			assert_eq(bosses, ["magnetron"])
			assert_eq(ids[ids.size() - 1], "magnetron")
		else:
			assert_eq(bosses.size(), 0, "волна %d без босса" % wave)


func test_wave_1_has_only_rustlings() -> void:
	var data: SimData = _data()
	for id: String in WaveDirector.compose(data, SimRng.new(1), 1):
		assert_eq(id, "rustling", "Скрипун появляется с 3-й волны")


func test_same_seed_gives_same_wave() -> void:
	var data: SimData = _data()
	var a: Array[String] = WaveDirector.compose(data, SimRng.new(42), 6)
	var b: Array[String] = WaveDirector.compose(data, SimRng.new(42), 6)
	assert_eq(a, b)


func test_monster_hp_follows_wave_table_and_scale() -> void:
	var data: SimData = _data()
	var spec: SimSpecs.Monster = data.monster("rustling")
	assert_eq(WaveDirector.monster_hp(data, spec, 1), 30_000)
	assert_eq(WaveDirector.monster_hp(data, spec, 10), 70_800)
	var harder: SimData = data.with_run_overrides({"monster_hp_scale": 2000})
	assert_eq(WaveDirector.monster_hp(harder, spec, 1), 60_000)


func test_boss_spawns_in_centre_lane() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.wave = 5
	sim.call("_spawn", "colossus")
	assert_eq(sim.monsters[0].x, SimGrid.HEART_X * 1000)
	assert_eq(sim.current_boss(), sim.monsters[0])


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

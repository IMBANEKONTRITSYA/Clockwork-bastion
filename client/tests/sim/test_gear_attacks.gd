extends GutTest
## Фаза и атаки шестерней: удары по фазе от rpm, Пильная и Паровая в обоих режимах.


func test_saw_attacks_8_times_in_first_300_ticks_with_spinup() -> void:
	# Ожидание посчитано моделью: сумма 60*min(1000, k*1000/60) по k<300 = 16_168_800 → 8 оборотов.
	var sim: BattleSim = SimTestHelpers.new_sim()
	SimTestHelpers.put_gear(sim, "saw", 1, 3, 3)
	sim.apply_input("next_wave", {})
	SimTestHelpers.run_ticks(sim, 300)
	assert_eq(sim.attacks, 8)


func test_steam_hits_four_times_per_revolution() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	SimTestHelpers.put_gear(sim, "steam", 1, 3, 3)
	sim.apply_input("next_wave", {})
	SimTestHelpers.run_ticks(sim, 300)
	assert_eq(sim.attacks, 35)


func test_disconnected_gear_does_not_attack() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	SimTestHelpers.put_gear(sim, "saw", 1, 0, 0)
	sim.apply_input("next_wave", {})
	SimTestHelpers.run_ticks(sim, 300)
	assert_eq(sim.attacks, 0)


func test_gears_do_not_attack_during_pause() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	SimTestHelpers.put_gear(sim, "saw", 1, 3, 3)
	SimTestHelpers.run_ticks(sim, 100)
	assert_eq(sim.attacks, 0)


func test_saw_counterclockwise_line_hits_three_nearest_in_its_column() -> void:
	# (3,3) крутится ↺ — «Отдача»: диск у Стены (дальность 2000, полуширина 1500).
	var sim: BattleSim = SimTestHelpers.new_sim()
	var g: SimGear = SimTestHelpers.put_gear(sim, "saw", 1, 3, 3)
	sim.advance()
	assert_false(g.clockwise)
	var near: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 3000, 1000)
	var side: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 4500, 500)
	var far: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 3000, 5000)
	var out: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 5000, 500)
	sim.call("_attack", g, sim.data.gear("saw"))
	sim.call("_apply_hits")
	assert_eq(near.hp, 1_000_000 - 10_000)
	assert_eq(side.hp, 1_000_000 - 10_000)
	assert_eq(far.hp, 1_000_000, "дальше 2000 от Стены")
	assert_eq(out.hp, 1_000_000, "дальше 1500 по горизонтали")


func test_saw_clockwise_hits_at_most_three_targets_closest_to_wall() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var g: SimGear = SimTestHelpers.put_gear(sim, "saw", 1, 3, 2)
	sim.advance()
	assert_true(g.clockwise)
	var ms: Array[SimMonster] = []
	for i: int in 4:
		ms.append(SimTestHelpers.put_monster(sim, "rustling", 3000, 1000 * (i + 1)))
	sim.call("_attack", g, sim.data.gear("saw"))
	sim.call("_apply_hits")
	assert_eq(ms[0].hp, 990_000)
	assert_eq(ms[2].hp, 990_000)
	assert_eq(ms[3].hp, 1_000_000, "четвёртая цель не задета")


func test_damage_grows_with_level() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var g: SimGear = SimTestHelpers.put_gear(sim, "saw", 2, 3, 2)
	sim.advance()
	var m: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 3000, 1000)
	sim.call("_attack", g, sim.data.gear("saw"))
	sim.call("_apply_hits")
	assert_eq(m.hp, 1_000_000 - 24_000)


func test_steam_clockwise_knocks_back() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var g: SimGear = SimTestHelpers.put_gear(sim, "steam", 1, 3, 2)
	sim.advance()
	var m: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 3000, 1000)
	sim.call("_attack", g, sim.data.gear("steam"))
	sim.call("_apply_hits")
	assert_eq(m.y, 1300)
	assert_eq(m.hp, 1_000_000 - 3_000)


func test_steam_counterclockwise_slows_by_35_percent() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var g: SimGear = SimTestHelpers.put_gear(sim, "steam", 1, 3, 3)
	sim.advance()
	var m: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 3000, 4000)
	sim.call("_attack", g, sim.data.gear("steam"))
	sim.call("_apply_hits")
	assert_eq(m.slow_pct, 350)
	assert_eq(m.slow_ticks, 60)
	assert_eq(m.hp, 1_000_000 - 1_500)

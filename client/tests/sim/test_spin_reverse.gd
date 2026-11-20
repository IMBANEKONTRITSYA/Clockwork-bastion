extends GutTest
## Раскрутка (60 тиков) и Реверс (стоп 45 тиков, перезарядка 600) — core-rules §3, §5.


func test_spin_starts_from_zero_and_reaches_full_in_60_ticks() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.apply_input("next_wave", {})
	assert_eq(sim.spin_factor(), 0)
	SimTestHelpers.run_ticks(sim, 30)
	assert_eq(sim.spin_factor(), 500)
	SimTestHelpers.run_ticks(sim, 30)
	assert_eq(sim.spin_factor(), 1000)
	SimTestHelpers.run_ticks(sim, 30)
	assert_eq(sim.spin_factor(), 1000)


func test_reverse_flips_direction_of_gears() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	var g: SimGear = SimTestHelpers.put_gear(sim, "saw", 1, 2, 2)
	sim.advance()
	assert_false(g.clockwise)
	assert_true(sim.apply_input("reverse", {}))
	sim.advance()
	assert_true(g.clockwise)


func test_reverse_stops_mechanism_for_45_ticks_then_spins_up() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.apply_input("next_wave", {})
	SimTestHelpers.run_ticks(sim, 90)
	assert_eq(sim.spin_factor(), 1000)
	sim.apply_input("reverse", {})
	for i: int in 45:
		assert_eq(sim.spin_factor(), 0, "тик %d после Реверса" % i)
		sim.advance()
	assert_eq(sim.spin_factor(), 0, "раскрутка начинается с нуля")
	SimTestHelpers.run_ticks(sim, 60)
	assert_eq(sim.spin_factor(), 1000)


func test_reverse_has_600_tick_cooldown() -> void:
	var sim: BattleSim = SimTestHelpers.new_sim()
	assert_true(sim.apply_input("reverse", {}))
	SimTestHelpers.run_ticks(sim, 599)
	assert_false(sim.apply_input("reverse", {}), "ещё перезарядка")
	sim.advance()
	assert_true(sim.apply_input("reverse", {}))

extends GutTest
## Монстры: движение к Стене, замедление, удары по Стене, зигзаг, смерть и гайки.


func _wave_sim() -> BattleSim:
	var sim: BattleSim = SimTestHelpers.new_sim()
	sim.phase = BattleSim.Phase.WAVE
	return sim


func test_rustling_moves_20_milli_cells_per_tick() -> void:
	var sim: BattleSim = _wave_sim()
	var m: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 3000, 6000)
	SimTestHelpers.run_ticks(sim, 30)
	assert_eq(m.y, 6000 - 600)


func test_slow_reduces_speed_and_expires() -> void:
	var sim: BattleSim = _wave_sim()
	var m: SimMonster = SimTestHelpers.put_monster(sim, "rustling", 3000, 6000)
	m.slow_pct = 350
	m.slow_ticks = 2
	SimTestHelpers.run_ticks(sim, 2)
	assert_eq(m.y, 6000 - 13 - 20, "первый тик с замедлением, второй — уже без")
	assert_eq(m.slow_pct, 0)


func test_monster_reaching_wall_hits_it_once_and_leaves_without_reward() -> void:
	var sim: BattleSim = _wave_sim()
	SimTestHelpers.put_monster(sim, "rustling", 3000, 20)
	SimTestHelpers.put_monster(sim, "rustling", 3000, 9000)
	sim.advance()
	assert_eq(sim.wall, 95)
	assert_eq(sim.monsters.size(), 1)
	assert_eq(sim.kills, 0)
	assert_eq(sim.nuts, 0)
	SimTestHelpers.run_ticks(sim, 30)
	assert_eq(sim.wall, 95)


func test_wall_at_zero_loses_run() -> void:
	var sim: BattleSim = _wave_sim()
	sim.wall = 5
	SimTestHelpers.put_monster(sim, "rustling", 3000, 20)
	sim.advance()
	assert_eq(sim.outcome(), "lost")
	assert_eq(sim.wall, 0)


func test_zigzag_offset_is_triangle_wave() -> void:
	assert_eq(SimMonster.zigzag_offset(1000, 60, 0), -1000)
	assert_eq(SimMonster.zigzag_offset(1000, 60, 15), 0)
	assert_eq(SimMonster.zigzag_offset(1000, 60, 30), 1000)
	assert_eq(SimMonster.zigzag_offset(1000, 60, 45), 0)
	assert_eq(SimMonster.zigzag_offset(0, 60, 10), 0)


func test_killed_monster_gives_nuts_and_kill() -> void:
	var sim: BattleSim = _wave_sim()
	var g: SimGear = SimTestHelpers.put_gear(sim, "saw", 1, 2, 1)
	sim.advance()
	SimTestHelpers.put_monster(sim, "rustling", 3000, 3000, 5_000)
	sim.call("_attack", g, sim.data.gear("saw"))
	sim.call("_apply_hits")
	assert_eq(sim.kills, 1)
	assert_eq(sim.nuts, 1)
	assert_eq(sim.monsters.size(), 0)

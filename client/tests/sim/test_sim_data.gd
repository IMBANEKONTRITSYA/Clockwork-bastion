extends GutTest
## SimData собирает типизированные описания из таблиц баланса.


func test_gears_and_monsters_keep_csv_order() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(data.gears[0].id, "saw")
	assert_eq(data.gears[1].id, "steam")
	assert_eq(data.monsters[0].id, "rustling")
	assert_eq(data.monsters[1].id, "squeaker")


func test_gear_modes_are_read_from_prefixed_columns() -> void:
	var steam: SimSpecs.Gear = SimData.load_default().gear("steam")
	assert_eq(steam.hits_per_rev_x1000, 4000)
	assert_eq(steam.mode(true).knockback_x1000, 300)
	assert_eq(steam.mode(false).slow_pct, 350)
	assert_eq(steam.mode(false).slow_ticks, 60)


func test_run_values() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(data.run_value("heart_power"), 8)
	assert_eq(data.run_value("wall_hp"), 100)
	assert_eq(data.max_level(), 5)


func test_bosses_are_flagged_and_regulars_are_not() -> void:
	var data: SimData = SimData.load_default()
	assert_false(data.monster("rustling").boss)
	assert_true(data.monster("colossus").boss)
	assert_true(data.monster("magnetron").boss)


func test_wave_table_accessors() -> void:
	var data: SimData = SimData.load_default()
	assert_eq(data.wave_count(1), 8)
	assert_eq(data.wave_hp_mul(1), 1000)
	assert_eq(data.wave_hp_mul(10), 2360)
	assert_eq(data.wave_boss(5), "colossus")
	assert_eq(data.wave_boss(10), "magnetron")
	assert_eq(data.wave_boss(4), "")
	assert_eq(data.wave_hp_mul(99), 2360, "после конца таблицы — последняя строка")
